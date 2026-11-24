import 'package:flutter/material.dart';

import '../../../core/dates.dart';
import '../../../core/food_photos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../data/home_data.dart';

/// The deep-green banner: the one question the app answers. The photo is the item with the most
/// to make and bleeds off the right edge.
class TomorrowBanner extends StatelessWidget {
  const TomorrowBanner({super.key, required this.plan, required this.onSeeFullList});

  final TomorrowPlan plan;
  final VoidCallback onSeeFullList;

  @override
  Widget build(BuildContext context) {
    final asset = FoodPhotos.assetOf(plan.bannerPhoto);
    return Semantics(
      container: true,
      label: 'Tomorrow, ${Dates.short(plan.date)}. ${plan.things} things to make.',
      child: ClipRRect(
        borderRadius: Shapes.banner,
        child: Container(
          height: 150,
          decoration: const BoxDecoration(color: AppColors.deep, borderRadius: Shapes.banner),
          child: Stack(
            children: [
              if (asset != null)
                Positioned(
                  right: -34,
                  top: -9,
                  child: SizedBox(
                    width: 168,
                    height: 168,
                    child: ClipOval(child: Image.asset(asset, fit: BoxFit.cover)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tomorrow · ${Dates.short(plan.date)}',
                      style: AppText.small.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // The number is the point of the screen: it takes the room that is left and
                    // scales down rather than hiding "to make" behind the pill.
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('${plan.things} things\nto make', style: AppText.bannerNumber),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    PillButton(label: 'See full list', onPressed: onSeeFullList, height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What Home shows when tomorrow is still empty (screen 03).
class NothingTomorrowCard extends StatelessWidget {
  const NothingTomorrowCard({super.key, required this.date, required this.onNewOrder});

  final DateTime date;
  final VoidCallback onNewOrder;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.greenTint, shape: BoxShape.circle),
            child: const Icon(Icons.shopping_bag_rounded, size: 30, color: AppColors.greenText),
          ),
          const SizedBox(height: 18),
          Text('No orders for tomorrow yet', style: AppText.navTitle, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Add an order when someone asks. What to make for ${Dates.weekday(date)} will show up here.',
            style: AppText.bodyRegular.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          PillButton(label: 'New order', onPressed: onNewOrder, icon: Icons.add_rounded, height: 48),
        ],
      ),
    );
  }
}
