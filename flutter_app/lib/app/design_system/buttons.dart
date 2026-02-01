import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';

/// Aji Tfarraj Button Components
/// Primary, Secondary, and Disabled states
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSmall;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSmall = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final height = isSmall ? AppSpacing.buttonHeightSm : AppSpacing.buttonHeight;
    final textStyle = isSmall ? AppTypography.buttonMedium : AppTypography.buttonLarge;

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.backgroundWhite,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          disabledForegroundColor: AppColors.backgroundWhite.withOpacity(0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? AppSpacing.lg : AppSpacing.xl,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.backgroundWhite,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: isSmall ? 18 : 20),
                    SizedBox(width: AppSpacing.sm),
                  ],
                  Text(text, style: textStyle),
                ],
              ),
      ),
    );
  }
}

/// Secondary Button (outlined)
class AppButtonSecondary extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSmall;
  final IconData? icon;

  const AppButtonSecondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSmall = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final height = isSmall ? AppSpacing.buttonHeightSm : AppSpacing.buttonHeight;
    final textStyle = (isSmall ? AppTypography.buttonMedium : AppTypography.buttonLarge)
        .copyWith(color: AppColors.primary);

    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: onPressed == null ? AppColors.disabled : AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? AppSpacing.lg : AppSpacing.xl,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: isSmall ? 18 : 20),
                    SizedBox(width: AppSpacing.sm),
                  ],
                  Text(text, style: textStyle),
                ],
              ),
      ),
    );
  }
}

/// Text Button (minimal)
class AppButtonText extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;

  const AppButtonText({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.primary,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.labelLarge.copyWith(
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}
