import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Helper class để xác định platform và screen size
class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static bool isWeb() {
    return kIsWeb;
  }

  static bool isDesktopPlatform() {
    return kIsWeb || 
           defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.linux;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Breakpoints cho responsive design
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;

  /// Sidebar width cho desktop
  static const double sidebarWidth = 280;
  static const double sidebarCollapsedWidth = 80;

  /// Max width cho content trên desktop để tránh quá rộng
  static const double maxContentWidth = 1400;

  /// Scale factor cho desktop để UI không quá to
  static double getScaleFactor(BuildContext context) {
    final width = getScreenWidth(context);
    if (width >= desktopBreakpoint) {
      // Desktop: scale down để UI không quá to
      return 0.8;
    } else if (width >= tabletBreakpoint) {
      // Tablet: scale nhẹ
      return 0.9;
    }
    // Mobile: không scale
    return 1.0;
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final scaleFactor = getScaleFactor(context);
    return baseFontSize * scaleFactor;
  }

  /// Get responsive padding
  static double getResponsivePadding(BuildContext context, double basePadding) {
    final scaleFactor = getScaleFactor(context);
    return basePadding * scaleFactor;
  }
}

/// Enum để định nghĩa device type
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Extension để dễ dàng sử dụng
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  
  DeviceType get deviceType {
    if (isMobile) return DeviceType.mobile;
    if (isTablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  double get screenWidth => ResponsiveHelper.getScreenWidth(this);
  double get screenHeight => ResponsiveHelper.getScreenHeight(this);
}
