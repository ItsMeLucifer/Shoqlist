import 'package:flutter/material.dart';

/// Brand palette used across the app. Keep in sync with the theme in `main.dart`.
///
/// **Paleta pastelowa** (kwiecień 2026): zmiękczone wartości RGB — niższa
/// saturacja, wyższa lightness. Importance levels zachowują skojarzenia
/// (sky / mint / butter / pink) w cieplejszej, bardziej harmonijnej formie.
class AppColors {
  AppColors._();

  /// Primary pink — domyślny accent: buttons, header icons, navbar selected.
  /// Po wejściu w detail listy chwilowo zastępowany przez `importanceColor`
  /// tej listy poprzez `accentColorProvider` (patrz `lib/main.dart`).
  static const Color brandPink = Color.fromRGBO(240, 150, 165, 1);

  /// Neutral surface — dialogs, list tiles.
  static const Color surfaceGray = Color.fromRGBO(237, 236, 242, 1);

  /// Slightly warmer surface variant used by card backgrounds.
  static const Color surfaceGrayWarm = Color.fromRGBO(237, 236, 243, 1);

  /// Icon tint on neutral surfaces.
  static const Color neutralIcon = Color.fromRGBO(187, 191, 201, 1);

  /// Importance colors (pastel set).
  static const Color importanceLow = Color.fromRGBO(150, 190, 215, 1);
  static const Color importanceNormal = Color.fromRGBO(155, 215, 190, 1);
  static const Color importanceImportant = Color.fromRGBO(245, 215, 140, 1);
  static const Color importanceUrgent = brandPink;

  // -- Functional tokens ------------------------------------------------------

  /// Pastel red — tekst/ikona przy destruktywnych akcjach (delete account,
  /// swipe-delete pane). Spójniejsze niż `Colors.red.*`.
  static const Color dangerSoft = Color.fromRGBO(225, 130, 140, 1);

  /// Soft border dla danger sekcji (np. delete account card w settings).
  static const Color dangerSoftBorder = Color.fromRGBO(240, 195, 200, 1);

  /// Pastel niebieski dla swipe-edit action pane.
  static const Color editTone = Color.fromRGBO(140, 175, 215, 1);

  /// = `dangerSoft`. Alias z myślą o swipe-delete; sygnalizuje role.
  static const Color deleteTone = dangerSoft;

  /// Subtelne wypełnienie dla TextField — zamiast transparent wygląda
  /// "wciśnięte" w surface, ładniej w pastelowym layout.
  static const Color inputFill = Color.fromRGBO(245, 244, 248, 1);

  /// Divider między tile'ami w settings cards / podobnych grupach.
  static const Color dividerSoft = Color.fromRGBO(225, 224, 230, 1);
}
