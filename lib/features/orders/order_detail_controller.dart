import '../../core/appambit/analytics.dart';
import '../../core/loadable.dart';
import 'data/order.dart';
import 'data/orders_repository.dart';

/// One order: its items, its note, its timeline, and the two things you can do to it.
class OrderDetailController extends LoadableController {
  OrderDetailController({
    required this.repository,
    required this.analytics,
    required this.orderId,
  });

  final OrdersRepository repository;
  final Analytics analytics;
  final String orderId;

  Order? order;

  /// True once anything here changed, so the screen behind reloads on the way back.
  bool changed = false;

  @override
  Future<void> fetch() async {
    order = await repository.get(orderId);
  }

  /// "Mark as picked up" / "Undo picked up".
  String get actionLabel => (order?.pickedUp ?? false) ? 'Undo picked up' : 'Mark as picked up';

  Future<void> togglePickedUp() async {
    final current = order;
    if (current == null) return;
    final ok = await runWrite(() async {
      await repository.setPickedUp(id: current.id, pickedUp: !current.pickedUp);
      analytics.track(Events.orderPickedUp, {'from': 'detail', 'undo': '${current.pickedUp}'});
      order = await repository.get(current.id);
    });
    if (ok) changed = true;
  }

  Future<bool> delete() async {
    final ok = await runWrite(() async {
      await repository.delete(orderId);
      analytics.track(Events.orderDeleted);
    });
    if (ok) changed = true;
    return ok;
  }

  /// Called when the edit screen saved something.
  Future<void> reloadAfterEdit() async {
    changed = true;
    await load();
  }
}
