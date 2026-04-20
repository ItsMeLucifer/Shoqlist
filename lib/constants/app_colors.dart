import 'package:flutter/material.dart';

/// Brand palette used across the app. Keep in sync with the theme in `main.dart`.
class AppColors {
  AppColors._();

  /// Primary pink — buttons, accents, highlighted text.
  static const Color brandPink = Color.fromRGBO(242, 102, 116, 1);

  /// Neutral surface — dialogs, list tiles.
  static const Color surfaceGray = Color.fromRGBO(237, 236, 242, 1);

  /// Slightly warmer surface variant used by card backgrounds.
  static const Color surfaceGrayWarm = Color.fromRGBO(237, 236, 243, 1);

  /// Icon tint on neutral surfaces.
  static const Color neutralIcon = Color.fromRGBO(187, 191, 201, 1);

  /// Importance colors.
  static const Color importanceLow = Color.fromRGBO(66, 129, 164, 1);
  static const Color importanceNormal = Color.fromRGBO(67, 197, 158, 1);
  static const Color importanceImportant = Color.fromRGBO(253, 202, 64, 1);
  static const Color importanceUrgent = brandPink;
}
