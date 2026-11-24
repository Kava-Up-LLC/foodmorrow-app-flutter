import 'package:flutter/material.dart';

import '../../../core/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/food_photo.dart';
import '../data/home_data.dart';

/// "See full list": every item to make tomorrow with its photo and quantity.
Future<void> showTomorrowListSheet(BuildContext context, TomorrowPlan plan) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bg,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _TomorrowListSheet(plan: plan),
  );
}

class _TomorrowListSheet extends StatelessWidget {
  const _TomorrowListSheet({required this.plan});

  final TomorrowPlan plan;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Shapes.side, 4, Shapes.side, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tomorrow · ${Dates.short(plan.date)}', style: AppText.small),
                  const SizedBox(height: 2),
                  Text('${plan.things} things to make', style: AppText.title),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(Shapes.side, 14, Shapes.side, 24),
                itemCount: plan.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = plan.items[i];
                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        FoodPhoto(photoKey: item.photo, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item.name, style: AppText.body),
                              Text(item.ordersLabel, style: AppText.smaller),
                            ],
                          ),
                        ),
                        Text(
                          '×${item.qty}',
                          style: AppText.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
