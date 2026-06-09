// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/design_system/components/cards/app_card.dart
import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';

/// Primitive AppCard component
/// Applies standard radius, padding, background, and subtle elevation.
/// Use this as the base card for all card-based UI components.
class AppCard extends StatelessWidget {
  /// The content of the card
  final Widget child;

  /// Custom padding (defaults to AppSpacing.cardPadding)
  final EdgeInsetsGeometry? padding;

  /// Optional tap callback
  final VoidCallback? onTap;

  /// Custom background color (defaults to AppColors.backgroundWhite)
  final Color? backgroundColor;

  /// Custom border radius (defaults to AppSpacing.cardRadius)
  final double? borderRadius;

  /// Custom elevation (defaults to subtle elevation)
  final double? elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppSpacing.cardRadius;
    final effectiveElevation = elevation ?? 2.0;

    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, effectiveElevation),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
