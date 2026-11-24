import '../../core/appambit/analytics.dart';
import '../../core/loadable.dart';
import '../orders/data/orders_repository.dart';
import 'data/home_data.dart';
import 'home_repository.dart';

/// Home: what to make tomorrow, and who is picking up today.
class HomeController extends LoadableController {
  HomeController({
    required this.repository,
    required this.orders,
    required this.analytics,
  });

  final HomeRepository repository;
  final OrdersRepository orders;
  final Analytics analytics;

  HomeData? data;

  /// The pickup whose check is waiting for the cloud, so only that row shows it.
  String? pendingPickup;

  @override
  Future<void> fetch() async {
    data = await repository.load();
  }

  /// Ticks a pickup off, or puts it back. Home reloads so "1 of 2 done" and the list agree.
  Future<void> togglePickedUp(Pickup pickup) async {
    pendingPickup = pickup.id;
    refresh();
    await runWrite(() async {
      await orders.setPickedUp(id: pickup.id, pickedUp: !pickup.pickedUp);
      analytics.track(Events.orderPickedUp, {'from': 'home', 'undo': '${pickup.pickedUp}'});
      data = await repository.load();
    });
    pendingPickup = null;
    refresh();
  }

  void trackTomorrowListViewed() {
    analytics.track(Events.tomorrowListViewed, {'items': '${data?.tomorrow.items.length ?? 0}'});
  }
}
