import 'package:flutter/material.dart';

import 'app_services.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/common.dart';
import 'core/widgets/floating_tab_bar.dart';
import 'features/home/views/home_view.dart';
import 'features/menu/views/item_form_view.dart';
import 'features/menu/views/menu_view.dart';
import 'features/orders/views/order_form_view.dart';
import 'features/orders/views/orders_view.dart';
import 'features/settings/views/settings_view.dart';
import 'features/welcome/views/welcome_view.dart';

class App extends StatelessWidget {
  const App({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foodmorrow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: services.store.welcomeDone
          ? HomeShell(services: services)
          : WelcomeView(services: services),
    );
  }
}

/// The four tabs under one floating tab bar.
///
/// Only the tab you are looking at is built, so opening the app or saving an order is one call to
/// AppAmbit, not four. The app keeps no cache (spec §7.5), so a tab reads what it needs when it is
/// shown — which is also what keeps the numbers on Home honest.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.services, this.initialTab = AppTab.home});

  final AppServices services;
  final AppTab initialTab;

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  late AppTab _tab = widget.initialTab;

  /// Bumped after any save, edit, delete or picked-up, so the tab on screen reads again.
  int _revision = 0;

  /// The day Orders is on, remembered across tab switches.
  DateTime? _ordersDay;

  @override
  void initState() {
    super.initState();
    // `hello` lands after the first frame, so the week start can change under us; the day strip
    // has to follow it.
    widget.services.seller.addListener(_sellerChanged);
  }

  @override
  void dispose() {
    widget.services.seller.removeListener(_sellerChanged);
    super.dispose();
  }

  void _sellerChanged() {
    if (mounted) setState(() {});
  }

  /// Something changed in the cloud: what is on screen must not show stale numbers.
  void reloadEverything() => setState(() => _revision++);

  void openTab(AppTab tab, {DateTime? onDay}) {
    setState(() {
      _tab = tab;
      if (onDay != null) _ordersDay = onDay;
    });
  }

  Future<void> openNewOrder() async {
    clearMessages(context);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderFormView(services: widget.services)),
    );
    if (saved == true) reloadEverything();
  }

  Future<void> openNewItem() async {
    clearMessages(context);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemFormView(services: widget.services)),
    );
    if (saved == true) reloadEverything();
  }

  Widget _currentTab() {
    final services = widget.services;
    return switch (_tab) {
      AppTab.home => HomeView(key: ValueKey('home-$_revision'), services: services, shell: this),
      AppTab.orders => OrdersView(
          // The week start is part of the key: when `hello` answers "sun", the strip is rebuilt
          // to start on Sunday instead of staying on the default.
          key: ValueKey('orders-$_revision-${services.weekStart}'),
          services: services,
          shell: this,
          initialDay: _ordersDay,
          onDayChanged: (day) => _ordersDay = day,
        ),
      AppTab.menu => MenuView(key: ValueKey('menu-$_revision'), services: services, shell: this),
      AppTab.settings =>
        SettingsView(key: ValueKey('settings-$_revision'), services: services, shell: this),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentTab(),
      extendBody: true,
      bottomNavigationBar: FloatingTabBar(
        current: _tab,
        onSelect: (tab) => openTab(tab),
        onNewOrder: openNewOrder,
      ),
    );
  }
}
