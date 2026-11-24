import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/food_photo.dart';
import '../data/home_data.dart';

/// One product of the "For tomorrow" row: name, how many orders, photo, and the big quantity.
class MakeCard extends StatelessWidget {
  const MakeCard({super.key, required this.item});

  final MakeItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${item.qty} ${item.name} to make, in ${item.ordersLabel}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 150,
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(item.ordersLabel, style: AppText.small),
                const SizedBox(height: 12),
                FoodPhoto(photoKey: item.photo, size: 78),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        '${item.qty}',
                        style: AppText.qtyBig,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('to make', style: AppText.body.copyWith(fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One person picking up today, with the check that ticks them off.
class PickupRow extends StatelessWidget {
  const PickupRow({
    super.key,
    required this.pickup,
    required this.onToggle,
    required this.busy,
  });

  final Pickup pickup;
  final VoidCallback onToggle;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          FoodPhoto(photoKey: pickup.photo, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppText.body.copyWith(
                    color: pickup.pickedUp ? AppColors.muted : AppColors.ink,
                    decoration: pickup.pickedUp ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: AppColors.muted,
                  ),
                  child: Text(pickup.customer, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 2),
                Text(
                  pickup.itemsLabel,
                  style: AppText.smaller,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.green),
                ),
              ),
            )
          else
            PickupCheck(
              pickedUp: pickup.pickedUp,
              customer: pickup.customer,
              onPressed: onToggle,
            ),
        ],
      ),
    );
  }
}
