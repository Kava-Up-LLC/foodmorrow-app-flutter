import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Identifies the `+` in the tab bar, which shares its name with the empty-state buttons.
const newOrderButtonKey = Key('tab_new_order');

/// The five slots of the tab bar. The middle one is not a tab: it opens New order.
enum AppTab { home, orders, menu, settings }

/// The floating white pill (DESIGN.md §5). The active tab is a green pill with its label; the
/// others are 46 circles. The middle `+` is a 52 green circle.
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onNewOrder,
  });

  final AppTab current;
  final ValueChanged<AppTab> onSelect;
  final VoidCallback onNewOrder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 22 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(34),
          boxShadow: AppColors.shadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // The active slot carries a word, so it gets most of the room; the plain circles
            // need no more than their 46. Flex rather than fixed widths, so a long label still
            // gives way instead of overflowing on a narrow phone.
            _flex(AppTab.home, Icons.home_rounded, 'Home', current, onSelect),
            _flex(AppTab.orders, Icons.calendar_month_rounded, 'Orders', current, onSelect),
            _NewOrderButton(onPressed: onNewOrder),
            _flex(AppTab.menu, Icons.restaurant_rounded, 'Menu', current, onSelect),
            _flex(AppTab.settings, Icons.settings_rounded, 'Settings', current, onSelect),
          ],
        ),
      ),
    );
  }
}

Widget _flex(
  AppTab tab,
  IconData icon,
  String label,
  AppTab current,
  ValueChanged<AppTab> onSelect,
) =>
    Flexible(
      flex: tab == current ? 4 : 1,
      child: _Slot(tab: tab, icon: icon, label: label, current: current, onSelect: onSelect),
    );

class _Slot extends StatelessWidget {
  const _Slot({
    required this.tab,
    required this.icon,
    required this.label,
    required this.current,
    required this.onSelect,
  });

  final AppTab tab;
  final IconData icon;
  final String label;
  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final active = tab == current;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      container: true,
      // The active tab also shows its name; without this the node would read it twice.
      excludeSemantics: true,
      child: Material(
        color: active ? AppColors.green : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onSelect(tab),
          child: Container(
            height: 48,
            constraints: const BoxConstraints(minWidth: 46),
            padding: EdgeInsets.symmetric(horizontal: active ? 14 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: active ? null : Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: active ? Colors.white : AppColors.muted),
                if (active) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: AppText.body.copyWith(color: Colors.white, fontSize: 15),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewOrderButton extends StatelessWidget {
  const _NewOrderButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: newOrderButtonKey,
      button: true,
      label: 'New order',
      container: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Material(
          color: AppColors.green,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
