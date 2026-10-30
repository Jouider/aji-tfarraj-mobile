import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';

/// Les couleurs et l'icône de la liste d'attente : l'or de la marque tant
/// qu'on attend une place, le vert quand la personne a dit qu'elle vient.
class WaitlistLook {
  const WaitlistLook._(this.icon, this.color, this.foreground);

  final IconData icon;
  final Color color;
  final Color foreground;

  static WaitlistLook of(Reservation reservation) => reservation.waitlistComing
      ? const WaitlistLook._(
          Icons.directions_walk_rounded, AppColors.success, AppColors.successDark)
      : WaitlistLook._(Icons.format_list_numbered_rounded, AppColors.secondary,
          AppColors.accentInk);

  Color get background => color.withValues(alpha: 0.12);
  Color get border => color.withValues(alpha: 0.30);
}

/// À la place du badge « En attente » quand la réservation est sur la liste.
class WaitlistBadge extends ConsumerWidget {
  const WaitlistBadge({super.key, required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(stringsProvider).waitlist;
    final look = WaitlistLook.of(reservation);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: look.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: look.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(look.icon, size: 14, color: look.foreground),
          const SizedBox(width: 6),
          Text(
            reservation.waitlistComing ? c.comingBadge : c.waitingBadge,
            style: TextStyle(
              color: look.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ce que veut dire la liste d'attente, et quoi faire, sous la carte.
class WaitlistNotice extends ConsumerWidget {
  const WaitlistNotice({
    super.key,
    required this.reservation,
    this.margin = EdgeInsets.zero,
  });

  final Reservation reservation;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(stringsProvider).waitlist;
    final look = WaitlistLook.of(reservation);

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: look.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: look.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(look.icon, size: 18, color: look.foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              reservation.waitlistComing ? c.comingBody : c.waitingBody,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
