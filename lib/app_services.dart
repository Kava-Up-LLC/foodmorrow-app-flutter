import 'core/appambit/analytics.dart';
import 'core/appambit/cloud_service.dart';
import 'core/appambit/diagnostics.dart';
import 'core/local_store.dart';
import 'features/home/home_repository.dart';
import 'features/menu/menu_repository.dart';
import 'features/orders/data/orders_repository.dart';
import 'features/settings/seller_state.dart';
import 'features/settings/settings_repository.dart';

/// Everything the screens need, built once in main.dart and handed down by constructor.
/// Tests build it with fakes.
class AppServices {
  AppServices({
    required this.cloud,
    required this.analytics,
    required this.diagnostics,
    required this.store,
    required this.platform,
    required this.appVersion,
    HomeRepository? home,
    MenuRepository? menu,
    OrdersRepository? orders,
    SettingsRepository? settings,
  })  : home = home ?? CloudHomeRepository(cloud: cloud, sellerId: store.sellerId),
        menu = menu ?? CloudMenuRepository(cloud: cloud, sellerId: store.sellerId),
        orders = orders ?? CloudOrdersRepository(cloud: cloud, sellerId: store.sellerId),
        settings = settings ??
            CloudSettingsRepository(cloud: cloud, sellerId: store.sellerId, platform: platform) {
    seller = SellerState(repository: this.settings);
  }

  final CloudService cloud;
  final Analytics analytics;
  final Diagnostics diagnostics;
  final LocalStore store;

  /// 'ios' or 'android'.
  final String platform;

  /// Shown in Settings.
  final String appVersion;

  final HomeRepository home;
  final MenuRepository menu;
  final OrdersRepository orders;
  final SettingsRepository settings;

  /// The business name and week start, shared by Home, Orders and Settings.
  late final SellerState seller;

  /// Shorthand for the screens that only need the day the week starts on.
  String get weekStart => seller.weekStart;
}
