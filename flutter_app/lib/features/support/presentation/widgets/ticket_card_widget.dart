// FEATURE: Support Tickets - Ticket Card Widget
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/support/domain/support_ticket.dart';
import 'package:aji_tfarraj/features/support/presentation/widgets/ticket_status_badge_widget.dart';

/// Tappable card used in the support tickets list.
class TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final AppStrings s;
  final String locale;
  final VoidCallback onTap;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.s,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('dd MMM', locale).format(ticket.createdAt.toLocal());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDarkElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TicketStatusBadge(status: ticket.status, s: s),
                Text(
                  dateLabel,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.subject,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.supportCardSubtitle,
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
