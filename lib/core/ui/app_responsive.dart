import 'package:flutter/material.dart';

/// Responsive layout utilities for tablet and phone support.
///
/// Usage:
/// ```dart
/// AppResponsiveBuilder(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
/// )
/// ```

/// Breakpoints used across the app.
abstract class AppBreakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Device type inferred from screen width.
enum AppDeviceType { phone, tablet, desktop }

AppDeviceType getDeviceType(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= AppBreakpoints.desktop) return AppDeviceType.desktop;
  if (width >= AppBreakpoints.tablet) return AppDeviceType.tablet;
  return AppDeviceType.phone;
}

bool isPhone(BuildContext context) =>
    getDeviceType(context) == AppDeviceType.phone;

bool isTablet(BuildContext context) =>
    getDeviceType(context) == AppDeviceType.tablet;

bool isDesktop(BuildContext context) =>
    getDeviceType(context) == AppDeviceType.desktop;

/// Builder that switches between mobile, tablet, and desktop layouts.
class AppResponsiveBuilder extends StatelessWidget {
  const AppResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case AppDeviceType.desktop:
        return (desktop ?? tablet ?? mobile)(context);
      case AppDeviceType.tablet:
        return (tablet ?? mobile)(context);
      case AppDeviceType.phone:
        return mobile(context);
    }
  }
}

/// A grid that adapts its column count based on device type.
class AppResponsiveGrid extends StatelessWidget {
  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.phoneCrossAxisCount = 1,
    this.tabletCrossAxisCount = 2,
    this.desktopCrossAxisCount = 3,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.childAspectRatio = 1,
    this.padding = const EdgeInsets.all(16),
  });

  final List<Widget> children;
  final int phoneCrossAxisCount;
  final int tabletCrossAxisCount;
  final int desktopCrossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final type = getDeviceType(context);
    final crossAxisCount = switch (type) {
      AppDeviceType.phone => phoneCrossAxisCount,
      AppDeviceType.tablet => tabletCrossAxisCount,
      AppDeviceType.desktop => desktopCrossAxisCount,
    };

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

/// A layout that shows a sidebar on tablets/desktops and a bottom nav on phones.
class AppAdaptiveScaffold extends StatelessWidget {
  const AppAdaptiveScaffold({
    super.key,
    required this.body,
    this.sidebar,
    this.bottomNavigationBar,
    this.appBar,
    this.floatingActionButton,
  });

  final Widget body;
  final Widget? sidebar;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final type = getDeviceType(context);
    final showSidebar = type != AppDeviceType.phone && sidebar != null;

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showSidebar ? null : bottomNavigationBar,
      body: Row(
        children: [
          if (showSidebar)
            SizedBox(
              width: 280,
              child: sidebar!,
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
