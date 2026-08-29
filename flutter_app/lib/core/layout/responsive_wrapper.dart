import 'package:flutter/material.dart';

/// Responsive breakpoints
class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

/// A responsive layout wrapper that constrains content width on large screens
/// and adjusts padding based on viewport size.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool useSafeArea;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.useSafeArea = true,
  });

  static double padding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < Breakpoints.mobile) return 20;
    if (width < Breakpoints.tablet) return 28;
    return 40;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < Breakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= Breakpoints.mobile && w < Breakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Breakpoints.desktop,
        ),
        child: child,
      ),
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}

/// A responsive grid that adapts columns based on screen width
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? forceColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.forceColumns,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    int columns;
    if (forceColumns != null) {
      columns = forceColumns!;
    } else if (width < Breakpoints.mobile) {
      columns = 1;
    } else if (width < Breakpoints.tablet) {
      columns = 2;
    } else {
      columns = 3;
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        return SizedBox(
          width: (width - (columns - 1) * spacing) / columns,
          child: child,
        );
      }).toList(),
    );
  }
}
