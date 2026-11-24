import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../app_services.dart';
import '../../../core/dates.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../data/order.dart';
import '../orders_controller.dart';
import '../widgets/day_strip.dart';
import '../widgets/order_card.dart';
import 'order_detail_view.dart';
import 'search_view.dart';

/// Orders by day: the week strip and the orders of the selected day (screen 05).
class OrdersView extends StatefulWidget {
  const OrdersView({
    super.key,
    required this.services,
    required this.shell,
    this.initialDay,
    this.onDayChanged,
  });

  final AppServices services;
  final HomeShellState shell;

  /// Set when Home's "See all" sends you here on tomorrow.
  final DateTime? initialDay;

  /// Tells the shell which day is selected, so it comes back on that day.
  final ValueChanged<DateTime>? onDayChanged;

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  late final OrdersController _controller = OrdersController(
    repository: widget.services.orders,
    weekStart: widget.services.weekStart,
    initialDay: widget.initialDay,
  )..load();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_reportDay);
  }

  @override
  void dispose() {
    _controller.removeListener(_reportDay);
    _controller.dispose();
    super.dispose();
  }

  void _reportDay() => widget.onDayChanged?.call(_controller.selectedDay);

  Future<void> _openOrder(Order order) async {
    clearMessages(context);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderDetailView(services: widget.services, orderId: order.id),
      ),
    );
    // The shell rebuilds this tab, which reads the day again: one call, not two.
    if (changed == true) widget.shell.reloadEverything();
  }

  Future<void> _openSearch() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => SearchView(services: widget.services)),
    );
    if (picked == null || !mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderDetailView(services: widget.services, orderId: picked),
      ),
    );
    if (changed == true) widget.shell.reloadEverything();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final orders = _controller.selectedOrders;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Shapes.side,
              24,
              Shapes.side,
              Shapes.bottomInset,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_controller.monthLabel, style: AppText.small),
                        const SizedBox(height: 2),
                        // Long-pressing the title is the test crash of spec §10 (video only).
                        GestureDetector(
                          onLongPress: widget.services.diagnostics.testCrash,
                          child: Text('Orders', style: AppText.title),
                        ),
                      ],
                    ),
                  ),
                  RoundIconButton(
                    icon: Icons.search_rounded,
                    semanticLabel: 'Search orders',
                    onPressed: _openSearch,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DayStrip(
                days: _controller.weekDays,
                selected: _controller.selectedDay,
                ordersOn: _controller.ordersOn,
                onSelect: _controller.selectDay,
                onMoveWeek: _controller.moveWeek,
              ),
              const SizedBox(height: 22),
              if (_controller.failure != null) ...[
                AlertBanner(failure: _controller.failure!, onRetry: _controller.load),
                const SizedBox(height: Shapes.gap),
              ],
              if (_controller.loading) ...[
                const Skeleton(height: 150),
                const SizedBox(height: Shapes.gap),
                const Skeleton(height: 150),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: Text(_controller.selectedTitle, style: AppText.navTitle)),
                    Text(_controller.selectedCountLabel, style: AppText.small),
                  ],
                ),
                const SizedBox(height: 12),
                if (orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'No orders for this day.',
                      style: AppText.bodyRegular.copyWith(color: AppColors.muted),
                    ),
                  )
                else
                  for (final order in orders) ...[
                    OrderCard(order: order, onTap: () => _openOrder(order)),
                    const SizedBox(height: Shapes.gap),
                  ],
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A small helper so Orders can say "Wed, Nov 25" the same way the rest of the app does.
String orderDayLabel(DateTime day) {
  final relative = Dates.relative(day);
  return relative == null ? Dates.short(day) : '${Dates.short(day)} · $relative';
}
