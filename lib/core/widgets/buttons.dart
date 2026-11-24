import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Full width, 56 high, green. Fixed at the bottom of a pushed screen. It can carry a detail after
/// a dot ("Save order · Wed 25"), and shows a spinner while the cloud answers.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.detail,
    this.busy = false,
    this.icon,
  });

  final String label;
  final String? detail;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Material(
        color: enabled ? AppColors.green : AppColors.green.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 22, color: Colors.white),
                            const SizedBox(width: 10),
                          ],
                          Text(label, style: AppText.bodyLarge.copyWith(color: Colors.white)),
                          if (detail != null) ...[
                            Text('  ·  ', style: AppText.bodyLarge.copyWith(color: Colors.white70)),
                            Text(detail!, style: AppText.bodyLarge.copyWith(color: Colors.white)),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Same shape as [PrimaryButton], white with a green border.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.green, width: 1.5),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: AppColors.greenText),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppText.bodyLarge.copyWith(color: AppColors.greenText)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The small green pill: "See full list", "New order", "Retry".
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 40,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(height / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: height * 0.45),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppText.smaller.copyWith(
                    color: Colors.white,
                    fontSize: height >= 44 ? 15 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 44 white circle: back, search, delete.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.color = AppColors.ink,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      container: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 44,
        height: 44,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: AppColors.shadow,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Icon(icon, size: 22, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// The green square `+` on the Menu screen.
class SquareAddButton extends StatelessWidget {
  const SquareAddButton({super.key, required this.onPressed, this.semanticLabel = 'Add'});

  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      container: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: AppColors.green,
          borderRadius: Shapes.tile,
          child: InkWell(
            borderRadius: Shapes.tile,
            onTap: onPressed,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
