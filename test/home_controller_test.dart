import 'package:flutter_test/flutter_test.dart';
import 'package:foodmorrow_app/core/errors.dart';
import 'package:foodmorrow_app/features/home/data/home_data.dart';
import 'package:foodmorrow_app/features/home/home_controller.dart';

import 'fakes.dart';

void main() {
  // The three orders of spec §9, as Home gets them back.
  final fiftyTwo = [
    const MakeItem(name: 'Cookies', photo: 'cookies', qty: 48, orders: 3),
    const MakeItem(name: 'Chocolate cake', photo: 'chocolate_cake', qty: 3, orders: 2),
    const MakeItem(name: 'Lasagna', photo: 'lasagna', qty: 1, orders: 1),
  ];

  HomeController build({
    FakeHomeRepository? home,
    FakeOrdersRepository? orders,
    FakeAnalytics? analytics,
  }) {
    return HomeController(
      repository: home ?? FakeHomeRepository(homeData(tomorrowItems: fiftyTwo)),
      orders: orders ?? FakeOrdersRepository(),
      analytics: analytics ?? FakeAnalytics(),
    );
  }

  test('loads what to make tomorrow', () async {
    final controller = build();
    expect(controller.loading, isTrue);

    await controller.load();

    expect(controller.loading, isFalse);
    expect(controller.failure, isNull);
    expect(controller.data!.businessName, "Ana's Kitchen");
    expect(controller.data!.tomorrow.things, 52);
    expect(controller.data!.tomorrow.items.first.name, 'Cookies');
    expect(controller.data!.tomorrow.bannerPhoto, 'cookies', reason: 'the biggest one');
  });

  test('an empty tomorrow is empty, not an error', () async {
    final controller = build(home: FakeHomeRepository(homeData()));
    await controller.load();

    expect(controller.failure, isNull);
    expect(controller.data!.tomorrow.isEmpty, isTrue);
    expect(controller.data!.tomorrow.things, 0);
    expect(controller.data!.tomorrow.bannerPhoto, isNull);
    expect(controller.data!.today.doneLabel, 'None');
  });

  test('no connection leaves the banner, and Retry loads again', () async {
    final repository = FakeHomeRepository(homeData(tomorrowItems: fiftyTwo))
      ..failWith = const AppFailure(FailureKind.noConnection);
    final controller = build(home: repository);

    await controller.load();
    expect(controller.failure!.isNoConnection, isTrue);
    expect(controller.failure!.title, 'No connection');
    expect(controller.failure!.message, 'Your orders are saved.');
    expect(controller.data, isNull);

    repository.failWith = null;
    await controller.load();
    expect(controller.failure, isNull);
    expect(controller.data!.tomorrow.things, 52);
  });

  group('ticking a pickup off', () {
    final marta = const Pickup(
      id: 'o-marta',
      customer: 'Marta Gil',
      pickedUp: false,
      items: [PickupLine(name: 'Brownies', photo: 'brownies', qty: 6)],
    );
    final jorge = const Pickup(
      id: 'o-jorge',
      customer: 'Jorge Paz',
      pickedUp: true,
      items: [PickupLine(name: 'Cookies', photo: 'cookies', qty: 12)],
    );

    test('marks it, reloads Home and reports the event', () async {
      final home = FakeHomeRepository(homeData(pickups: [marta, jorge]));
      final orders = FakeOrdersRepository();
      final analytics = FakeAnalytics();
      final controller = build(home: home, orders: orders, analytics: analytics);
      await controller.load();

      expect(controller.data!.today.doneLabel, '1 of 2 done');

      // The answer Home gives once Marta has picked up.
      home.data = homeData(pickups: [
        const Pickup(id: 'o-marta', customer: 'Marta Gil', pickedUp: true, items: []),
        jorge,
      ]);
      await controller.togglePickedUp(marta);

      expect(orders.pickedUp, [('o-marta', true)]);
      expect(controller.data!.today.doneLabel, '2 of 2 done');
      expect(controller.pendingPickup, isNull);
      expect(analytics.names, contains('order_picked_up'));
    });

    test('undoes one that was already picked up', () async {
      final orders = FakeOrdersRepository();
      final controller = build(
        home: FakeHomeRepository(homeData(pickups: [marta, jorge])),
        orders: orders,
      );
      await controller.load();

      await controller.togglePickedUp(jorge);
      expect(orders.pickedUp, [('o-jorge', false)]);
    });

    test('a failure shows the banner and changes nothing', () async {
      final orders = FakeOrdersRepository()..failWith = const AppFailure(FailureKind.noConnection);
      final controller = build(
        home: FakeHomeRepository(homeData(pickups: [marta])),
        orders: orders,
      );
      await controller.load();

      await controller.togglePickedUp(marta);

      expect(controller.failure!.isNoConnection, isTrue);
      expect(controller.data!.today.done, 0);
      expect(controller.pendingPickup, isNull, reason: 'the row must not stay spinning');
    });
  });

  test('"See full list" is reported once', () async {
    final analytics = FakeAnalytics();
    final controller = build(analytics: analytics);
    await controller.load();

    controller.trackTomorrowListViewed();

    expect(analytics.events.single.$1, 'tomorrow_list_viewed');
    expect(analytics.events.single.$2['items'], '3');
  });
}
