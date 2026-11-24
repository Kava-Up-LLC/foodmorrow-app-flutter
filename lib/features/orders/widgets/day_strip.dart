import 'package:flutter/material.dart';

import '../../../core/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';

/// The week strip: 7 tiles with the weekday, the day number and up to 3 dots for orders.
/// Swiping left or right moves one week.
class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.ordersOn,
    required this.onSelect,
    required this.onMoveWeek,
  });

  final List<DateTime> days;
  final DateTime selected;
  final int Function(DateTime) ordersOn;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onMoveWeek;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -250) onMoveWeek(1);
        if (v > 250) onMoveWeek(-1);
      },
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _DayTile(
                  day: days[i],
                  selected: Dates.key(days[i]) == Dates.key(selected),
                  orders: ordersOn(days[i]),
                  onTap: () => onSelect(days[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.selected,
    required this.orders,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final int orders;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dots = orders.clamp(0, 3);
    return Semantics(
      button: true,
      selected: selected,
      label: '${Dates.long(day)}, ${orders == 1 ? '1 order' : '$orders orders'}',
      container: true,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? AppColors.green : AppColors.surface,
          borderRadius: Shapes.tile,
          child: InkWell(
            borderRadius: Shapes.tile,
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: Shapes.tile,
                boxShadow: selected ? null : AppColors.shadow,
                color: selected ? AppColors.green : AppColors.surface,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Dates.weekdayShort(day),
                    style: AppText.smaller.copyWith(
                      fontSize: 12,
                      color: selected ? Colors.white70 : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${day.day}',
                    style: AppText.body.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < dots; i++) ...[
                          if (i > 0) const SizedBox(width: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? Colors.white : AppColors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
