// FEATURE: Support — starting a conversation.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/support/data/support_service.dart';
import 'package:aji_tfarraj/features/support/presentation/screens/support_chat_screen.dart';

/// A subject and a first message; then straight into the conversation.
///
/// The button sits in a bar under the form, above the keyboard: in the old
/// screen it was at the end of the scroll, and the keyboard hid it while
/// typing.
class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;
  String? _subjectError;
  String? _messageError;

  @override
  void initState() {
    super.initState();
    _subject.addListener(_onChanged);
    _message.addListener(_onChanged);
  }

  void _onChanged() => setState(() {
        if (_subject.text.trim().isNotEmpty) _subjectError = null;
        if (_message.text.trim().isNotEmpty) _messageError = null;
      });

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final copy = ref.read(stringsProvider).supportChat;
    final subject = _subject.text.trim();
    final message = _message.text.trim();

    setState(() {
      _subjectError = subject.isEmpty ? copy.subjectRequired : null;
      _messageError = message.isEmpty ? copy.messageRequired : null;
    });
    if (_subjectError != null || _messageError != null) return;

    setState(() => _sending = true);
    try {
      final ticket = await ref
          .read(supportServiceProvider)
          .createTicket(subject: subject, message: message);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            SupportChatScreen(ticketId: ticket.id, subject: ticket.subject),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(stringsProvider).supportChat;

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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          copy.createTitle,
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
              children: [
                Text(
                  copy.createIntro,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _Field(
                  label: copy.subjectLabel,
                  hint: copy.subjectHint,
                  controller: _subject,
                  error: _subjectError,
                  maxLength: 255,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                _Field(
                  label: copy.messageLabel,
                  hint: copy.messageHint,
                  controller: _message,
                  error: _messageError,
                  maxLength: 5000,
                  minLines: 6,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ],
            ),
          ),
          // The button stays above the keyboard and the home indicator.
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.zero,
              child: SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(copy.start,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryAction,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.maxLength,
    this.error,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLength;
  final String? error;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          maxLength: maxLength,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintMaxLines: 3,
            hintStyle: AppTypography.bodyMedium
                .copyWith(color: AppColors.textMuted, height: 1.5),
            filled: true,
            fillColor: AppColors.backgroundLight,
            counterText: '',
            errorText: error,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2, vertical: AppSpacing.md + 2),
            border: border(AppColors.border),
            enabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.primary, 1.5),
            errorBorder: border(AppColors.error),
            focusedErrorBorder: border(AppColors.error, 1.5),
          ),
        ),
      ],
    );
  }
}
