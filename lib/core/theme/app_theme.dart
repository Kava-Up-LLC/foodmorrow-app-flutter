import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Shapes and spacing (DESIGN.md §4), in one place so no view invents its own.
abstract final class Shapes {
  /// Screen side padding.
  static const side = 20.0;

  /// Space between cards.
  static const gap = 12.0;

  /// Nothing is hidden behind the floating tab bar.
  static const bottomInset = 110.0;

  static const card = BorderRadius.all(Radius.circular(22));
  static const banner = BorderRadius.all(Radius.circular(24));
  static const tile = BorderRadius.all(Radius.circular(18));
  static const small = BorderRadius.all(Radius.circular(10));
}

/// A white card with the app's one shadow.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.radius = Shapes.card, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        boxShadow: AppColors.shadow,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: box),
    );
  }
}

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.green,
      secondary: AppColors.greenText,
      surface: AppColors.surface,
      error: AppColors.orange,
    ),
    textTheme: base.textTheme.apply(fontFamily: AppText.family, bodyColor: AppColors.ink),
    splashFactory: InkRipple.splashFactory,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.body.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: Shapes.tile),
      // A floating message lands exactly where the bottom button and the tab bar are. Lift it
      // clear of both, so "Order saved" never swallows the tap on "Mark as picked up".
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.surface,
      headerBackgroundColor: AppColors.green,
      headerForegroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: Shapes.card),
    ),
  );
}
