import 'package:flutter/material.dart';

class AppSizes {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Spacing aliases for backward compatibility
  static const double spacingXSmall = xs;
  static const double spacingSmall = sm;
  static const double spacingMedium = md;
  static const double spacingLarge = lg;
  static const double spacingXLarge = xl;
  static const double spacingXXLarge = xxl;
  
  // Padding
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  
  // Padding aliases for backward compatibility
  static const double paddingSmall = sm;
  static const double paddingMedium = md;
  static const double paddingLarge = lg;
  
  static const EdgeInsets paddingHorizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingVerticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLG = EdgeInsets.symmetric(vertical: lg);
  
  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;
  
  // Border radius aliases for backward compatibility
  static const double borderRadius = radiusMD;
  
  static const BorderRadius borderRadiusXS = BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderRadiusSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusXXL = BorderRadius.all(Radius.circular(radiusXXL));
  
  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;
  
  // Button Heights
  static const double buttonHeightSM = 36.0;
  static const double buttonHeightMD = 44.0;
  static const double buttonHeightLG = 52.0;
  static const double buttonHeightXL = 60.0;
  
  // Card Dimensions
  static const double cardElevation = 4.0;
  static const double cardElevationHover = 8.0;
  static const double cardElevationPressed = 2.0;
  
  // App Bar
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 120.0;
  
  // Bottom Navigation
  static const double bottomNavHeight = 60.0;
  static const double bottomNavHeightLarge = 80.0;
  
  // Avatar Sizes
  static const double avatarXS = 24.0;
  static const double avatarSM = 32.0;
  static const double avatarMD = 48.0;
  static const double avatarLG = 64.0;
  static const double avatarXL = 96.0;
  static const double avatarXXL = 128.0;
  
  // List Items
  static const double listItemHeight = 72.0;
  static const double listItemHeightSM = 56.0;
  static const double listItemHeightLG = 88.0;
  
  // Marquee
  static const double marqueeHeight = 120.0;
  static const double marqueeVelocity = 50.0;
  
  // Consultation Cards
  static const double consultationCardHeight = 160.0;
  static const double consultationCardWidth = 280.0;
  static const double doctorCardHeight = 200.0;
  static const double doctorCardWidth = 300.0;
  
  // Input Fields
  static const double inputHeight = 48.0;
  static const double inputHeightLarge = 56.0;
  static const double inputBorderWidth = 1.0;
  static const double inputBorderWidthFocused = 2.0;
  
  // Floating Action Button
  static const double fabSize = 56.0;
  static const double fabSizeSmall = 40.0;
  static const double fabSizeLarge = 64.0;
  
  // Dialog
  static const double dialogBorderRadius = 16.0;
  static const double dialogElevation = 24.0;
  static const double dialogMaxWidth = 400.0;
  
  // Breakpoints for responsive design
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
  
  // Content widths
  static const double contentMaxWidth = 1200.0;
  static const double sidebarWidth = 280.0;
  static const double sidebarWidthCollapsed = 64.0;
  
  // Z-Index values
  static const double zIndexBase = 0;
  static const double zIndexModal = 1000;
  static const double zIndexTooltip = 1500;
  static const double zIndexNotification = 2000;
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 1000);
  
  // Splash screen
  static const Duration splash = Duration(seconds: 2);
  static const Duration splashDelay = Duration(milliseconds: 500);
  
  // Animations
  static const Duration fadeIn = Duration(milliseconds: 300);
  static const Duration fadeOut = Duration(milliseconds: 200);
  static const Duration slideIn = Duration(milliseconds: 400);
  static const Duration slideOut = Duration(milliseconds: 300);
  static const Duration scaleIn = Duration(milliseconds: 200);
  static const Duration scaleOut = Duration(milliseconds: 150);
  static const Duration rotate = Duration(milliseconds: 400);
  
  // UI Interactions
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration ripple = Duration(milliseconds: 300);
  static const Duration pageTransition = Duration(milliseconds: 250);
  static const Duration tabTransition = Duration(milliseconds: 200);
  
  // Network & Loading
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(minutes: 2);
  static const Duration apiTimeout = Duration(seconds: 15);
  
  // Notifications
  static const Duration snackBar = Duration(seconds: 4);
  static const Duration toast = Duration(seconds: 2);
  static const Duration notification = Duration(seconds: 5);
  
  // Video call
  static const Duration callTimeout = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 3);
  
  // Database operations
  static const Duration dbTimeout = Duration(seconds: 10);
  static const Duration syncInterval = Duration(minutes: 5);
}

class AppAnimationCurves {
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticIn = Curves.elasticIn;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve linear = Curves.linear;
  static const Curve decelerate = Curves.decelerate;
}