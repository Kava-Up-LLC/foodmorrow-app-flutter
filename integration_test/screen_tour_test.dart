// Walks the app slowly, stopping on each screen, so screenshots can be taken from outside
// (`xcrun simctl io … screenshot` / `adb exec-out screencap`) and held next to design/screens/.
//
//   flutter test integration_test/screen_tour_test.dart -d <device>
//
// Each run installs the app afresh, so the phone forgets its seller: the tour puts the demo data
// of spec §9 on whatever seller it gets, the first time round.
import 'dart:io';

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodmorrow_app/app.dart';
import 'package:foodmorrow_app/app_services.dart';
import 'package:foodmorrow_app/core/appambit/analytics.dart';
import 'package:foodmorrow_app/core/appambit/cloud_service.dart';
import 'package:foodmorrow_app/core/appambit/diagnostics.dart';
import 'package:foodmorrow_app/core/dates.dart';
import 'package:foodmorrow_app/core/local_store.dart';
import 'package:foodmorrow_app/core/widgets/floating_tab_bar.dart';
import 'package:foodmorrow_app/features/menu/data/product.dart';

/// How long each screen stays on show.
const _hold = Duration(seconds: 5);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every screen, slowly', (tester) async {
    await dotenv.load();
    final appKey = Platform.isIOS
        ? dotenv.env['APPAMBIT_IOS_APP_KEY']
        : dotenv.env['APPAMBIT_ANDROID_APP_KEY'];
    await AppAmbitSdk.start(appKey: appKey!);

    // Straight to Home: Welcome is HU-01's business, not the tour's.
    (await SharedPreferences.getInstance()).setBool('welcome_done', true);
    final store = await PrefsStore.open();
    debugPrint('SELLER_ID=${store.sellerId}');
    final services = AppServices(
      cloud: AppAmbitCloudService(),
      analytics: const AppAmbitAnalytics(),
      diagnostics: const AppAmbitDiagnostics(),
      store: store,
      platform: Platform.isIOS ? 'ios' : 'android',
      appVersion: '1.0.0',
    );
    await services.seller.hello();
    await seedIfEmpty(services);

    await tester.pumpWidget(App(services: services));
    await hold(tester, 'HOME');

    await tapAndHold(tester, find.text('See full list'), 'TOMORROW LIST');
    await tester.tapAt(const Offset(200, 60));
    await hold(tester, 'HOME again');

    await tapAndHold(tester, find.bySemanticsLabel('Orders'), 'ORDERS');
    await tapAndHold(
      tester,
      find.bySemanticsLabel(RegExp('^${Dates.long(Dates.tomorrow())}')),
      'ORDERS tomorrow',
    );
    await tapAndHold(tester, find.text('Sofía Ramos'), 'ORDER DETAILS');
    await tapAndHold(tester, find.bySemanticsLabel('Back'), 'ORDERS again');

    await tapAndHold(tester, find.byKey(newOrderButtonKey), 'NEW ORDER');
    await tapAndHold(tester, find.bySemanticsLabel('Back'), 'back');

    await tapAndHold(tester, find.bySemanticsLabel('Menu'), 'MENU');
    await tapAndHold(tester, find.text('Cookies'), 'EDIT ITEM');
    await tapAndHold(tester, find.bySemanticsLabel('Back'), 'back');

    await tapAndHold(tester, find.bySemanticsLabel('Settings'), 'SETTINGS');
    debugPrint('TOUR DONE');
  });
}

/// The orders of spec §9 plus today's two pickups, so every screen has something to show.
Future<void> seedIfEmpty(AppServices services) async {
  if ((await services.menu.list()).isNotEmpty) return;
  await services.settings.save(businessName: "Ana's Kitchen", weekStart: 'mon');
  var menu = const <Product>[];
  for (final item in const [
    ('Cookies', 'cookies'),
    ('Chocolate cake', 'chocolate_cake'),
    ('Lasagna', 'lasagna'),
    ('Brownies', 'brownies'),
  ]) {
    menu = await services.menu.add(name: item.$1, photo: item.$2);
  }
  final byName = {for (final p in menu) p.name: p.id};
  final today = Dates.today();
  final tomorrow = Dates.tomorrow();
  for (final order in [
    ('Laura Méndez', {'Cookies': 12, 'Chocolate cake': 1}, tomorrow, null),
    ('Pedro Ruiz', {'Cookies': 24}, tomorrow, null),
    (
      'Sofía Ramos',
      {'Cookies': 12, 'Chocolate cake': 2, 'Lasagna': 1},
      tomorrow,
      'Birthday, no nuts',
    ),
    ('Marta Gil', {'Brownies': 6, 'Lasagna': 1}, today, null),
    ('Jorge Paz', {'Cookies': 12}, today, null),
  ]) {
    final id = await services.orders.save(
      customer: order.$1,
      pickupDate: order.$3,
      note: order.$4,
      quantities: {for (final e in order.$2.entries) byName[e.key]!: e.value},
    );
    if (order.$1 == 'Jorge Paz') {
      await services.orders.setPickedUp(id: id, pickedUp: true);
    }
  }
  debugPrint('SEEDED the demo data');
}

Future<void> hold(WidgetTester tester, String what) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  debugPrint('SCREEN $what');
  final end = DateTime.now().add(_hold);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapAndHold(WidgetTester tester, Finder finder, String what) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 150));
    if (finder.evaluate().isNotEmpty) break;
  }
  if (finder.evaluate().isEmpty) {
    debugPrint('SKIPPED $what — not on screen');
    return;
  }
  await tester.tap(finder.first);
  await hold(tester, what);
}
