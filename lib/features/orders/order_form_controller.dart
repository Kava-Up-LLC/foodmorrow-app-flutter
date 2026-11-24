import '../../core/appambit/analytics.dart';
import '../../core/loadable.dart';
import '../menu/data/product.dart';
import '../menu/menu_repository.dart';
import 'data/order.dart';
import 'data/orders_repository.dart';
import 'order_draft.dart';

/// New order / Edit order. The menu is read once when the screen opens; saving is the only other
/// call, so a slow network never gets in the way of typing (spec §11).
class OrderFormController extends LoadableController {
  OrderFormController({
    required this.repository,
    required this.menu,
    required this.analytics,
    this.editing,
  });

  final OrdersRepository repository;
  final MenuRepository menu;
  final Analytics analytics;

  /// The order being changed, or null for a new one.
  final Order? editing;

  List<Product> products = const [];
  late OrderDraft draft = editing == null
      ? OrderDraft()
      : OrderDraft.editing(
          customer: editing!.customer,
          note: editing!.note,
          quantities: {for (final line in editing!.items) line.productId: line.qty},
          pickupDate: editing!.pickupDate,
        );

  bool get isEditing => editing != null;

  String get title => isEditing ? 'Edit order' : 'New order';

  /// True when the seller has nothing on their menu yet (HU-03 CA6).
  bool get hasNoMenu => !loading && failure == null && products.isEmpty;

  @override
  Future<void> fetch() async {
    products = await menu.list();
  }

  void setCustomer(String value) {
    draft.customer = value;
    refresh();
  }

  void setNote(String value) {
    draft.note = value;
    refresh();
  }

  void setQty(String productId, int qty) {
    draft.setQty(productId, qty);
    refresh();
  }

  void choose(PickupChoice choice) {
    draft.choice = choice;
    refresh();
  }

  void pickDay(DateTime day) {
    draft.pickDay(day);
    refresh();
  }

  /// Saves and reports whether it went through.
  Future<bool> save() => runWrite(() async {
        await repository.save(
          id: editing?.id,
          customer: draft.trimmedCustomer,
          pickupDate: draft.pickupDate,
          note: draft.trimmedNote,
          quantities: draft.quantities,
        );
        analytics.track(
          isEditing ? Events.orderEdited : Events.orderSaved,
          {'items': '${draft.lineCount}', 'days_ahead': '${draft.daysFromToday}'},
        );
      });
}
