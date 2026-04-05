import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';

/// Reservation status constants matching backend
class ReservationStatus {
  static const String pendingReview = 'pending_review';
  static const String contacting = 'contacting';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';
  static const String expired = 'expired';
  static const String checkedIn = 'checked_in';
}

/// Utility class for reservation status UI mapping
class ReservationStatusHelper {
  final String status;

  ReservationStatusHelper(this.status);

  /// Get French label for status
  String get label {
    switch (status) {
      case ReservationStatus.pendingReview:
        return 'En attente';
      case ReservationStatus.contacting:
        return 'En cours d\'appel';
      case ReservationStatus.approved:
        return 'Approuvée';
      case ReservationStatus.rejected:
        return 'Refusée';
      case ReservationStatus.cancelled:
        return 'Annulée';
      case ReservationStatus.expired:
        return 'Expirée';
      case ReservationStatus.checkedIn:
        return 'Check-in effectué';
      default:
        return status;
    }
  }

  /// Get Arabic label for status (for future localization)
  String get labelAr {
    switch (status) {
      case ReservationStatus.pendingReview:
        return 'في انتظار المراجعة';
      case ReservationStatus.contacting:
        return 'جاري الاتصال';
      case ReservationStatus.approved:
        return 'تمت الموافقة';
      case ReservationStatus.rejected:
        return 'مرفوض';
      case ReservationStatus.cancelled:
        return 'ملغى';
      case ReservationStatus.expired:
        return 'منتهي الصلاحية';
      case ReservationStatus.checkedIn:
        return 'تم الدخول';
      default:
        return status;
    }
  }

  /// Get badge color for status (bright, for dark-mode or decorative use)
  Color get color => AppColors.getStatusColor(status);

  /// Get background color (lighter) for badge
  Color get backgroundColor => AppColors.getStatusBackgroundColor(status);

  /// Get readable foreground color for badge text/icon (theme-aware)
  // FIX: Theme-aware foreground — dark variants in light mode for readability
  Color get foregroundColor => AppColors.getStatusForegroundColor(status);

  /// Get border color for badge (status-tinted)
  // FIX: Status-tinted borders
  Color get borderColor => AppColors.getStatusBorderColor(status);

  /// Get icon for status
  IconData get icon {
    switch (status) {
      case ReservationStatus.pendingReview:
        return Icons.hourglass_empty;
      case ReservationStatus.contacting:
        return Icons.phone;
      case ReservationStatus.approved:
        return Icons.check_circle;
      case ReservationStatus.rejected:
        return Icons.cancel;
      case ReservationStatus.cancelled:
        return Icons.block;
      case ReservationStatus.expired:
        return Icons.timer_off;
      case ReservationStatus.checkedIn:
        return Icons.verified;
      default:
        return Icons.help_outline;
    }
  }

  // Helper booleans
  bool get isPending =>
      status == ReservationStatus.pendingReview ||
      status == ReservationStatus.contacting;

  bool get isApproved => status == ReservationStatus.approved;

  bool get isRejected => status == ReservationStatus.rejected;

  bool get isCancelled => status == ReservationStatus.cancelled;

  bool get isExpired => status == ReservationStatus.expired;

  bool get isCheckedIn => status == ReservationStatus.checkedIn;

  /// Can the reservation be cancelled by user?
  bool get canCancel =>
      status == ReservationStatus.pendingReview ||
      status == ReservationStatus.contacting;

  /// Is the reservation in a final state?
  bool get isFinal =>
      status == ReservationStatus.rejected ||
      status == ReservationStatus.cancelled ||
      status == ReservationStatus.expired ||
      status == ReservationStatus.checkedIn;
}

/// Widget for displaying reservation status badge
// FIX: Status badge — brand tokens, no truncation, radius 20, theme-aware foreground
class ReservationStatusBadge extends ConsumerWidget {
  final String status;
  final bool showIcon;

  const ReservationStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helper = ReservationStatusHelper(status);
    final isAr = ref.watch(isRtlProvider);
    // FIX: Use theme-aware foreground — readable in both light and dark
    final fg = helper.foregroundColor;
    // FIX: Use short badge label (helper.label) — NOT statusByKey which returns "En attente de validation"
    final label = isAr ? helper.labelAr : helper.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: helper.backgroundColor,
        // FIX: Radius 20 pill shape
        borderRadius: BorderRadius.circular(20),
        // FIX: Status-tinted border at correct opacity
        border: Border.all(color: helper.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(helper.icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
