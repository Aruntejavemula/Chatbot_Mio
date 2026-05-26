import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class MioAnimations {
  MioAnimations._();

  static const Duration standard = Duration(milliseconds: 300);
  static const Duration fast = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOutCubic;
  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 20,
  );
}
