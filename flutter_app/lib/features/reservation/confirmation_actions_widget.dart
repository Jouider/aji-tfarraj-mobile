import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';

/// ConfirmationActions — primary CTA + secondary outline button.
/// FIX: primary bg + shadow for "Voir mes réservations";
///      outline primary for "Retour à l'accueil".
class ConfirmationActions extends ConsumerWidget {
  /// When false, the secondary "Retour à l'accueil" button is hidden
  /// (used when a top-left back control already provides that action).
  final bool showHomeButton;

  const ConfirmationActions({super.key, this.showHomeButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Column(
      children: [
        // FIX: Primary button — primary bg, white w700 16px, ticket icon, radius 14, h54, shadow
        _PrimaryActionButton(
          label: s.reservationResultCtaMyReservations,
          onTap: () => context.go(Routes.myReservations),
        ),
        if (showHomeButton) ...[
          const SizedBox(height: 12),
          // FIX: Secondary button — transparent bg, primary 1.5px border, radius 14, h54
          _SecondaryActionButton(
            label: s.reservationResultCtaHome,
            onTap: () => context.go(Routes.home),
          ),
        ],
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        // FIX: primary 30% shadow, blur 12, y4
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.list_alt_outlined, size: 18, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.home_outlined, size: 18, color: AppColors.primary),
        label: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          // FIX: primary 1.5px border, radius 14
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
