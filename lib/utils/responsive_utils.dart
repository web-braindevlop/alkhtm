import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class ResponsiveUtils {
  // Device type breakpoints - Updated for iPad 13" (2732x2048 / 2752x2064)
  // iPad 13" logical width is ~1366px in landscape, ~1024px in portrait (at 2x scale)
  static const double mobileMaxWidth = 600;      // Phones
  static const double tabletMaxWidth = 1400;     // Tablets including iPad 13"
  static const double desktopMinWidth = 1401;    // Desktop/large displays
  
  // iPad 13" specific detection (logical pixels)
  static const double iPad13MinWidth = 1024;    // Portrait mode
  static const double iPad13MaxWidth = 1400;    // Landscape mode
  
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
    final width = size.width;
    final height = size.height;
    
    // iPad 13" detection (logical pixels at standard scale)
    // Portrait: ~1024x1366, Landscape: ~1366x1024
    // iPad Pro 12.9": ~1024x1366, Landscape: ~1366x1024
    // Also covers iPad Air 11" and other iPad sizes
    return (width >= 768 && width <= 1400) || 
           (height >= 768 && height <= 1400);
  }
  
  static bool isIPad13(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    
    // Specifically detect iPad 13" (12.9" actual)
    // Portrait: ~1024 width, Landscape: ~1366 width (at 2x pixel density)
    return (width >= iPad13MinWidth && width <= iPad13MaxWidth) ||
           (height >= iPad13MinWidth && height <= iPad13MaxWidth);
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
  // Optimized for iPad 13" to show 4 columns in landscape, 3 in portrait
  static int getGridCrossAxisCount(BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    // iPad 13" landscape (1366+ width) - show 4 columns
    if (width >= 1200) return desktop;
    
    // iPad 13" portrait or iPad Air landscape (1024-1199 width) - show 3 columns
    if (width >= 800) return tablet;
    
    // Mobile and small tablets - show 2 columns
    return mobile;
  }
  
  // Get spacing based on screen size - increased for iPad 13"
  static double getSpacing(BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    // iPad 13" gets larger spacing
    if (width >= 1200) return desktop;
    if (width >= 800) return tablet;
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
  
  // Get max content width for centered layouts - optimized for iPad 13"
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= 1400) return 1200;  // Desktop
    if (width >= 1200) return 1000;  // iPad 13" landscape
    if (width >= 800) return 700;    // iPad 13" portrait / iPad Air
    return double.infinity;          // Mobile
  }
  
  // Get padding based on screen size - optimized for iPad 13"
  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    // iPad 13" landscape - generous padding
    if (width >= 1200) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    }
    
    // iPad 13" portrait / iPad Air landscape
    if (width >= 800) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    
    // Mobile
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
  
  // Check if should use two-column layout
  static bool shouldUseTwoColumns(BuildContext context) {
    return MediaQuery.of(context).size.width >= 800;
  }
  
  // Get card width for grid items - optimized for iPad 13"
  static double getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    // iPad 13" landscape - slightly wider cards
    if (width >= 1200) return 0.78;
    
    // iPad 13" portrait / iPad Air
    if (width >= 800) return 0.8;
    
    // Mobile
    return 0.7;
  }
  
  // Get responsive font size that respects user's device text scaling
  // Clamps textScaleFactor between 0.8 and 1.3 to prevent UI breaking
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    // Clamp to reasonable range for better UX (0.8-1.3)
    final clampedScale = textScaleFactor.clamp(0.8, 1.3);
    return baseFontSize * clampedScale;
  }
}
