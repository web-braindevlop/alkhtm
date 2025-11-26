import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Device type breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double desktopMinWidth = 1025;
  
  // Check device type
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < desktopMinWidth;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopMinWidth;
  }
  
  static bool isIPad(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // iPad dimensions: 768x1024 (portrait) or 1024x768 (landscape)
    return (size.width >= 768 && size.width <= 1024) || 
           (size.height >= 768 && size.height <= 1024);
  }
  
  // Get responsive values
  static T valueWhen<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
  
  // Get grid cross axis count based on screen size
  static int getGridCrossAxisCount(BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
  
  // Get spacing based on screen size
  static double getSpacing(BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
  
  // Get font size based on screen size
  static double getFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? (tablet ?? mobile) * 1.2;
    if (isTablet(context)) return tablet ?? mobile * 1.1;
    return mobile;
  }
  
  // Get max content width for centered layouts
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 900;
    return double.infinity;
  }
  
  // Get padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getSpacing(context, mobile: 16, tablet: 32, desktop: 48),
      vertical: getSpacing(context, mobile: 16, tablet: 24, desktop: 32),
    );
  }
  
  // Check if should use two-column layout
  static bool shouldUseTwoColumns(BuildContext context) {
    return !isMobile(context);
  }
  
  // Get card width for grid items
  static double getCardAspectRatio(BuildContext context) {
    if (isDesktop(context)) return 0.75;
    if (isTablet(context)) return 0.8;
    return 0.7;
  }
}
