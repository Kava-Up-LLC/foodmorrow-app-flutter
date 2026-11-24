import 'package:flutter_test/flutter_test.dart';
import 'package:foodmorrow_app/core/dates.dart';
import 'package:foodmorrow_app/features/orders/order_draft.dart';

void main() {
  group('a new order', () {
    test('starts on Tomorrow with nothing in it', () {
      final draft = OrderDraft();
      expect(draft.choice, PickupChoice.tomorrow);
      expect(Dates.key(draft.pickupDate), Dates.tomorrowKey());
      expect(draft.itemCount, 0);
      expect(draft.isValid, isFalse);
      expect(draft.isEditing, isFalse);
    });

    test('needs a customer and at least one item', () {
      final draft = OrderDraft();
      draft.customer = 'Laura';
      expect(draft.isValid, isFalse, reason: 'no items yet');

      draft.setQty('cookies', 12);
      expect(draft.isValid, isTrue);

      draft.customer = '   ';
      expect(draft.isValid, isFalse, reason: 'spaces are not a name');

      draft.customer = 'x' * 41;
      expect(draft.isValid, isFalse, reason: 'over 40 characters');

      draft.customer = 'x' * 40;
      expect(draft.isValid, isTrue);
    });

    test('counts everything asked for, not the number of products', () {
      final draft = OrderDraft(customer: 'Sofía');
      draft.setQty('cookies', 12);
      draft.setQty('cake', 2);
      draft.setQty('lasagna', 1);
      expect(draft.itemCount, 15);
      expect(draft.lineCount, 3);
      expect(draft.itemCountLabel, '15 items');

      draft.setQty('cookies', 0);
      expect(draft.itemCount, 3);
      expect(draft.lineCount, 2);
      expect(draft.quantities.containsKey('cookies'), isFalse, reason: 'zero is not saved');
    });

    test('says "1 item" for exactly one', () {
      final draft = OrderDraft()..setQty('cookies', 1);
      expect(draft.itemCountLabel, '1 item');
    });

    test('keeps quantities between 0 and 999', () {
      final draft = OrderDraft();
      draft.setQty('cookies', 5000);
      expect(draft.qtyOf('cookies'), 999);
      draft.setQty('cookies', -3);
      expect(draft.qtyOf('cookies'), 0);
    });

    test('refuses a note over 140 characters', () {
      final draft = OrderDraft(customer: 'Laura')..setQty('cookies', 1);
      draft.note = 'x' * 140;
      expect(draft.isValid, isTrue);
      draft.note = 'x' * 141;
      expect(draft.isValid, isFalse);
    });

    test('trims what it sends, and turns an empty note into nothing', () {
      final draft = OrderDraft(customer: '  Laura  ', note: '   ');
      expect(draft.trimmedCustomer, 'Laura');
      expect(draft.trimmedNote, isNull);
      draft.note = '  No nuts ';
      expect(draft.trimmedNote, 'No nuts');
    });

    test('offers today to 60 days ahead, and no earlier', () {
      final draft = OrderDraft();
      expect(Dates.key(draft.firstSelectableDay), Dates.todayKey());
      expect(draft.lastSelectableDay.difference(Dates.today()).inDays, 60);
    });

    test('follows the tile that is chosen', () {
      final draft = OrderDraft();
      draft.choice = PickupChoice.today;
      expect(Dates.key(draft.pickupDate), Dates.todayKey());
      expect(draft.daysFromToday, 0);

      final friday = Dates.today().add(const Duration(days: 5));
      draft.pickDay(friday);
      expect(draft.choice, PickupChoice.pickADay);
      expect(Dates.key(draft.pickupDate), Dates.key(friday));
      expect(draft.daysFromToday, 5);
    });
  });

  group('editing an order', () {
    test('comes back filled in, on the tile that matches its day', () {
      final draft = OrderDraft.editing(
        customer: 'Sofía Ramos',
        note: 'Birthday, no nuts',
        quantities: {'cookies': 12, 'cake': 2},
        pickupDate: Dates.tomorrow(),
      );
      expect(draft.isEditing, isTrue);
      expect(draft.customer, 'Sofía Ramos');
      expect(draft.note, 'Birthday, no nuts');
      expect(draft.itemCount, 14);
      expect(draft.choice, PickupChoice.tomorrow);
      expect(draft.isValid, isTrue);
    });

    test('keeps a day that has already passed (HU-04 CA4)', () {
      final lastWeek = Dates.today().subtract(const Duration(days: 7));
      final draft = OrderDraft.editing(
        customer: 'Marta',
        note: null,
        quantities: {'cookies': 2},
        pickupDate: lastWeek,
      );
      expect(draft.choice, PickupChoice.pickADay);
      expect(Dates.key(draft.pickupDate), Dates.key(lastWeek));
      expect(
        Dates.key(draft.firstSelectableDay),
        Dates.key(lastWeek),
        reason: 'the picker has to reach the day it already has',
      );
      expect(draft.isValid, isTrue);
    });

    test('lands on the Today tile when that is its day', () {
      final draft = OrderDraft.editing(
        customer: 'Marta',
        note: null,
        quantities: {'cookies': 2},
        pickupDate: Dates.today(),
      );
      expect(draft.choice, PickupChoice.today);
    });

    test('does not change the order it came from', () {
      final original = {'cookies': 12};
      final draft = OrderDraft.editing(
        customer: 'Laura',
        note: null,
        quantities: original,
        pickupDate: Dates.tomorrow(),
      );
      draft.setQty('cookies', 24);
      expect(original['cookies'], 12);
    });
  });
}
