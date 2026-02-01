// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/design_system/primitives/rtl_utils.dart
import 'package:flutter/material.dart';

/// RTL Utilities for Arabic language support
/// Ensures the design system works correctly in both LTR and RTL layouts

/// Check if current locale is RTL
bool isRtl(BuildContext context) {
  return Directionality.of(context) == TextDirection.rtl;
}

/// Get directional icon that flips in RTL
/// Use for navigation arrows, chevrons, etc.
class DirectionalIcon extends StatelessWidget {
  final IconData ltrIcon;
  final IconData? rtlIcon;
  final double? size;
  final Color? color;

  const DirectionalIcon({
    super.key,
    required this.ltrIcon,
    this.rtlIcon,
    this.size,
    this.color,
  });

  /// Back arrow that flips correctly
  factory DirectionalIcon.back({double? size, Color? color}) => DirectionalIcon(
        ltrIcon: Icons.arrow_back_ios,
        rtlIcon: Icons.arrow_forward_ios,
        size: size,
        color: color,
      );

  /// Forward arrow that flips correctly
  factory DirectionalIcon.forward({double? size, Color? color}) =>
      DirectionalIcon(
        ltrIcon: Icons.arrow_forward_ios,
        rtlIcon: Icons.arrow_back_ios,
        size: size,
        color: color,
      );

  /// Chevron right that flips correctly
  factory DirectionalIcon.chevronRight({double? size, Color? color}) =>
      DirectionalIcon(
        ltrIcon: Icons.chevron_right,
        rtlIcon: Icons.chevron_left,
        size: size,
        color: color,
      );

  /// Chevron left that flips correctly
  factory DirectionalIcon.chevronLeft({double? size, Color? color}) =>
      DirectionalIcon(
        ltrIcon: Icons.chevron_left,
        rtlIcon: Icons.chevron_right,
        size: size,
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    final effectiveIcon =
        isRtl(context) ? (rtlIcon ?? ltrIcon) : ltrIcon;
    return Icon(
      effectiveIcon,
      size: size,
      color: color,
    );
  }
}

/// Directional padding helpers
/// Use these instead of EdgeInsets for RTL-aware padding
class AppEdgeInsets {
  /// Symmetric padding (same in both directions)
  static EdgeInsetsDirectional symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) =>
      EdgeInsetsDirectional.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      );

  /// All sides equal
  static EdgeInsetsDirectional all(double value) =>
      EdgeInsetsDirectional.all(value);

  /// Only specific sides
  static EdgeInsetsDirectional only({
    double start = 0,
    double top = 0,
    double end = 0,
    double bottom = 0,
  }) =>
      EdgeInsetsDirectional.only(
        start: start,
        top: top,
        end: end,
        bottom: bottom,
      );

  /// Horizontal padding only (start and end)
  static EdgeInsetsDirectional horizontal(double value) =>
      EdgeInsetsDirectional.symmetric(horizontal: value);

  /// Vertical padding only (top and bottom)
  static EdgeInsetsDirectional vertical(double value) =>
      EdgeInsetsDirectional.symmetric(vertical: value);
}

/// Directional alignment helpers
extension DirectionalAlignment on MainAxisAlignment {
  /// Use this for Row alignments that should flip in RTL
  static MainAxisAlignment get directionalStart => MainAxisAlignment.start;
  static MainAxisAlignment get directionalEnd => MainAxisAlignment.end;
}

/// Directional text alignment
extension DirectionalTextAlign on TextAlign {
  /// Use TextAlign.start instead of TextAlign.left
  static TextAlign get directionalStart => TextAlign.start;
  static TextAlign get directionalEnd => TextAlign.end;
}

/// Border radius that respects directionality
class AppBorderRadius {
  static BorderRadiusDirectional only({
    double topStart = 0,
    double topEnd = 0,
    double bottomStart = 0,
    double bottomEnd = 0,
  }) =>
      BorderRadiusDirectional.only(
        topStart: Radius.circular(topStart),
        topEnd: Radius.circular(topEnd),
        bottomStart: Radius.circular(bottomStart),
        bottomEnd: Radius.circular(bottomEnd),
      );

  static BorderRadiusDirectional horizontal({
    double start = 0,
    double end = 0,
  }) =>
      BorderRadiusDirectional.horizontal(
        start: Radius.circular(start),
        end: Radius.circular(end),
      );

  static BorderRadius circular(double radius) =>
      BorderRadius.circular(radius);

  static BorderRadius all(double radius) =>
      BorderRadius.all(Radius.circular(radius));
}
