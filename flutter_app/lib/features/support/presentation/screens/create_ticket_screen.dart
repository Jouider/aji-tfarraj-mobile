// FEATURE: Support Tickets - Create Ticket Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/support/data/support_service.dart';
import 'package:aji_tfarraj/features/support/domain/support_ticket.dart';
import 'package:aji_tfarraj/features/support/presentation/screens/ticket_confirmation_screen.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() =>
      _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String? _subjectError;

  bool get _isFormValid =>
      _subjectController.text.trim().isNotEmpty &&
      _messageController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _subjectController.addListener(_onChanged);
    _messageController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket(AppStrings s) async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty) {
      setState(() => _subjectError = s.supportSubjectRequired);
      return;
    }
    setState(() => _subjectError = null);

    setState(() => _isLoading = true);
    try {
      final SupportTicket ticket =
          await ref.read(supportServiceProvider).createTicket(
                subject: subject,
                message: message,
              );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => TicketConfirmationScreen(ticket: ticket)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final subjectLen = _subjectController.text.length;
    final messageLen = _messageController.text.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          s.supportCreateTitle,
          style: AppTypography.h4.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),

            // ── "Bon à savoir" info banner ────────────────
            _InfoBanner(s: s),

            const SizedBox(height: AppSpacing.xl),

            // ── Subject field ─────────────────────────────
            _FieldLabel(s.supportSubjectLabel),
            const SizedBox(height: 6),
            _FocusableTextField(
              controller: _subjectController,
              placeholder: s.supportSubjectHint,
              maxLength: 255,
              maxLines: 1,
              error: _subjectError,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$subjectLen/255',
                style: TextStyle(
                  color: _counterColor(subjectLen, 255),
                  fontSize: 11,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Message field ─────────────────────────────
            _FieldLabel(s.supportMessageLabel),
            const SizedBox(height: 6),
            _FocusableTextField(
              controller: _messageController,
              placeholder: s.supportMessageHint,
              maxLength: 5000,
              maxLines: null,
              minLines: 5,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$messageLen/5000',
                style: TextStyle(
                  color: _counterColor(messageLen, 5000),
                  fontSize: 11,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── CTA button ────────────────────────────────
            _SubmitButton(
              label: s.supportSubmitButton,
              isLoading: _isLoading,
              isEnabled: _isFormValid,
              onTap: () => _submitTicket(s),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Color _counterColor(int length, int max) {
    if (length >= max) return AppColors.errorDark;
    if (length / max >= 0.80)
      return AppColors.getStatusForegroundColor('contacting');
    return AppColors.textMuted;
  }
}

// ─────────────────────────────────────────────
// Info Banner
// ─────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final AppStrings s;

  const _InfoBanner({required this.s});

  @override
  Widget build(BuildContext context) {
    final iconColor = AppColors.getStatusForegroundColor('contacting');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.supportInfoBannerTitle,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  s.supportInfoBannerBody,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Field Label
// ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Focusable TextField with animated border
// ─────────────────────────────────────────────

class _FocusableTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final int maxLength;
  final int? maxLines;
  final int? minLines;
  final String? error;

  const _FocusableTextField({
    required this.controller,
    required this.placeholder,
    required this.maxLength,
    this.maxLines,
    this.minLines,
    this.error,
  });

  @override
  State<_FocusableTextField> createState() => _FocusableTextFieldState();
}

class _FocusableTextFieldState extends State<_FocusableTextField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
        () => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final borderColor = hasError
        ? AppColors.error
        : _isFocused
            ? AppColors.primary
            : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 6,
                    )
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.error!,
            style: TextStyle(color: AppColors.errorDark, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Submit Button
// ─────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = isEnabled && !isLoading;
    return Container(
      width: double.infinity,
      height: 54,
      decoration: active
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: FilledButton.icon(
        onPressed: active ? onTap : null,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send_outlined, size: 18, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: active ? AppColors.primary : AppColors.border,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
