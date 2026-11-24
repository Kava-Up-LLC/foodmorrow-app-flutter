import 'package:flutter_test/flutter_test.dart';
import 'package:foodmorrow_app/core/errors.dart';
import 'package:foodmorrow_app/features/menu/data/product.dart';
import 'package:foodmorrow_app/features/menu/item_form_controller.dart';
import 'package:foodmorrow_app/features/menu/menu_controller.dart';
import 'package:foodmorrow_app/features/settings/seller_state.dart';
import 'package:foodmorrow_app/features/settings/settings_controller.dart';

import 'fakes.dart';

void main() {
  group('the menu', () {
    test('counts what is on it', () async {
      final controller = MenuListController(
        repository: FakeMenuRepository([
          const Product(id: 'p1', name: 'Cookies', photo: 'cookies', orders: 3),
          const Product(id: 'p2', name: 'Lasagna', photo: 'lasagna', orders: 1),
        ]),
      );
      await controller.load();

      expect(controller.products.length, 2);
      expect(controller.countLabel, '2 items');
      expect(controller.products.first.ordersLabel, 'In 3 orders');
      expect(controller.products.last.ordersLabel, 'In 1 order');
    });

    test('says "1 item" for exactly one, and nothing is not an error', () async {
      final one = MenuListController(
        repository: FakeMenuRepository([
          const Product(id: 'p1', name: 'Cookies', photo: null, orders: 0),
        ]),
      );
      await one.load();
      expect(one.countLabel, '1 item');

      final none = MenuListController(repository: FakeMenuRepository());
      await none.load();
      expect(none.countLabel, '0 items');
      expect(none.failure, isNull);
    });

    test('no connection shows the banner', () async {
      final repository = FakeMenuRepository()..failWith = const AppFailure(FailureKind.noConnection);
      final controller = MenuListController(repository: repository);
      await controller.load();
      expect(controller.failure!.isNoConnection, isTrue);
    });
  });

  group('a menu item', () {
    ItemFormController build({Product? editing, FakeMenuRepository? repo, FakeAnalytics? analytics}) =>
        ItemFormController(
          repository: repo ?? FakeMenuRepository(),
          analytics: analytics ?? FakeAnalytics(),
          editing: editing,
        );

    test('cannot be added without a name', () {
      final controller = build();
      expect(controller.isValid, isFalse);
      expect(controller.buttonLabel, 'Add to menu');
      expect(controller.title, 'New item');

      controller.setName('   ');
      expect(controller.isValid, isFalse);

      controller.setName('Cookies');
      expect(controller.isValid, isTrue);

      controller.setName('x' * 41);
      expect(controller.isValid, isFalse, reason: 'over 40 characters');
    });

    test('is added with its photo and reports product_added', () async {
      final repo = FakeMenuRepository();
      final analytics = FakeAnalytics();
      final controller = build(repo: repo, analytics: analytics);
      controller.setName('  Cookies  ');
      controller.setPhoto('cookies');

      expect(await controller.save(), isTrue);

      expect(repo.added, [('Cookies', 'cookies')]);
      expect(analytics.events.single.$1, 'product_added');
      expect(analytics.events.single.$2, {'has_photo': 'true'});
    });

    test('can be added with no photo at all', () async {
      final repo = FakeMenuRepository();
      final analytics = FakeAnalytics();
      final controller = build(repo: repo, analytics: analytics);
      controller.setName('Tamales');

      expect(await controller.save(), isTrue);

      expect(repo.added, [('Tamales', null)]);
      expect(analytics.events.single.$2, {'has_photo': 'false'});
    });

    test('tapping the chosen photo again removes it; the sheet always sets one', () {
      final controller = build();
      controller.setPhoto('cookies');
      expect(controller.photo, 'cookies');

      controller.setPhoto('cookies');
      expect(controller.photo, isNull, reason: 'the same circle again means no photo');

      controller.choosePhoto('lasagna');
      expect(controller.photo, 'lasagna');
      controller.choosePhoto('lasagna');
      expect(controller.photo, 'lasagna', reason: 'picking from the sheet never unsets it');
    });

    test('editing starts filled in and saves with the id', () async {
      final repo = FakeMenuRepository([
        const Product(id: 'p1', name: 'Cookies', photo: 'cookies', orders: 2),
      ]);
      final analytics = FakeAnalytics();
      final controller = build(editing: repo.products.first, repo: repo, analytics: analytics);

      expect(controller.isEditing, isTrue);
      expect(controller.title, 'Edit item');
      expect(controller.buttonLabel, 'Save');
      expect(controller.name, 'Cookies');
      expect(controller.photo, 'cookies');

      controller.setName('Choc chip cookies');
      expect(await controller.save(), isTrue);

      expect(repo.edited, [('p1', 'Choc chip cookies', 'cookies')]);
      expect(analytics.names, isEmpty, reason: 'product_added is only for a new item');
    });

    test('a duplicate name comes back as a duplicate, and nothing is added', () async {
      final repo = FakeMenuRepository()..failWith = const AppFailure(FailureKind.duplicate);
      final controller = build(repo: repo);
      controller.setName('cookies');

      expect(await controller.save(), isFalse);
      expect(controller.failure!.kind, FailureKind.duplicate);
      expect(controller.failure!.title, 'Already on your menu');
    });

    test('removing it goes through', () async {
      final repo = FakeMenuRepository([
        const Product(id: 'p1', name: 'Lasagna', photo: 'lasagna', orders: 0),
      ]);
      final controller = build(editing: repo.products.first, repo: repo);

      expect(await controller.remove(), isTrue);
      expect(repo.removed, ['p1']);
    });
  });

  group('settings', () {
    SettingsController build(FakeSettingsRepository repo) =>
        SettingsController(repository: repo, seller: SellerState(repository: repo));

    test('reads the business name and the week start', () async {
      final controller = build(FakeSettingsRepository());
      await controller.load();

      expect(controller.businessName, "Ana's Kitchen");
      expect(controller.weekStart, 'mon');
      expect(controller.startsOnSunday, isFalse);
    });

    test('saves a new business name', () async {
      final repo = FakeSettingsRepository();
      final controller = build(repo);
      await controller.load();

      expect(await controller.saveBusinessName('  Panadería Ana  '), isTrue);
      expect(controller.businessName, 'Panadería Ana');
      expect(repo.businessName, 'Panadería Ana');
    });

    test('refuses an empty or too long name without calling the cloud', () async {
      final repo = FakeSettingsRepository();
      final controller = build(repo);
      await controller.load();

      expect(await controller.saveBusinessName('   '), isFalse);
      expect(await controller.saveBusinessName('x' * 41), isFalse);
      expect(repo.businessName, "Ana's Kitchen");
    });

    test('switches the week to Sunday', () async {
      final repo = FakeSettingsRepository();
      final controller = build(repo);
      await controller.load();

      expect(await controller.saveWeekStart('sun'), isTrue);
      expect(controller.startsOnSunday, isTrue);
      expect(repo.weekStart, 'sun');
    });

    test('no connection shows the banner and keeps the old values', () async {
      final repo = FakeSettingsRepository()..failWith = const AppFailure(FailureKind.noConnection);
      final controller = build(repo);
      await controller.load();

      expect(controller.failure!.isNoConnection, isTrue);
      expect(controller.businessName, 'My kitchen', reason: 'the default, never a blank screen');
    });
  });

  group('the seller on app start', () {
    test('hello fills in the name and week start', () async {
      final seller = SellerState(repository: FakeSettingsRepository(weekStart: 'sun'));
      expect(seller.loaded, isFalse);

      await seller.hello();

      expect(seller.loaded, isTrue);
      expect(seller.businessName, "Ana's Kitchen");
      expect(seller.startsOnSunday, isTrue);
    });

    test('hello never throws, so the app opens with no connection', () async {
      final repo = FakeSettingsRepository()..failWith = const AppFailure(FailureKind.noConnection);
      final seller = SellerState(repository: repo);

      await seller.hello();

      expect(seller.loaded, isFalse);
      expect(seller.businessName, 'My kitchen');
      expect(seller.weekStart, 'mon');
    });
  });
}
