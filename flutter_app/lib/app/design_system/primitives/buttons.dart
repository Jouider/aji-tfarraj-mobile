// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/design_system/primitives/buttons.dart
import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/primitives/rtl_utils.dart';

/// Aji Tfarraj Button Components (RTL-Ready)
/// Primary, Secondary, and Disabled states with proper directional support

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSmall;
  final IconData? icon;
  final bool iconAtEnd; // For RTL: icon position is logical, not physical

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSmall = false,
    this.icon,
    this.iconAtEnd = false,
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
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.backgroundWhite.withValues(alpha: 0.7),
          elevation: 0,
          padding: AppEdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: AppSpacing.iconMd,
                height: AppSpacing.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.backgroundWhite.withValues(alpha: 0.7),
                  ),
                ),
              )
            : _buildContent(textStyle),
      ),
    );
  }

  Widget _buildContent(TextStyle textStyle) {
    if (icon == null) {
      return Text(text, style: textStyle);
    }

    final iconWidget = Icon(icon, size: AppSpacing.iconSm);
    final textWidget = Text(text, style: textStyle);
    final spacing = SizedBox(width: AppSpacing.sm);

    // Icon position is logical (start/end), not physical (left/right)
    final children = iconAtEnd
        ? [textWidget, spacing, iconWidget]
        : [iconWidget, spacing, textWidget];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}

/// Secondary Button with outline style (RTL-Ready)
class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSmall;
  final IconData? icon;
  final bool iconAtEnd;

  const AppSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSmall = false,
    this.icon,
    this.iconAtEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = isSmall ? AppSpacing.buttonHeightSm : AppSpacing.buttonHeight;
    final textStyle = (isSmall ? AppTypography.buttonMedium : AppTypography.buttonLarge)
        .copyWith(color: AppColors.primary);

    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: AppEdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: _buildContent(textStyle),
      ),
    );
  }

  Widget _buildContent(TextStyle textStyle) {
    if (icon == null) {
      return Text(text, style: textStyle);
    }

    final iconWidget = Icon(icon, size: AppSpacing.iconSm, color: AppColors.primary);
    final textWidget = Text(text, style: textStyle);
    final spacing = SizedBox(width: AppSpacing.sm);

    final children = iconAtEnd
        ? [textWidget, spacing, iconWidget]
        : [iconWidget, spacing, textWidget];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}

/// Text Button (RTL-Ready)
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSmall;
  final IconData? icon;
  final bool iconAtEnd;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSmall = false,
    this.icon,
    this.iconAtEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = (isSmall ? AppTypography.buttonMedium : AppTypography.buttonMedium)
        .copyWith(color: AppColors.primary);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: AppEdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: _buildContent(textStyle),
    );
  }

  Widget _buildContent(TextStyle textStyle) {
    if (icon == null) {
      return Text(text, style: textStyle);
    }

    final iconWidget = Icon(icon, size: AppSpacing.iconSm, color: AppColors.primary);
    final textWidget = Text(text, style: textStyle);
    final spacing = SizedBox(width: AppSpacing.xs);

    final children = iconAtEnd
        ? [textWidget, spacing, iconWidget]
        : [iconWidget, spacing, textWidget];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// Icon Button with directional support
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final bool isDirectional; // If true, icon flips in RTL

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.isDirectional = false,
  });

  /// Back button that automatically flips in RTL
  factory AppIconButton.back({
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? iconColor,
    double? size,
  }) =>
      _DirectionalIconButton(
        ltrIcon: Icons.arrow_back_ios_new,
        rtlIcon: Icons.arrow_forward_ios,
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        size: size,
      );

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppSpacing.iconLg;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: effectiveSize),
      color: iconColor ?? AppColors.textPrimary,
      style: backgroundColor != null
          ? IconButton.styleFrom(backgroundColor: backgroundColor)
          : null,
    );
  }
}

/// Internal directional icon button
class _DirectionalIconButton extends AppIconButton {
  final IconData ltrIcon;
  final IconData rtlIcon;

  const _DirectionalIconButton({
    required this.ltrIcon,
    required this.rtlIcon,
    super.onPressed,
    super.backgroundColor,
    super.iconColor,
    super.size,
  }) : super(icon: ltrIcon);

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppSpacing.iconLg;
    final effectiveIcon = isRtl(context) ? rtlIcon : ltrIcon;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(effectiveIcon, size: effectiveSize),
      color: iconColor ?? AppColors.textPrimary,
      style: backgroundColor != null
          ? IconButton.styleFrom(backgroundColor: backgroundColor)
          : null,
    );
  }
}
