import '../../../core/appambit/cloud_service.dart';
import '../../../core/dates.dart';
import 'order.dart';

/// Everything about orders, through the `orders` Cloud Code function.
abstract interface class OrdersRepository {
  /// The 7 days from [from] to [to], empty days included.
  Future<List<DayOrders>> week({required DateTime from, required DateTime to});

  /// Orders from today on whose customer contains [query].
  Future<List<SearchHit>> search(String query);

  Future<Order> get(String id);

  /// Saves a new order, or updates the one with [id]. Returns the order's id.
  Future<String> save({
    String? id,
    required String customer,
    required DateTime pickupDate,
    required String? note,
    required Map<String, int> quantities,
  });

  Future<void> setPickedUp({required String id, required bool pickedUp});

  Future<void> delete(String id);
}

class CloudOrdersRepository implements OrdersRepository {
  CloudOrdersRepository({required this.cloud, required this.sellerId});

  final CloudService cloud;
  final String sellerId;

  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) =>
      cloud.call('orders', {'seller_id': sellerId, ...body});

  @override
  Future<List<DayOrders>> week({required DateTime from, required DateTime to}) async {
    final res = await _call({'action': 'week', 'from': Dates.key(from), 'to': Dates.key(to)});
    return ((res['days'] as List?) ?? const [])
        .map((e) => DayOrders.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<SearchHit>> search(String query) async {
    final res = await _call({'action': 'search', 'today': Dates.todayKey(), 'q': query});
    return ((res['results'] as List?) ?? const [])
        .map((e) => SearchHit.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Order> get(String id) async {
    final res = await _call({'action': 'get', 'id': id});
    return Order.fromJson(Map<String, dynamic>.from(res['order'] as Map));
  }

  @override
  Future<String> save({
    String? id,
    required String customer,
    required DateTime pickupDate,
    required String? note,
    required Map<String, int> quantities,
  }) async {
    final items = quantities.entries
        .where((e) => e.value > 0)
        .map((e) => {'product_id': e.key, 'qty': e.value})
        .toList();
    final res = await _call({
      'action': 'save',
      'today': Dates.todayKey(),
      'order': {
        'id': ?id,
        'customer': customer,
        'pickup_date': Dates.key(pickupDate),
        'note': note,
        'items': items,
      },
    });
    return res['id'] as String;
  }

  @override
  Future<void> setPickedUp({required String id, required bool pickedUp}) =>
      _call({'action': 'picked_up', 'id': id, 'picked_up': pickedUp});

  @override
  Future<void> delete(String id) => _call({'action': 'delete', 'id': id});
}
