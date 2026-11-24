import 'package:flutter_test/flutter_test.dart';
import 'package:foodmorrow_app/core/dates.dart';
import 'package:foodmorrow_app/core/errors.dart';
import 'package:foodmorrow_app/features/menu/data/product.dart';
import 'package:foodmorrow_app/features/orders/data/order.dart';
import 'package:foodmorrow_app/features/orders/order_detail_controller.dart';
import 'package:foodmorrow_app/features/orders/order_form_controller.dart';
import 'package:foodmorrow_app/features/orders/orders_controller.dart';

import 'fakes.dart';

void main() {
  group('the Orders tab', () {
    OrdersController build({FakeOrdersRepository? orders, String weekStart = 'mon'}) =>
        OrdersController(
          repository: orders ?? FakeOrdersRepository(),
          weekStart: weekStart,
        );

    test('opens on today, in the current week', () async {
      final controller = build();
      await controller.load();

      expect(Dates.key(controller.selectedDay), Dates.todayKey());
      expect(controller.weekDays.length, 7);
      expect(Dates.weekdayShort(controller.weekDays.first), 'Mon');
      expect(controller.weekDays.any((d) => Dates.key(d) == Dates.todayKey()), isTrue);
    });

    test('starts the week on Sunday when Settings says so (HU-08 CA2)', () async {
      final controller = build(weekStart: 'sun');
      await controller.load();
      expect(Dates.weekdayShort(controller.weekDays.first), 'Sun');
    });

    test('lists the orders of the day that is selected, and counts the dots', () async {
      final tomorrow = Dates.tomorrow();
      final orders = FakeOrdersRepository(days: [
        DayOrders(date: tomorrow, orders: [
          fakeOrder(id: 'a', customer: 'Laura'),
          fakeOrder(id: 'b', customer: 'Pedro'),
          fakeOrder(id: 'c', customer: 'Sofía'),
        ]),
      ]);
      final controller = build(orders: orders);
      await controller.load();

      expect(controller.selectedOrders, isEmpty, reason: 'today has none');
      expect(controller.selectedCountLabel, 'No orders');
      expect(controller.ordersOn(tomorrow), 3);

      controller.selectDay(tomorrow);
      expect(controller.selectedOrders.map((o) => o.customer), ['Laura', 'Pedro', 'Sofía']);
      expect(controller.selectedCountLabel, '3 orders');
      expect(controller.selectedTitle, '${Dates.weekday(tomorrow)} · Tomorrow');
    });

    test('says "1 order" for exactly one', () async {
      final controller = build(
        orders: FakeOrdersRepository(days: [
          DayOrders(date: Dates.today(), orders: [fakeOrder()]),
        ]),
      );
      await controller.load();
      expect(controller.selectedCountLabel, '1 order');
      expect(controller.selectedTitle, '${Dates.weekday(Dates.today())} · Today');
    });

    test('moving a week keeps the same weekday selected', () async {
      final controller = build();
      await controller.load();
      final was = controller.selectedDay;

      await controller.moveWeek(1);
      expect(controller.selectedDay.difference(was).inDays, 7);
      expect(Dates.weekday(controller.selectedDay), Dates.weekday(was));

      await controller.moveWeek(-1);
      expect(Dates.key(controller.selectedDay), Dates.key(was));
    });

    test('Home\'s "See all" opens the week of that day', () async {
      final controller = build();
      await controller.load();
      final inThreeWeeks = Dates.today().add(const Duration(days: 21));

      await controller.goToDay(inThreeWeeks);

      expect(Dates.key(controller.selectedDay), Dates.key(inThreeWeeks));
      expect(
        controller.weekDays.any((d) => Dates.key(d) == Dates.key(inThreeWeeks)),
        isTrue,
      );
    });

    test('no connection shows the banner', () async {
      final orders = FakeOrdersRepository()..failWith = const AppFailure(FailureKind.noConnection);
      final controller = build(orders: orders);
      await controller.load();

      expect(controller.failure!.isNoConnection, isTrue);
      expect(controller.selectedOrders, isEmpty);
    });
  });

  group('the order form', () {
    final menu = [
      const Product(id: 'p1', name: 'Cookies', photo: 'cookies', orders: 0),
      const Product(id: 'p2', name: 'Chocolate cake', photo: 'chocolate_cake', orders: 0),
    ];

    OrderFormController build({
      FakeMenuRepository? menuRepo,
      FakeOrdersRepository? orders,
      FakeAnalytics? analytics,
      Order? editing,
    }) {
      return OrderFormController(
        repository: orders ?? FakeOrdersRepository(),
        menu: menuRepo ?? FakeMenuRepository(List.of(menu)),
        analytics: analytics ?? FakeAnalytics(),
        editing: editing,
      );
    }

    test('loads the menu once, and nothing else until Save', () async {
      final orders = FakeOrdersRepository();
      final controller = build(orders: orders);
      await controller.load();

      expect(controller.products.length, 2);
      expect(controller.hasNoMenu, isFalse);
      expect(orders.saved, isEmpty);
      expect(controller.title, 'New order');
    });

    test('an empty menu is called out instead of an empty form (HU-03 CA6)', () async {
      final controller = build(menuRepo: FakeMenuRepository());
      await controller.load();
      expect(controller.hasNoMenu, isTrue);
    });

    test('saves what was typed and reports order_saved', () async {
      final orders = FakeOrdersRepository();
      final analytics = FakeAnalytics();
      final controller = build(orders: orders, analytics: analytics);
      await controller.load();

      controller.setCustomer('Laura');
      controller.setQty('p1', 12);
      controller.setQty('p2', 1);
      expect(controller.draft.itemCount, 13);

      expect(await controller.save(), isTrue);

      expect(orders.saved.single['customer'], 'Laura');
      expect(orders.saved.single['pickup_date'], Dates.tomorrowKey());
      expect(orders.saved.single['quantities'], {'p1': 12, 'p2': 1});
      expect(orders.saved.single['id'], isNull);
      expect(analytics.events.single.$1, 'order_saved');
      expect(analytics.events.single.$2, {'items': '2', 'days_ahead': '1'});
    });

    test('editing sends the id and reports order_edited', () async {
      final orders = FakeOrdersRepository();
      final analytics = FakeAnalytics();
      final controller = build(
        orders: orders,
        analytics: analytics,
        editing: fakeOrder(
          id: 'o-sofia',
          customer: 'Sofía',
          items: const [
            OrderLine(productId: 'p1', name: 'Cookies', photo: 'cookies', qty: 12),
            OrderLine(productId: 'p2', name: 'Chocolate cake', photo: null, qty: 2),
          ],
        ),
      );
      await controller.load();

      expect(controller.title, 'Edit order');
      expect(controller.draft.qtyOf('p2'), 2);

      controller.setQty('p2', 3);
      expect(await controller.save(), isTrue);

      expect(orders.saved.single['id'], 'o-sofia');
      expect(orders.saved.single['quantities'], {'p1': 12, 'p2': 3});
      expect(analytics.events.single.$1, 'order_edited');
    });

    test('a failed save keeps the form filled in (HU-09 CA3)', () async {
      final orders = FakeOrdersRepository()..failWith = const AppFailure(FailureKind.noConnection);
      final controller = build(orders: orders);
      await controller.load();
      controller.setCustomer('Laura');
      controller.setQty('p1', 12);

      expect(await controller.save(), isFalse);

      expect(controller.failure!.isNoConnection, isTrue);
      expect(controller.draft.customer, 'Laura');
      expect(controller.draft.qtyOf('p1'), 12);
      expect(controller.draft.isValid, isTrue, reason: 'it can be saved again');
    });
  });

  group('order details', () {
    OrderDetailController build({FakeOrdersRepository? orders, FakeAnalytics? analytics}) =>
        OrderDetailController(
          repository: orders ?? FakeOrdersRepository(order: fakeOrder()),
          analytics: analytics ?? FakeAnalytics(),
          orderId: 'o1',
        );

    test('loads the order and offers to mark it', () async {
      final controller = build();
      await controller.load();

      expect(controller.order!.customer, 'Laura Méndez');
      expect(controller.actionLabel, 'Mark as picked up');
      expect(controller.changed, isFalse);
    });

    test('marking it flips the button and tells the screen behind to reload', () async {
      final orders = FakeOrdersRepository(order: fakeOrder());
      final controller = build(orders: orders);
      await controller.load();

      orders.order = fakeOrder(pickedUp: true);
      await controller.togglePickedUp();

      expect(orders.pickedUp, [('o1', true)]);
      expect(controller.actionLabel, 'Undo picked up');
      expect(controller.changed, isTrue);
    });

    test('deleting reports it and tells the screen behind to reload', () async {
      final orders = FakeOrdersRepository(order: fakeOrder());
      final analytics = FakeAnalytics();
      final controller = build(orders: orders, analytics: analytics);
      await controller.load();

      expect(await controller.delete(), isTrue);

      expect(orders.deleted, ['o1']);
      expect(controller.changed, isTrue);
      expect(analytics.names, ['order_deleted']);
    });

    test('a failed delete changes nothing', () async {
      final orders = FakeOrdersRepository(order: fakeOrder())
        ..failWith = const AppFailure(FailureKind.noConnection);
      final controller = build(orders: orders);
      await controller.load();

      expect(await controller.delete(), isFalse);
      expect(orders.deleted, isEmpty);
      expect(controller.changed, isFalse);
      expect(controller.failure!.isNoConnection, isTrue);
    });

    test('an order that is not there any more says so', () async {
      final controller = OrderDetailController(
        repository: FakeOrdersRepository(),
        analytics: FakeAnalytics(),
        orderId: 'gone',
      );
      await controller.load();

      expect(controller.order, isNull);
      expect(controller.failure!.kind, FailureKind.notFound);
    });
  });
}
