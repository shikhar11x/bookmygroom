import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double screenPadding = 20;

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 28;
  static const double radiusPill = 100;

  static const EdgeInsets screenInsets = EdgeInsets.symmetric(
    horizontal: screenPadding,
  );

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
}
