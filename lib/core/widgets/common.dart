import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../errors.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'buttons.dart';

/// − number + . The buttons are 32 visible with a 44 hit area (DESIGN.md §4).
class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onChanged, this.max = 999});

  final int value;
  final ValueChanged<int> onChanged;
  final int max;

  @override
  Widget build(BuildContext context) {
    final canRemove = value > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          semanticLabel: 'One less',
          fill: canRemove ? AppColors.greenTint : AppColors.disabledFill,
          iconColor: canRemove ? AppColors.greenText : AppColors.disabledIcon,
          onPressed: canRemove
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged(value - 1);
                }
              : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppText.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          semanticLabel: 'One more',
          fill: value < max ? AppColors.green : AppColors.disabledFill,
          iconColor: value < max ? Colors.white : AppColors.disabledIcon,
          onPressed: value < max
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged(value + 1);
                }
              : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.fill,
    required this.iconColor,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final Color fill;
  final Color iconColor;
  final VoidCallback? onPressed;
  final String semanticLabel;

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
        child: Center(
          child: Material(
            color: fill,
            borderRadius: Shapes.small,
            child: InkWell(
              borderRadius: Shapes.small,
              onTap: onPressed,
              child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 20, color: iconColor)),
            ),
          ),
        ),
      ),
    );
  }
}

/// "To make" / "Picked up".
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.pickedUp});

  final bool pickedUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: pickedUp ? AppColors.greenTint : AppColors.orangeTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pickedUp) ...[
            const Icon(Icons.check_rounded, size: 14, color: AppColors.greenText),
            const SizedBox(width: 4),
          ],
          Text(
            pickedUp ? 'Picked up' : 'To make',
            style: AppText.smaller.copyWith(
              color: pickedUp ? AppColors.greenText : AppColors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The round check of a pickup row: grey outline waiting, green filled when picked up.
class PickupCheck extends StatelessWidget {
  const PickupCheck({
    super.key,
    required this.pickedUp,
    required this.onPressed,
    required this.customer,
  });

  final bool pickedUp;
  final VoidCallback? onPressed;
  final String customer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: pickedUp,
      label: pickedUp ? 'Undo picked up for $customer' : 'Mark $customer as picked up',
      container: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Material(
            color: pickedUp ? AppColors.green : AppColors.surface,
            shape: CircleBorder(
              side: pickedUp
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.line, width: 1.5),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                width: 40,
                height: 40,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.check_rounded,
                    key: ValueKey(pickedUp),
                    size: 22,
                    color: pickedUp ? Colors.white : AppColors.line,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White input, 56 high, with a leading icon. Green 2 border when focused.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.maxLength,
    this.autofocus = false,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.words,
    this.maxLines = 1,
    this.dashed = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final int? maxLength;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final int maxLines;

  /// The note field is a dashed outline instead of a white card (screen 04).
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      autofocus: autofocus,
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      onSubmitted: onSubmitted,
      style: AppText.bodyLarge,
      cursorColor: AppColors.green,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.bodyRegular.copyWith(color: AppColors.muted),
        prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted, size: 22),
        filled: true,
        fillColor: dashed ? Colors.transparent : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: Shapes.tile, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: Shapes.tile,
          borderSide: dashed
              ? const BorderSide(color: AppColors.line, width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: Shapes.tile,
          borderSide: BorderSide(color: AppColors.green, width: 2),
        ),
      ),
    );
    if (dashed) return field;
    return DecoratedBox(
      decoration: const BoxDecoration(borderRadius: Shapes.tile, boxShadow: AppColors.shadow),
      child: field,
    );
  }
}

/// The No connection card (screen 10). The same one on every screen.
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.orangeTint, shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded, size: 20, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failure.title, style: AppText.body),
                Text(failure.message, style: AppText.small),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PillButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}

/// Section header: "For tomorrow", with an optional green link on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction, this.trailing});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.navTitle)),
          ?trailing,
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(action!, style: AppText.body.copyWith(color: AppColors.greenText)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The header of a pushed screen: back on the left, title centred, an optional action on the right.
class ScreenTopBar extends StatelessWidget {
  const ScreenTopBar({super.key, required this.title, this.trailing, this.onTitleLongPress});

  final String title;
  final Widget? trailing;

  /// Only the Orders tab uses this, for the test crash of spec §10.
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Shapes.side, 14, Shapes.side, 14),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            semanticLabel: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onLongPress: onTitleLongPress,
                child: Text(title, style: AppText.navTitle),
              ),
            ),
          ),
          SizedBox(width: 44, child: trailing),
        ],
      ),
    );
  }
}

/// Takes away any message still floating at the bottom before a screen with a bottom button
/// opens — otherwise "Order saved" sits right on top of the next "Save order".
void clearMessages(BuildContext context) => ScaffoldMessenger.of(context).removeCurrentSnackBar();
