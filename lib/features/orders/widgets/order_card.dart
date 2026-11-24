import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/food_photo.dart';
import '../data/order.dart';

/// One order in the list of a day: who, how many things, the status, and its items underneath.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = order.hasNote
        ? '${_itemsLabel(order.itemCount)} · has a note'
        : _itemsLabel(order.itemCount);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
            child: Row(
              children: [
                InitialAvatar(name: order.customer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        order.customer,
                        style: AppText.body.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(subtitle, style: AppText.smaller, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(pickedUp: order.pickedUp),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 22),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.line, indent: 14, endIndent: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                for (final line in order.items)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FoodPhoto(photoKey: line.photo, size: 30),
                      const SizedBox(width: 8),
                      Text(line.label, style: AppText.body),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _itemsLabel(int count) => count == 1 ? '1 item' : '$count items';
}
