import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../app_services.dart';
import '../../../core/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/floating_tab_bar.dart';
import '../home_controller.dart';
import '../widgets/make_card.dart';
import '../widgets/tomorrow_banner.dart';
import 'tomorrow_list_sheet.dart';

/// Home: the date, the business name, what to make tomorrow and today's pickups (screen 02).
class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.services, required this.shell});

  final AppServices services;
  final HomeShellState shell;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeController _controller = HomeController(
    repository: widget.services.home,
    orders: widget.services.orders,
    analytics: widget.services.analytics,
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final data = _controller.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(Shapes.side, 24, Shapes.side, Shapes.bottomInset),
            children: [
              Text(Dates.long(Dates.today()), style: AppText.small),
              const SizedBox(height: 2),
              if (data == null)
                // The real name arrives with the rest; a placeholder of the same height keeps
                // the screen from jumping when it does.
                const Shimmer(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: SkeletonLine(width: 190, height: 20),
                  ),
                )
              else
                Text(data.businessName, style: AppText.greeting),
              const SizedBox(height: 18),
              if (_controller.failure != null) ...[
                AlertBanner(failure: _controller.failure!, onRetry: _controller.load),
                const SizedBox(height: Shapes.gap),
              ],
              if (data == null)
                const _HomeSkeletons()
              else ...[
                if (data.tomorrow.isEmpty)
                  NothingTomorrowCard(
                    date: data.tomorrow.date,
                    onNewOrder: widget.shell.openNewOrder,
                  )
                else ...[
                  TomorrowBanner(
                    plan: data.tomorrow,
                    onSeeFullList: () {
                      _controller.trackTomorrowListViewed();
                      showTomorrowListSheet(context, data.tomorrow);
                    },
                  ),
                  SectionHeader(
                    title: 'For tomorrow',
                    action: 'See all',
                    onAction: () => widget.shell.openTab(AppTab.orders, onDay: data.tomorrow.date),
                  ),
                  SizedBox(
                    height: 232,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: data.tomorrow.items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: Shapes.gap),
                      itemBuilder: (context, i) => MakeCard(item: data.tomorrow.items[i]),
                    ),
                  ),
                ],
                SectionHeader(
                  title: 'Pickups today',
                  trailing: Text(data.today.doneLabel, style: AppText.small),
                ),
                if (data.today.pickups.isEmpty)
                  Text(
                    'Nobody is picking up today.',
                    style: AppText.bodyRegular.copyWith(color: AppColors.muted),
                  )
                else
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < data.today.pickups.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.line,
                              indent: 14,
                              endIndent: 14,
                            ),
                          PickupRow(
                            pickup: data.today.pickups[i],
                            busy: _controller.pendingPickup == data.today.pickups[i].id,
                            onToggle: () => _controller.togglePickedUp(data.today.pickups[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// What Home looks like while it loads, and under the No connection banner (screen 10).
/// It is laid out like the real thing — banner, section header, two product cards, the pickup
/// list — so the screen does not rearrange itself when the answer lands.
class _HomeSkeletons extends StatelessWidget {
  const _HomeSkeletons();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer(child: SkeletonBox(height: 150, radius: 24)),
        SizedBox(height: 22),
        Shimmer(child: SkeletonLine(width: 150, height: 18)),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _MakeCardSkeleton()),
            SizedBox(width: Shapes.gap),
            Expanded(child: _MakeCardSkeleton()),
          ],
        ),
        SizedBox(height: 22),
        Shimmer(child: SkeletonLine(width: 130, height: 18)),
        SizedBox(height: 10),
        SkeletonCard(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [_PickupRowSkeleton(), SizedBox(height: 22), _PickupRowSkeleton()],
          ),
        ),
      ],
    );
  }
}

class _MakeCardSkeleton extends StatelessWidget {
  const _MakeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          SkeletonLine(width: 90, height: 14),
          SizedBox(height: 8),
          SkeletonLine(width: 56, height: 11),
          SizedBox(height: 12),
          SkeletonCircle(size: 78),
          SizedBox(height: 16),
          SkeletonLine(width: 80, height: 22),
        ],
      ),
    );
  }
}

class _PickupRowSkeleton extends StatelessWidget {
  const _PickupRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonCircle(size: 44),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(width: 120, height: 14),
              SizedBox(height: 6),
              SkeletonLine(width: 170, height: 11),
            ],
          ),
        ),
        SizedBox(width: 8),
        SkeletonCircle(size: 40),
      ],
    );
  }
}
