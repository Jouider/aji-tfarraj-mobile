import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';

/// Aji Tfarraj Button Components
/// Primary, Secondary, Text, and Icon button variants
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
  });

  /// Primary button constructor
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
  }) : variant = AppButtonVariant.primary;

  /// Secondary button constructor
  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
  }) : variant = AppButtonVariant.secondary;

  /// Outline button constructor
  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
  }) : variant = AppButtonVariant.outline;

  /// Text button constructor
  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
  }) : variant = AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final height = size == AppButtonSize.large 
        ? AppSpacing.buttonHeight 
        : AppSpacing.buttonHeightSm;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: _buildButton(isDisabled),
    );
  }

  Widget _buildButton(bool isDisabled) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _PrimaryButton(
          label: label,
          onPressed: isDisabled ? null : onPressed,
          isLoading: isLoading,
          size: size,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        );
      case AppButtonVariant.secondary:
        return _SecondaryButton(
          label: label,
          onPressed: isDisabled ? null : onPressed,
          isLoading: isLoading,
          size: size,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        );
      case AppButtonVariant.outline:
        return _OutlineButton(
          label: label,
          onPressed: isDisabled ? null : onPressed,
          isLoading: isLoading,
          size: size,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        );
      case AppButtonVariant.text:
        return _TextButton(
          label: label,
          onPressed: isDisabled ? null : onPressed,
          isLoading: isLoading,
          size: size,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        );
    }
  }
}

/// Button variants
enum AppButtonVariant { primary, secondary, outline, text }

/// Button sizes
enum AppButtonSize { large, small }

// ============================================
// Primary Button
// ============================================
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.large,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.backgroundWhite,
        disabledBackgroundColor: AppColors.disabled,
        disabledForegroundColor: AppColors.textLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: size == AppButtonSize.large ? AppSpacing.xl : AppSpacing.lg,
        ),
      ),
      child: _ButtonContent(
        label: label,
        isLoading: isLoading,
        size: size,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
        textStyle: size == AppButtonSize.large
            ? AppTypography.buttonLarge
            : AppTypography.buttonMedium,
      ),
    );
  }
}

// ============================================
// Secondary Button
// ============================================
class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const _SecondaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.large,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.disabled,
        disabledForegroundColor: AppColors.textLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: size == AppButtonSize.large ? AppSpacing.xl : AppSpacing.lg,
        ),
      ),
      child: _ButtonContent(
        label: label,
        isLoading: isLoading,
        size: size,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
        textStyle: (size == AppButtonSize.large
                ? AppTypography.buttonLarge
                : AppTypography.buttonMedium)
            .copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

// ============================================
// Outline Button
// ============================================
class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const _OutlineButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.large,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textLight,
        side: BorderSide(
          color: onPressed != null ? AppColors.primary : AppColors.disabled,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: size == AppButtonSize.large ? AppSpacing.xl : AppSpacing.lg,
        ),
      ),
      child: _ButtonContent(
        label: label,
        isLoading: isLoading,
        size: size,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
        textStyle: (size == AppButtonSize.large
                ? AppTypography.buttonLarge
                : AppTypography.buttonMedium)
            .copyWith(color: AppColors.primary),
        loadingColor: AppColors.primary,
      ),
    );
  }
}

// ============================================
// Text Button
// ============================================
class _TextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const _TextButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.large,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: size == AppButtonSize.large ? AppSpacing.lg : AppSpacing.md,
        ),
      ),
      child: _ButtonContent(
        label: label,
        isLoading: isLoading,
        size: size,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
        textStyle: (size == AppButtonSize.large
                ? AppTypography.buttonLarge
                : AppTypography.buttonMedium)
            .copyWith(color: AppColors.primary),
        loadingColor: AppColors.primary,
      ),
    );
  }
}

// ============================================
// Button Content (shared)
// ============================================
class _ButtonContent extends StatelessWidget {
  final String label;
  final bool isLoading;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final TextStyle textStyle;
  final Color loadingColor;

  _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.size,
    required this.textStyle,
    this.leadingIcon,
    this.trailingIcon,
    Color? loadingColor,
  }) : loadingColor = loadingColor ?? AppColors.backgroundWhite;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
        ),
      );
    }

    final iconSize = size == AppButtonSize.large 
        ? AppSpacing.iconMd 
        : AppSpacing.iconSm;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: iconSize),
          SizedBox(width: AppSpacing.sm),
        ],
        Text(label, style: textStyle),
        if (trailingIcon != null) ...[
          SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );
  }
}

// ============================================
// Icon Button
// ============================================
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 40,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              icon,
              color: color ?? AppColors.textPrimary,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
