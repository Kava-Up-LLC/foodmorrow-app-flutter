// Puts Ana's Kitchen on the phone that runs it: the menu of four items and the orders of
// spec §9, so the app has something real to show.
//
//   flutter test integration_test/seed_demo_data_test.dart -d <device>
//
// It writes through the app's own repositories, so everything goes to AppAmbit the same way the
// app does it. Run it again and it tops the data back up: items it already has are left alone,
// and today's and tomorrow's orders are rebuilt.
import 'dart:io';

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodmorrow_app/app_services.dart';
import 'package:foodmorrow_app/core/appambit/analytics.dart';
import 'package:foodmorrow_app/core/appambit/cloud_service.dart';
import 'package:foodmorrow_app/core/appambit/diagnostics.dart';
import 'package:foodmorrow_app/core/dates.dart';
import 'package:foodmorrow_app/core/local_store.dart';
import 'package:foodmorrow_app/features/menu/data/product.dart';

/// What the seller sells.
const _menu = [
  ('Cookies', 'cookies'),
  ('Chocolate cake', 'chocolate_cake'),
  ('Lasagna', 'lasagna'),
  ('Brownies', 'brownies'),
];

/// Tomorrow adds up to the 52 things of spec §9; today has two pickups, one already done.
const _orders = [
  ('Laura Méndez', {'Cookies': 12, 'Chocolate cake': 1}, 'tomorrow', null, false),
  ('Pedro Ruiz', {'Cookies': 24}, 'tomorrow', null, false),
  ('Sofía Ramos', {'Cookies': 12, 'Chocolate cake': 2, 'Lasagna': 1}, 'tomorrow', 'Birthday, no nuts', false),
  ('Marta Gil', {'Brownies': 6, 'Lasagna': 1}, 'today', null, false),
  ('Jorge Paz', {'Cookies': 12}, 'today', null, true),
  ('Elena Ruiz', {'Chocolate cake': 1, 'Brownies': 12}, 'friday', 'Pick up after 6 pm', false),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('seed the demo data on this phone', (tester) async {
    await dotenv.load();
    final appKey = Platform.isIOS
        ? dotenv.env['APPAMBIT_IOS_APP_KEY']
        : dotenv.env['APPAMBIT_ANDROID_APP_KEY'];
    expect(appKey, isNotNull, reason: '.env must hold the app keys');
    await AppAmbitSdk.start(appKey: appKey!);

    // The app is past its first open once it has a menu.
    (await SharedPreferences.getInstance()).setBool('welcome_done', true);

    final store = await PrefsStore.open();
    final services = AppServices(
      cloud: AppAmbitCloudService(),
      analytics: const AppAmbitAnalytics(),
      diagnostics: const AppAmbitDiagnostics(),
      store: store,
      platform: Platform.isIOS ? 'ios' : 'android',
      appVersion: '1.0.0',
    );
    await services.seller.hello();
    debugPrint('SELLER_ID=${store.sellerId}');

    await services.settings.save(businessName: "Ana's Kitchen", weekStart: 'mon');

    var menu = await services.menu.list();
    for (final item in _menu) {
      if (menu.any((p) => p.name.toLowerCase() == item.$1.toLowerCase())) continue;
      menu = await services.menu.add(name: item.$1, photo: item.$2);
    }
    final byName = {for (final Product p in menu) p.name: p.id};
    debugPrint('MENU ${menu.map((p) => p.name).join(', ')}');

    // Clear the days we are about to fill, so running this twice doesn't double the numbers.
    final today = Dates.today();
    final friday = today.add(const Duration(days: 4));
    final days = await services.orders.week(from: today, to: friday);
    for (final day in days) {
      for (final order in day.orders) {
        await services.orders.delete(order.id);
      }
    }

    for (final order in _orders) {
      final date = switch (order.$3) {
        'today' => today,
        'tomorrow' => Dates.tomorrow(),
        _ => friday,
      };
      final id = await services.orders.save(
        customer: order.$1,
        pickupDate: date,
        note: order.$4,
        quantities: {for (final e in order.$2.entries) byName[e.key]!: e.value},
      );
      if (order.$5) await services.orders.setPickedUp(id: id, pickedUp: true);
    }

    // Say out loud what the app should now be showing.
    final home = await services.home.load();
    debugPrint('HOME ${home.businessName}: ${home.tomorrow.things} things to make tomorrow, '
        '${home.today.done} of ${home.today.total} pickups done today');
    expect(home.tomorrow.things, 52, reason: 'the 52 of spec §9');
    debugPrint('SEEDED — open the app on this phone');
  });
}
