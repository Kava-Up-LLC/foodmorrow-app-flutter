import '../../core/dates.dart';

/// Which of the three pickup tiles is chosen.
enum PickupChoice { today, tomorrow, pickADay }

/// The order being typed, as plain Dart — no widgets, no cloud. The rules of spec §2 rule 3 live
/// here so they can be tested on their own.
class OrderDraft {
  OrderDraft({
    this.customer = '',
    this.note = '',
    Map<String, int>? quantities,
    this.choice = PickupChoice.tomorrow,
    DateTime? chosenDay,
    this.editingDate,
  })  : quantities = {...?quantities},
        chosenDay = chosenDay ?? Dates.tomorrow();

  /// The draft for editing an order that already exists. Its day is kept as it is, even if it has
  /// passed (spec §2 rule 5).
  factory OrderDraft.editing({
    required String customer,
    required String? note,
    required Map<String, int> quantities,
    required DateTime pickupDate,
  }) {
    final choice = switch (Dates.key(pickupDate)) {
      final k when k == Dates.todayKey() => PickupChoice.today,
      final k when k == Dates.tomorrowKey() => PickupChoice.tomorrow,
      _ => PickupChoice.pickADay,
    };
    return OrderDraft(
      customer: customer,
      note: note ?? '',
      quantities: quantities,
      choice: choice,
      chosenDay: pickupDate,
      editingDate: pickupDate,
    );
  }

  static const maxCustomer = 40;
  static const maxNote = 140;
  static const maxQty = 999;

  /// How far ahead a new order may be picked up.
  static const daysAhead = 60;

  String customer;
  String note;
  final Map<String, int> quantities;
  PickupChoice choice;

  /// The day behind the "Pick a day" tile.
  DateTime chosenDay;

  /// The day an edited order already had. Null for a new order.
  final DateTime? editingDate;

  bool get isEditing => editingDate != null;

  /// The day this order is for.
  DateTime get pickupDate => switch (choice) {
        PickupChoice.today => Dates.today(),
        PickupChoice.tomorrow => Dates.tomorrow(),
        PickupChoice.pickADay => chosenDay,
      };

  /// The earliest day "Pick a day" offers. An order being edited may keep a day gone by.
  DateTime get firstSelectableDay {
    final today = Dates.today();
    final kept = editingDate;
    return kept != null && kept.isBefore(today) ? kept : today;
  }

  DateTime get lastSelectableDay => Dates.today().add(const Duration(days: daysAhead));

  int qtyOf(String productId) => quantities[productId] ?? 0;

  void setQty(String productId, int qty) {
    final clamped = qty.clamp(0, maxQty);
    if (clamped == 0) {
      quantities.remove(productId);
    } else {
      quantities[productId] = clamped;
    }
  }

  void pickDay(DateTime day) {
    chosenDay = DateTime(day.year, day.month, day.day);
    choice = PickupChoice.pickADay;
  }

  /// Everything the order asks for, added up: "13 items".
  int get itemCount => quantities.values.fold(0, (sum, q) => sum + q);

  /// How many different menu items are in it.
  int get lineCount => quantities.values.where((q) => q > 0).length;

  String get trimmedCustomer => customer.trim();

  String? get trimmedNote {
    final n = note.trim();
    return n.isEmpty ? null : n;
  }

  bool get hasCustomer =>
      trimmedCustomer.isNotEmpty && trimmedCustomer.length <= maxCustomer;

  bool get noteFits => note.trim().length <= maxNote;

  /// An order needs a customer and at least one item.
  bool get isValid => hasCustomer && lineCount > 0 && noteFits;

  /// "13 items" / "1 item".
  String get itemCountLabel => itemCount == 1 ? '1 item' : '$itemCount items';

  /// How far ahead this order is, for the `order_saved` event.
  int get daysFromToday => pickupDate.difference(Dates.today()).inDays;
}
