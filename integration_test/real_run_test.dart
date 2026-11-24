// The real app, on a real device, against the real AppAmbit backend — no fakes anywhere.
// It walks spec §9 and the user stories end to end.
//
//   flutter test integration_test/real_run_test.dart -d <device>
//
// It writes real rows for a throwaway seller and prints its id as `SELLER_ID=<uuid>` so the data
// can be cleaned up afterwards.
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
import 'package:foodmorrow_app/core/widgets/common.dart';
import 'package:foodmorrow_app/core/widgets/floating_tab_bar.dart';
import 'package:foodmorrow_app/features/menu/views/item_form_view.dart';
import 'package:foodmorrow_app/features/menu/views/menu_view.dart';
import 'package:foodmorrow_app/features/orders/views/order_form_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Foodmorrow end to end on the real backend', (tester) async {
    // A seller nobody else is using, and Welcome already out of the way: this test is about the
    // numbers, and HU-01 is covered by the widget tests.
    SharedPreferences.setMockInitialValues({'welcome_done': true});
    await dotenv.load();
    final appKey = Platform.isIOS
        ? dotenv.env['APPAMBIT_IOS_APP_KEY']
        : dotenv.env['APPAMBIT_ANDROID_APP_KEY'];
    expect(appKey, isNotNull, reason: '.env must hold the app keys');
    expect(appKey, isNotEmpty);
    await AppAmbitSdk.start(appKey: appKey!);

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

    await tester.pumpWidget(App(services: services));
    await settle(tester);

    // ---------------------------------------------------------------- the menu (HU-02)
    await tapWhenReady(tester, find.bySemanticsLabel('Menu'), 'the Menu tab');
    await waitFor(tester, find.text('Your menu'), 'the menu screen');

    for (final item in const [
      ('Cookies', 'cookies'),
      ('Chocolate cake', 'chocolate_cake'),
      ('Lasagna', 'lasagna'),
    ]) {
      await tapWhenReady(tester, find.byKey(menuAddItemKey), 'the + on the menu');
      await waitFor(tester, find.byKey(itemNameFieldKey), 'the new item form');
      await tester.enterText(find.byKey(itemNameFieldKey), item.$1);
      await settle(tester);
      await tapWhenReady(tester, find.byKey(ValueKey('pick_photo_${item.$2}')), 'the ${item.$2} photo');
      await tapWhenReady(tester, find.text('Add to menu'), 'Add to menu');
      // Back on the menu — the + only exists there, and the name alone would also match the
      // text still sitting in the form's field.
      await waitFor(tester, find.byKey(menuAddItemKey), 'the menu after adding ${item.$1}');
    }

    await waitFor(tester, find.text('3 items'), 'the menu count');
    expect(find.text('Cookies'), findsOneWidget);
    debugPrint('CHECK menu: 3 items added');

    // A name that is already on the menu, however it is typed (HU-02 CA2).
    await tapWhenReady(tester, find.byKey(menuAddItemKey), 'the + on the menu');
    await waitFor(tester, find.byKey(itemNameFieldKey), 'the new item form');
    await tester.enterText(find.byKey(itemNameFieldKey), 'cookies');
    await settle(tester);
    await tapWhenReady(tester, find.text('Add to menu'), 'Add to menu');
    await waitFor(tester, find.text('Already on your menu'), 'the duplicate message');
    debugPrint('CHECK duplicate refused by the cloud');
    await tapWhenReady(tester, find.bySemanticsLabel('Back'), 'Back');

    // ---------------------------------------------------------------- three orders (HU-03)
    for (final order in const [
      ('Laura', [12, 1, 0]),
      ('Pedro', [24, 0, 0]),
      ('Sofía', [12, 2, 1]),
    ]) {
      await tapWhenReady(tester, find.byKey(newOrderButtonKey), 'the + in the tab bar');
      await waitFor(tester, find.byKey(customerFieldKey), 'the order form');
      await tester.enterText(find.byKey(customerFieldKey), order.$1);
      await settle(tester);

      // The keyboard is in the way of the lower rows, and the list only lays out what is on
      // screen, so put it away before counting anything out.
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);

      await addQty(tester, 'Cookies', order.$2[0]);
      await addQty(tester, 'Chocolate cake', order.$2[1]);
      await addQty(tester, 'Lasagna', order.$2[2]);
      await settle(tester);
      await tapWhenReady(tester, find.text('Save order'), 'Save order');
      await waitFor(tester, find.byKey(newOrderButtonKey), 'the tab bar, back from the form');
    }
    debugPrint('CHECK 3 orders saved for tomorrow');

    // ---------------------------------------------------------------- Home says 52 (HU-07 CA1)
    await tapWhenReady(tester, find.bySemanticsLabel('Home'), 'the Home tab');
    await waitFor(tester, find.text('52 things\nto make'), '52 things to make');
    expect(find.text('48'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3 orders'), findsOneWidget, reason: 'Cookies are in all three');
    debugPrint('CHECK Home: 52 things to make — 48 Cookies, 3 Chocolate cake, 1 Lasagna');

    // The full list (HU-07 CA2).
    await tapWhenReady(tester, find.text('See full list'), 'See full list');
    await waitFor(tester, find.text('×48'), 'the full list sheet');
    expect(find.text('52 things to make'), findsOneWidget);
    await tester.tapAt(const Offset(200, 60)); // outside the sheet
    await settle(tester);

    // ---------------------------------------------------------------- the orders of a day (HU-05)
    await tapWhenReady(tester, find.bySemanticsLabel('Orders'), 'the Orders tab');
    await tapWhenReady(
        tester, find.bySemanticsLabel(RegExp('^${Dates.long(Dates.tomorrow())}')), "tomorrow's tile");
    await waitFor(tester, find.text('Laura'), "tomorrow's orders");
    expect(find.text('3 orders'), findsOneWidget);
    expect(find.text('Pedro'), findsOneWidget);
    expect(find.text('Sofía'), findsOneWidget);
    expect(find.text('13 items'), findsOneWidget, reason: "Laura's 12 + 1");
    debugPrint('CHECK Orders: 3 orders tomorrow, waiting first');

    // ---------------------------------------------------------------- edit (HU-04 CA2)
    await tapWhenReady(tester, find.text('Sofía'), "Sofía's order");
    await waitFor(tester, find.text('Order details'), 'the order details screen');
    await tapWhenReady(tester, find.text('Edit'), 'Edit');
    await waitFor(tester, find.text('Edit order'), 'the edit form');
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
    // Chocolate cake: 2 → 3.
    await addQty(tester, 'Chocolate cake', 1);
    await settle(tester);
    await tapWhenReady(tester, find.text('Save order'), 'Save order');

    // ---------------------------------------------------------------- picked up (HU-06 CA3)
    await tapWhenReady(tester, find.text('Mark as picked up'), 'Mark as picked up');
    await waitFor(tester, find.text('Undo picked up'), 'the button flipping');
    debugPrint('CHECK Sofía marked as picked up, order edited to 3 cakes');

    await tapWhenReady(tester, find.bySemanticsLabel('Back'), 'Back');

    // The edit reached Home, and a picked-up order still counts (HU-06 CA4, HU-04 CA2).
    await tapWhenReady(tester, find.bySemanticsLabel('Home'), 'the Home tab');
    await waitFor(tester, find.text('53 things\nto make'), '53 things to make');
    debugPrint('CHECK Home followed the edit: 53 things to make');

    // ---------------------------------------------------------------- settings (HU-08)
    await tapWhenReady(tester, find.bySemanticsLabel('Settings'), 'the Settings tab');
    await waitFor(tester, find.text('My kitchen'), 'the business card');
    await tapWhenReady(tester, find.text('Edit'), 'Edit');
    await waitFor(tester, find.byType(TextField), 'the name dialog');
    await tester.enterText(find.byType(TextField).last, "Ana's Kitchen");
    await settle(tester);
    await tapWhenReady(tester, find.text('Save'), 'Save');
    await waitFor(tester, find.text("Ana's Kitchen"), 'the new name in Settings');

    await tapWhenReady(tester, find.bySemanticsLabel('Home'), 'the Home tab');
    await waitFor(tester, find.text("Ana's Kitchen"), 'the name under the date on Home');
    debugPrint('CHECK business name reached Home');

    // ---------------------------------------------------------------- clean up after ourselves
    await tapWhenReady(tester, find.bySemanticsLabel('Orders'), 'the Orders tab');
    await tapWhenReady(
        tester, find.bySemanticsLabel(RegExp('^${Dates.long(Dates.tomorrow())}')), "tomorrow's tile");
    for (final customer in const ['Laura', 'Pedro', 'Sofía']) {
      await tapWhenReady(tester, find.text(customer), "$customer's order");
      await tapWhenReady(tester, find.bySemanticsLabel('Delete order'), 'the delete button');
      await tapWhenReady(tester, find.text('Delete'), 'Delete in the dialog');
    }
    await waitFor(tester, find.text('No orders for this day.'), 'the empty day');
    debugPrint('CHECK test orders deleted');
    debugPrint('ALL REAL CHECKS PASSED');
  });
}

/// Taps `+` on one product's row as many times as asked, scrolling the row into view first.
Future<void> addQty(WidgetTester tester, String product, int times) async {
  if (times == 0) return;
  final stepper = find.byKey(ValueKey('qty_$product'));
  await waitFor(tester, stepper, "the $product row");
  await tester.ensureVisible(stepper);
  await tester.pump(const Duration(milliseconds: 150));
  final plus = find.descendant(of: stepper, matching: find.bySemanticsLabel('One more'));
  for (var i = 0; i < times; i++) {
    await tester.tap(plus);
    await tester.pump();
  }
}

/// Every screen here waits on a real round trip, so the test waits for what it expects to appear
/// instead of guessing how long the cloud will take.
Future<void> waitFor(WidgetTester tester, Finder finder, String what) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 150));
    if (finder.evaluate().isNotEmpty) return;
  }
  final onScreen = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
  fail('waited 18s and never saw: $what\nOn screen instead: $onScreen');
}

Future<void> tapWhenReady(WidgetTester tester, Finder finder, String what) async {
  await waitFor(tester, finder, what);
  // On a real phone the soft keyboard shrinks the screen, so the thing to tap can be below the
  // fold. Bring it into view first; not everything lives in a scrollable, hence the catch.
  try {
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 150));
  } catch (_) {}
  await tester.tap(finder);
  await settle(tester);
}

/// Lets the frames and any in-flight call finish.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 150));
    if (!_isBusy(tester)) break;
  }
  await tester.pump(const Duration(milliseconds: 150));
}

bool _isBusy(WidgetTester tester) =>
    tester.any(find.byType(CircularProgressIndicator)) || tester.any(find.byType(Skeleton));
