// FEATURE: Support Tickets - Ticket Detail Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/support/data/support_service.dart';
import 'package:aji_tfarraj/features/support/domain/support_ticket.dart';
import 'package:aji_tfarraj/features/support/presentation/widgets/ticket_status_banner_widget.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() =>
      _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  late Future<SupportTicketDetail> _ticketFuture;

  @override
  void initState() {
    super.initState();
    _ticketFuture = _fetchTicket();
  }

  Future<SupportTicketDetail> _fetchTicket() =>
      ref.read(supportServiceProvider).getTicket(widget.ticketId);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final locale =
        ref.watch(localeProvider).languageCode == 'ar' ? 'ar' : 'fr_FR';

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
          '#${widget.ticketId}',
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
      body: FutureBuilder<SupportTicketDetail>(
        future: _ticketFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            final msg = snapshot.error.toString().contains('403')
                ? s.supportDetailForbidden
                : s.supportDetailError;
            return _ErrorView(
              message: msg,
              retryLabel: s.supportDetailRetry,
              onRetry: () => setState(() => _ticketFuture = _fetchTicket()),
            );
          }
          final ticket = snapshot.data!;
          return _DetailContent(ticket: ticket, s: s, locale: locale);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Detail Content
// ─────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  final SupportTicketDetail ticket;
  final AppStrings s;
  final String locale;

  const _DetailContent(
      {required this.ticket, required this.s, required this.locale});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', locale);
    final createdStr = dateFormat.format(ticket.createdAt.toLocal());
    final updatedStr = dateFormat.format(ticket.updatedAt.toLocal());
    final isClosed = ticket.status == 'closed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TicketStatusBanner(status: ticket.status, s: s),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel(s.supportDetailSubjectSection),
          const SizedBox(height: AppSpacing.sm),
          _SubjectCard(subject: ticket.subject),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel(s.supportDetailMessageSection),
          const SizedBox(height: AppSpacing.sm),
          _MessageCard(message: ticket.message),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel(s.supportDetailMetaSection),
          const SizedBox(height: AppSpacing.sm),
          _MetadataCard(
            id: ticket.id,
            createdAt: createdStr,
            updatedAt: updatedStr,
            s: s,
          ),
          const SizedBox(height: AppSpacing.xl),

          isClosed
              ? _ClosedInfoBox(s: s)
              : _PendingInfoBox(s: s),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Subject Card
// ─────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final String subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        subject,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Message Card
// ─────────────────────────────────────────────

class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Metadata Card
// ─────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {
  final int id;
  final String createdAt;
  final String updatedAt;
  final AppStrings s;

  const _MetadataCard({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _MetaRow(
            icon: Icons.confirmation_number_outlined,
            label: s.supportMetaTicketNumber,
            value: '#$id',
            valueStyle: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            label: s.supportMetaSubmittedAt,
            value: createdAt,
          ),
          Divider(height: 1, color: AppColors.border),
          _MetaRow(
            icon: Icons.update,
            label: s.supportMetaUpdatedAt,
            value: updatedAt,
            valueStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: valueStyle ??
                AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Info Boxes
// ─────────────────────────────────────────────

class _PendingInfoBox extends StatelessWidget {
  final AppStrings s;

  const _PendingInfoBox({required this.s});

  @override
  Widget build(BuildContext context) {
    final iconColor = AppColors.getStatusForegroundColor('contacting');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: iconColor, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              s.supportInfoCallPending,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedInfoBox extends StatelessWidget {
  final AppStrings s;

  const _ClosedInfoBox({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              color: AppColors.textMuted, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              s.supportInfoClosed,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorView(
      {required this.message,
      required this.retryLabel,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(retryLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
