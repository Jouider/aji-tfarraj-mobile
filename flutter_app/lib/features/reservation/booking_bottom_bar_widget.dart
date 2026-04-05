import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';

/// BookingBottomBar — sticky recap + confirm CTA.
/// FIX: backgroundLight bg, top border token, uppercase recap label,
///      primary CTA button (active) vs border bg (disabled).
class BookingBottomBar extends StatelessWidget {
  final bool isLoading;
  final bool isSoldOut;
  final bool agreedToTerms;
  final VoidCallback onConfirm;
  final AppStrings s;

  const BookingBottomBar({
    super.key,
    required this.isLoading,
    required this.isSoldOut,
    required this.agreedToTerms,
    required this.onConfirm,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        // FIX: backgroundLight bg + top border token
        color: AppColors.backgroundLight,
        border: Border(
            top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIX: Récapitulatif row — textMuted uppercase ls0.8 + primary seat icon
            Row(
              children: [
                Text(
                  s.reserveSeatsRecap.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.event_seat_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  // FIX: textPrimary w700 16px
                  '1 ${s.place}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Confirm / sold-out button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: isSoldOut
                  ? _SoldOutButton(s: s)
                  : _ConfirmButton(
                      isLoading: isLoading,
                      isActive: agreedToTerms && !isLoading,
                      onConfirm: onConfirm,
                      s: s,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confirm Button ────────────────────────────────────────────────────────────

class _ConfirmButton extends StatelessWidget {
  final bool isLoading;
  final bool isActive;
  final VoidCallback onConfirm;
  final AppStrings s;

  const _ConfirmButton({
    required this.isLoading,
    required this.isActive,
    required this.onConfirm,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isActive
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              // FIX: Active shadow — primary 30% blur 12 y4
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: ElevatedButton(
        onPressed: (isLoading || !isActive) ? null : onConfirm,
        style: ElevatedButton.styleFrom(
          // FIX: Active → primary bg, white text; Disabled → border bg, textMuted
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // FIX: Ticket icon white size 18
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: isActive ? Colors.white : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  // FIX: white w700 16px when active
                  Text(
                    s.reserveSeatsConfirm,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Sold Out Button ───────────────────────────────────────────────────────────

class _SoldOutButton extends StatelessWidget {
  final AppStrings s;

  const _SoldOutButton({required this.s});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        disabledForegroundColor: AppColors.textMuted,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        s.reserveSeatsSoldOutCta,
        style: const TextStyle(
          color: AppColors.info,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}
