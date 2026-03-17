import 'package:flutter/material.dart';

class ResponsiveLayout {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  /// 태블릿 이상 (>= 600px)
  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  /// 태블릿 가로 또는 데스크톱 (>= 840px) — 2-column 레이아웃 임계값
  static bool isWideLayout(BuildContext context) =>
      MediaQuery.of(context).size.width >= 840;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1100.0;
    if (isTablet(context)) return 800.0;
    return double.infinity;
  }

  /// 화면 크기에 맞는 패딩
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(32);
    if (isTabletOrLarger(context)) return const EdgeInsets.all(20);
    return const EdgeInsets.all(16);
  }

  /// 태블릿+ 에서 BottomSheet 너비를 600px로 제한
  static BoxConstraints? bottomSheetConstraints(BuildContext context) {
    if (!isTabletOrLarger(context)) return null;
    return const BoxConstraints(maxWidth: 600);
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
