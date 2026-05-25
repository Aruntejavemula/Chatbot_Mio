import 'package:flutter/material.dart';

/// Utility class for responsive breakpoint detection.
class Responsive {
  Responsive._();

  static bool isPhone(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width < 600;

  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600 &&
      MediaQuery.of(ctx).size.width < 1100;

  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 1100;

  static bool isLandscape(BuildContext ctx) =>
      MediaQuery.of(ctx).orientation == Orientation.landscape;
}
