import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodmorrow_app/app.dart';
import 'package:foodmorrow_app/app_services.dart';
import 'package:foodmorrow_app/core/dates.dart';
import 'package:foodmorrow_app/core/errors.dart';
import 'package:foodmorrow_app/core/widgets/floating_tab_bar.dart';
import 'package:foodmorrow_app/features/home/data/home_data.dart';
import 'package:foodmorrow_app/features/menu/data/product.dart';
import 'package:foodmorrow_app/features/orders/data/order.dart';

import 'fakes.dart';

void main() {
  /// The three orders of spec §9, the way Home gets them back.
  HomeData fiftyTwoThings({List<Pickup> pickups = const []}) => homeData(
        tomorrowItems: const [
          MakeItem(name: 'Cookies', photo: 'cookies', qty: 48, orders: 3),
          MakeItem(name: 'Chocolate cake', photo: 'chocolate_cake', qty: 3, orders: 2),
          MakeItem(name: 'Lasagna', photo: 'lasagna', qty: 1, orders: 1),
        ],
        pickups: pickups,
      );

  /// Draws the app at phone width and tall enough that a screen's content is all on show, so the
  /// tests are about what the screen says, not about scrolling.
  Future<void> pumpApp(WidgetTester tester, AppServices services) async {
    tester.view.physicalSize = const Size(390 * 3, 1700 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(App(services: services));
    await tester.pumpAndSettle();
  }

  group('Home', () {
    testWidgets('answers what to make tomorrow (HU-07 CA1)', (tester) async {
      final services = fakeServices(home: FakeHomeRepository(fiftyTwoThings()));
      await pumpApp(tester, services);

      expect(find.text("Ana's Kitchen"), findsOneWidget);
      expect(find.text('52 things\nto make'), findsOneWidget);
      expect(find.text('For tomorrow'), findsOneWidget);
      expect(find.text('Cookies'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      expect(find.text('3 orders'), findsOneWidget);
      expect(find.text('Nobody is picking up today.'), findsOneWidget);
    });

    testWidgets('"See full list" opens the sheet with every item (HU-07 CA2)', (tester) async {
      final analytics = FakeAnalytics();
      await pumpApp(
        tester,
        fakeServices(home: FakeHomeRepository(fiftyTwoThings()), analytics: analytics),
      );

      await tester.tap(find.text('See full list'));
      await tester.pumpAndSettle();

      expect(find.text('52 things to make'), findsOneWidget);
      expect(find.text('×48'), findsOneWidget);
      expect(find.text('×3'), findsOneWidget);
      expect(find.text('×1'), findsOneWidget);
      expect(analytics.names, contains('tomorrow_list_viewed'));
    });

    testWidgets('an empty tomorrow offers New order (HU-07 CA4)', (tester) async {
      await pumpApp(tester, fakeServices(home: FakeHomeRepository(homeData())));

      expect(find.text('No orders for tomorrow yet'), findsOneWidget);
      expect(find.text('New order'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('a pickup can be ticked off from Home (HU-06 CA1)', (tester) async {
      final home = FakeHomeRepository(fiftyTwoThings(pickups: const [
        Pickup(
          id: 'o-marta',
          customer: 'Marta Gil',
          pickedUp: false,
          items: [PickupLine(name: 'Brownies', photo: 'brownies', qty: 6)],
        ),
        Pickup(
          id: 'o-jorge',
          customer: 'Jorge Paz',
          pickedUp: true,
          items: [PickupLine(name: 'Cookies', photo: 'cookies', qty: 12)],
        ),
      ]));
      final orders = FakeOrdersRepository();
      await pumpApp(tester, fakeServices(home: home, orders: orders));

      expect(find.text('1 of 2 done'), findsOneWidget);
      expect(find.text('6 Brownies'), findsOneWidget);

      // Marta's check is the one that is not yet filled.
      await tester.tap(find.bySemanticsLabel('Mark Marta Gil as picked up'));
      await tester.pumpAndSettle();

      expect(orders.pickedUp, [('o-marta', true)]);
    });

    testWidgets('no connection shows the banner over skeletons (HU-09 CA1)', (tester) async {
      final home = FakeHomeRepository(fiftyTwoThings())
        ..failWith = const AppFailure(FailureKind.noConnection);
      await pumpApp(tester, fakeServices(home: home));

      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Your orders are saved.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('52 things\nto make'), findsNothing);

      // Back online, Retry loads it (HU-09 CA2).
      home.failWith = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('No connection'), findsNothing);
      expect(find.text('52 things\nto make'), findsOneWidget);
    });
  });

  group('Orders', () {
    testWidgets('shows the day strip and the orders of the day (HU-05 CA2)', (tester) async {
      final tomorrow = Dates.tomorrow();
      final orders = FakeOrdersRepository(days: [
        DayOrders(date: tomorrow, orders: [
          fakeOrder(
            id: 'a',
            customer: 'Laura Méndez',
            items: const [
              OrderLine(productId: 'p1', name: 'Cookies', photo: 'cookies', qty: 12),
              OrderLine(productId: 'p2', name: 'Chocolate cake', photo: 'chocolate_cake', qty: 1),
            ],
          ),
        ]),
      ]);
      await pumpApp(tester, fakeServices(orders: orders));

      await tester.tap(find.bySemanticsLabel('Orders'));
      await tester.pumpAndSettle();

      expect(find.text('No orders for this day.'), findsOneWidget, reason: 'today is empty');

      await tester.tap(find.bySemanticsLabel(RegExp('^${Dates.long(tomorrow)}')));
      await tester.pumpAndSettle();

      expect(find.text('${Dates.weekday(tomorrow)} · Tomorrow'), findsOneWidget);
      expect(find.text('1 order'), findsOneWidget);
      expect(find.text('Laura Méndez'), findsOneWidget);
      expect(find.text('13 items'), findsOneWidget);
      expect(find.text('To make'), findsOneWidget);
      expect(find.text('12 Cookies'), findsOneWidget);
    });

    testWidgets('an order opens, and can be marked picked up (HU-06 CA3)', (tester) async {
      final order = fakeOrder(customer: 'Sofía Ramos', note: 'Birthday, no nuts');
      final orders = FakeOrdersRepository(
        days: [DayOrders(date: Dates.today(), orders: [order])],
        order: order,
      );
      await pumpApp(tester, fakeServices(orders: orders));

      await tester.tap(find.bySemanticsLabel('Orders'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sofía Ramos'));
      await tester.pumpAndSettle();

      expect(find.text('Order details'), findsOneWidget);
      expect(find.text('Pickup'), findsOneWidget);
      expect(find.text('Birthday, no nuts'), findsOneWidget);
      expect(find.text('Order saved'), findsOneWidget);
      expect(find.text('On the list to make'), findsOneWidget);
      expect(find.text('×12'), findsOneWidget);

      orders.order = fakeOrder(customer: 'Sofía Ramos', pickedUp: true);
      await tester.tap(find.text('Mark as picked up'));
      await tester.pumpAndSettle();

      expect(orders.pickedUp, [('o1', true)]);
      expect(find.text('Undo picked up'), findsOneWidget);
    });

    testWidgets('deleting asks first, by name (HU-04 CA3)', (tester) async {
      final order = fakeOrder(customer: 'Sofía Ramos');
      final orders = FakeOrdersRepository(
        days: [DayOrders(date: Dates.today(), orders: [order])],
        order: order,
      );
      await pumpApp(tester, fakeServices(orders: orders));

      await tester.tap(find.bySemanticsLabel('Orders'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sofía Ramos'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Delete order'));
      await tester.pumpAndSettle();

      expect(find.text("Delete Sofía Ramos's order?"), findsOneWidget);

      // Cancelling keeps it.
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(orders.deleted, isEmpty);

      await tester.tap(find.bySemanticsLabel('Delete order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(orders.deleted, ['o1']);
    });

    testWidgets('long-pressing the Orders title is the test crash (spec §10)', (tester) async {
      final diagnostics = FakeDiagnostics();
      await pumpApp(tester, fakeServices(diagnostics: diagnostics));

      await tester.tap(find.bySemanticsLabel('Orders'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Orders').first);
      await tester.pumpAndSettle();

      expect(diagnostics.crashes, 1);
    });
  });

  group('New order', () {
    final menu = [
      const Product(id: 'p1', name: 'Cookies', photo: 'cookies', orders: 0),
      const Product(id: 'p2', name: 'Chocolate cake', photo: 'chocolate_cake', orders: 0),
    ];

    testWidgets('opens on Tomorrow and saves what was tapped (HU-03 CA1, CA2, CA5)', (tester) async {
      final orders = FakeOrdersRepository();
      final analytics = FakeAnalytics();
      await pumpApp(
        tester,
        fakeServices(menu: FakeMenuRepository(List.of(menu)), orders: orders, analytics: analytics),
      );

      await tester.tap(find.byKey(newOrderButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('New order'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('What they want'), findsOneWidget);
      expect(find.text('0 items'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Laura');
      await tester.pumpAndSettle();

      // 12 cookies and 1 cake.
      final plus = find.bySemanticsLabel('One more');
      for (var i = 0; i < 12; i++) {
        await tester.tap(plus.first);
        await tester.pump();
      }
      await tester.tap(plus.at(1));
      await tester.pumpAndSettle();

      expect(find.text('13 items'), findsOneWidget);
      expect(find.text(Dates.buttonDay(Dates.tomorrow())), findsWidgets);

      await tester.tap(find.text('Save order'));
      await tester.pumpAndSettle();

      expect(orders.saved.single['customer'], 'Laura');
      expect(orders.saved.single['quantities'], {'p1': 12, 'p2': 1});
      expect(orders.saved.single['pickup_date'], Dates.tomorrowKey());
      expect(analytics.names, contains('order_saved'));
    });

    testWidgets('Save is off until there is a customer and an item (HU-03 CA3)', (tester) async {
      final orders = FakeOrdersRepository();
      await pumpApp(
        tester,
        fakeServices(menu: FakeMenuRepository(List.of(menu)), orders: orders),
      );

      await tester.tap(find.byKey(newOrderButtonKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save order'));
      await tester.pumpAndSettle();
      expect(orders.saved, isEmpty, reason: 'nothing typed yet');

      await tester.enterText(find.byType(TextField).first, 'Laura');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save order'));
      await tester.pumpAndSettle();
      expect(orders.saved, isEmpty, reason: 'still no items');

      await tester.tap(find.bySemanticsLabel('One more').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save order'));
      await tester.pumpAndSettle();
      expect(orders.saved, hasLength(1));
    });

    testWidgets('with no menu it says to add what you sell first (HU-03 CA6)', (tester) async {
      await pumpApp(tester, fakeServices(menu: FakeMenuRepository()));

      await tester.tap(find.byKey(newOrderButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('Add what you sell first'), findsOneWidget);
      expect(find.text('New item'), findsOneWidget);
      expect(find.text('Save order'), findsNothing);
    });
  });

  group('Menu', () {
    testWidgets('shows the grid and how many orders each item is in (HU-02 CA8)', (tester) async {
      await pumpApp(
        tester,
        fakeServices(
          menu: FakeMenuRepository([
            const Product(id: 'p1', name: 'Cookies', photo: 'cookies', orders: 3),
            const Product(id: 'p2', name: 'Tamales', photo: null, orders: 0),
          ]),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Your menu'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('In 3 orders'), findsOneWidget);
      expect(find.text('Add a photo'), findsOneWidget, reason: 'Tamales has no photo');
    });

    testWidgets('a new item is added with its photo (HU-02 CA1)', (tester) async {
      final menu = FakeMenuRepository();
      await pumpApp(tester, fakeServices(menu: menu));

      await tester.tap(find.bySemanticsLabel('Menu'));
      await tester.pumpAndSettle();
      // The empty menu card offers it; the green + in the corner does the same thing.
      await tester.tap(find.text('New item'));
      await tester.pumpAndSettle();

      expect(find.text('New item'), findsOneWidget);
      expect(find.text('Add to menu'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Cookies');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to menu'));
      await tester.pumpAndSettle();

      expect(menu.added, [('Cookies', null)]);
      expect(find.text('Your menu'), findsOneWidget, reason: 'back on the menu');
    });

    testWidgets('a duplicate name is refused with a message (HU-02 CA2)', (tester) async {
      final menu = FakeMenuRepository()..failWith = const AppFailure(FailureKind.duplicate);
      await pumpApp(tester, fakeServices(menu: menu));

      await tester.tap(find.bySemanticsLabel('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New item'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'cookies');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to menu'));
      await tester.pumpAndSettle();

      expect(find.text('Already on your menu'), findsOneWidget);
      expect(find.text('New item'), findsOneWidget, reason: 'it stays on the form');
    });

    testWidgets('removing an item asks first (HU-02 CA7)', (tester) async {
      final menu = FakeMenuRepository([
        const Product(id: 'p1', name: 'Lasagna', photo: 'lasagna', orders: 1),
      ]);
      await pumpApp(tester, fakeServices(menu: menu));

      await tester.tap(find.bySemanticsLabel('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lasagna'));
      await tester.pumpAndSettle();

      expect(find.text('Edit item'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      await tester.tap(find.text('Remove from menu'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Lasagna?'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(menu.removed, ['p1']);
    });
  });

  group('Settings', () {
    testWidgets('shows the business, the week start and the version', (tester) async {
      await pumpApp(tester, fakeServices());

      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(find.text("Ana's Kitchen"), findsOneWidget);
      expect(find.text('Shown at the top of Home'), findsOneWidget);
      expect(find.text('Week starts on'), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Time zone'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('the week can be switched to Sunday (HU-08 CA2)', (tester) async {
      final settings = FakeSettingsRepository();
      await pumpApp(tester, fakeServices(settings: settings));

      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week starts on'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sunday').last);
      await tester.pumpAndSettle();

      expect(settings.weekStart, 'sun');
      expect(find.text('Sunday'), findsOneWidget);
    });

    testWidgets('Help opens three tips (HU-08 CA3)', (tester) async {
      await pumpApp(tester, fakeServices());

      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help'));
      await tester.pumpAndSettle();

      expect(find.text('Set up your menu once'), findsOneWidget);
      expect(find.text('Write orders down as they arrive'), findsOneWidget);
      expect(find.text('Open Home in the morning'), findsOneWidget);
    });
  });

  group('First open', () {
    testWidgets('Welcome leads to New item and then to Home (HU-01)', (tester) async {
      final store = FakeStore(welcomeDone: false);
      final menu = FakeMenuRepository();
      final analytics = FakeAnalytics();
      await pumpApp(tester, fakeServices(store: store, menu: menu, analytics: analytics));

      expect(find.text('Know today what\nyou cook tomorrow'), findsOneWidget);
      expect(find.text('Add what you sell'), findsOneWidget);

      await tester.tap(find.text('Add what you sell'));
      await tester.pumpAndSettle();
      expect(find.text('New item'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Cookies');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to menu'));
      await tester.pumpAndSettle();

      expect(store.welcomeDone, isTrue);
      expect(analytics.names, contains('welcome_done'));
      expect(find.text('Know today what\nyou cook tomorrow'), findsNothing);
      // It landed on Home.
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
    });

    testWidgets('Welcome never shows again once it is done', (tester) async {
      await pumpApp(tester, fakeServices(store: FakeStore()));
      expect(find.text('Add what you sell'), findsNothing);
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
    });
  });
}
