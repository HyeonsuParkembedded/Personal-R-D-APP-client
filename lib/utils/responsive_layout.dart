import 'package:flutter/material.dart';

class ResponsiveLayout {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1100.0;
    if (isTablet(context)) return 800.0;
    return double.infinity;
  }
}

class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final bool center;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveLayout.contentMaxWidth(context);
    
    Widget result = child;
    if (maxWidth != double.infinity) {
      result = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      );
      if (center) {
        result = Center(child: result);
      }
    }
    return result;
  }
}
