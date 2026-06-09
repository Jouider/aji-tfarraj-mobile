import 'package:flutter/material.dart';

/// Aji Tfarraj Spacing & Layout Tokens
/// Consistent spacing system based on 4px base unit
class AppSpacing {
  AppSpacing._();

  // ============================================
  // Base Spacing (4px base unit)
  // ============================================
  
  /// 4px - Tight spacing
  static const double xs = 4.0;
  
  /// 8px - Small spacing
  static const double sm = 8.0;
  
  /// 12px - Medium-small spacing
  static const double md = 12.0;
  
  /// 16px - Default spacing
  static const double lg = 16.0;
  
  /// 24px - Large spacing
  static const double xl = 24.0;
  
  /// 32px - Extra large spacing
  static const double xxl = 32.0;
  
  /// 48px - Section spacing
  static const double xxxl = 48.0;

  // ============================================
  // Screen Padding
  // ============================================
  
  /// Horizontal screen padding (16px)
  static const double screenPaddingH = 16.0;
  
  /// Vertical screen padding (24px)
  static const double screenPaddingV = 24.0;
  
  /// Screen edge insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );
  
  /// Horizontal only screen padding
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
  );

  // ============================================
  // Component Dimensions
  // ============================================
  
  /// Button height (48px)
  static const double buttonHeight = 48.0;
  
  /// Small button height (36px)
  static const double buttonHeightSm = 36.0;
  
  /// Input field height (48px)
  static const double inputHeight = 48.0;
  
  /// App bar height (56px)
  static const double appBarHeight = 56.0;
  
  /// Bottom nav height (64px)
  static const double bottomNavHeight = 64.0;
  
  /// Card min height (120px)
  static const double cardMinHeight = 120.0;

  // ============================================
  // Border Radius
  // ============================================
  
  /// Small radius (4px) - Chips, small elements
  static const double radiusSm = 4.0;
  
  /// Medium radius (8px) - Buttons, inputs
  static const double radiusMd = 8.0;
  
  /// Large radius (12px) - Cards
  static const double radiusLg = 12.0;
  
  /// Extra large radius (16px) - Modals, bottom sheets
  static const double radiusXl = 16.0;
  
  /// Full radius (999px) - Pills, circular
  static const double radiusFull = 999.0;
  
  /// Card border radius
  static const double cardRadius = 12.0;

  // ============================================
  // Icon Sizes
  // ============================================
  
  /// Small icon (16px)
  static const double iconSm = 16.0;
  
  /// Medium icon (20px)
  static const double iconMd = 20.0;
  
  /// Large icon (24px)
  static const double iconLg = 24.0;
  
  /// Extra large icon (32px)
  static const double iconXl = 32.0;
  
  /// Double extra large icon (64px)
  static const double iconXxl = 64.0;
  
  /// Hero icon (48px)
  static const double iconHero = 48.0;

  // ============================================
  // Avatar Sizes
  // ============================================
  
  /// Small avatar (32px)
  static const double avatarSm = 32.0;
  
  /// Medium avatar (40px)
  static const double avatarMd = 40.0;
  
  /// Large avatar (56px)
  static const double avatarLg = 56.0;
  
  /// Extra large avatar (80px)
  static const double avatarXl = 80.0;

  // ============================================
  // Image Sizes
  // ============================================
  
  /// Thumbnail size (80px)
  static const double thumbnailSize = 80.0;
  
  /// Card image height (160px)
  static const double cardImageHeight = 160.0;
  
  /// Hero image height (200px)
  static const double heroImageHeight = 200.0;

  // ============================================
  // Card Dimensions
  // ============================================
  
  /// Card padding (16px)
  static const double cardPadding = 16.0;

  // ============================================
  // Helper Methods
  // ============================================
  
  /// Get EdgeInsets with all sides equal
  static EdgeInsets all(double value) => EdgeInsets.all(value);
  
  /// Get symmetric EdgeInsets
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  
  /// Get BorderRadius.circular
  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
}
