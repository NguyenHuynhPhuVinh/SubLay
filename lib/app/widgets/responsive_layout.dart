import 'package:flutter/material.dart';
import '../core/utils/responsive_helper.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return desktop;
    } else if (context.isTablet && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(context, context.deviceType);
  }
}

/// Widget wrapper để giới hạn width trên desktop
class DesktopContentWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const DesktopContentWrapper({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!context.isDesktop) {
      return child;
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveHelper.maxContentWidth,
        ),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
        child: child,
      ),
    );
  }
}

/// Layout cho desktop với sidebar
class DesktopLayout extends StatefulWidget {
  final Widget sidebar;
  final Widget content;
  final bool initialSidebarCollapsed;

  const DesktopLayout({
    Key? key,
    required this.sidebar,
    required this.content,
    this.initialSidebarCollapsed = false,
  }) : super(key: key);

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  late bool _isSidebarCollapsed;

  @override
  void initState() {
    super.initState();
    _isSidebarCollapsed = widget.initialSidebarCollapsed;
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          widget.sidebar,
          // Main content
          Expanded(
            child: widget.content,
          ),
        ],
      ),
    );
  }
}

/// Grid layout responsive cho content
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
    this.runSpacing = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int columns;
    if (context.isDesktop) {
      columns = desktopColumns;
    } else if (context.isTablet) {
      columns = tabletColumns;
    } else {
      columns = mobileColumns;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive padding
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? mobile;
  final EdgeInsetsGeometry? tablet;
  final EdgeInsetsGeometry? desktop;

  const ResponsivePadding({
    Key? key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry padding;
    
    if (context.isDesktop && desktop != null) {
      padding = desktop!;
    } else if (context.isTablet && tablet != null) {
      padding = tablet!;
    } else {
      padding = mobile ?? const EdgeInsets.all(16);
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Responsive spacing
class ResponsiveSpacing extends StatelessWidget {
  final double mobile;
  final double? tablet;
  final double? desktop;
  final bool isHorizontal;

  const ResponsiveSpacing({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.isHorizontal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double spacing;

    if (context.isDesktop && desktop != null) {
      spacing = desktop!;
    } else if (context.isTablet && tablet != null) {
      spacing = tablet!;
    } else {
      spacing = mobile;
    }

    return SizedBox(
      width: isHorizontal ? spacing : null,
      height: isHorizontal ? null : spacing,
    );
  }
}

/// Responsive scale wrapper để scale UI phù hợp với screen size
class ResponsiveScale extends StatelessWidget {
  final Widget child;

  const ResponsiveScale({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaleFactor = ResponsiveHelper.getScaleFactor(context);

    if (scaleFactor == 1.0) {
      return child;
    }

    return Transform.scale(
      scale: scaleFactor,
      child: child,
    );
  }
}
