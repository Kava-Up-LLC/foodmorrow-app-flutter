import 'package:flutter/material.dart';

/// The "Fresh Batch" palette (DESIGN.md §2). Views take their colors from here, never a literal.
abstract final class AppColors {
  /// Screen background, every screen.
  static const bg = Color(0xFFEFF4F5);

  /// Cards, tab bar, inputs, round buttons.
  static const surface = Color(0xFFFFFFFF);

  /// Main text.
  static const ink = Color(0xFF0D1007);

  /// Secondary text and inactive icons.
  static const muted = Color(0xFF5C6661);

  /// Dividers, outlines of unselected tiles, inactive tab circles.
  static const line = Color(0xFFDDE5E3);

  /// Fills only: primary buttons, the active tab pill, `+`, the selected day, checks.
  /// Never use it for text on [bg] — it fails contrast. Use [greenText].
  static const green = Color(0xFF27852C);

  /// Green text: links, big quantities, initials.
  static const greenText = Color(0xFF1F6B24);

  /// Selected tiles, avatar circles, the minus button, icon circles.
  static const greenTint = Color(0xFFE5F1E6);

  /// The Home banner, and nothing else.
  static const deep = Color(0xFF0F4A33);

  /// Text on [deep] only.
  static const gold = Color(0xFFE0B565);

  /// "To make" status text and the no-connection icon.
  static const orange = Color(0xFFC34614);

  /// Behind the "To make" chip and the no-connection icon.
  static const orangeTint = Color(0xFFFBE9E1);

  /// The order note card. Its icon is [noteIcon].
  static const noteBg = Color(0xFFFBF3E4);
  static const noteIcon = Color(0xFFD19E49);

  /// Loading and no-connection placeholders.
  static const skeleton = Color(0xFFE2EAE8);

  /// A disabled stepper minus.
  static const disabledFill = Color(0xFFEDF1F0);
  static const disabledIcon = Color(0xFFA9B4B1);

  /// The one shadow of the whole app, on cards and floating things.
  static const shadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F0D1007), blurRadius: 20, offset: Offset(0, 6)),
  ];
}
