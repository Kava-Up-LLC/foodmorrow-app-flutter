import 'dart:async';

import 'package:foodmorrow_app/app_services.dart';
import 'package:foodmorrow_app/core/appambit/analytics.dart';
import 'package:foodmorrow_app/core/appambit/cloud_service.dart';
import 'package:foodmorrow_app/core/appambit/diagnostics.dart';
import 'package:foodmorrow_app/core/dates.dart';
import 'package:foodmorrow_app/core/errors.dart';
import 'package:foodmorrow_app/core/local_store.dart';
import 'package:foodmorrow_app/features/home/data/home_data.dart';
import 'package:foodmorrow_app/features/home/home_repository.dart';
import 'package:foodmorrow_app/features/menu/data/product.dart';
import 'package:foodmorrow_app/features/menu/menu_repository.dart';
import 'package:foodmorrow_app/features/orders/data/order.dart';
import 'package:foodmorrow_app/features/orders/data/orders_repository.dart';
import 'package:foodmorrow_app/features/settings/settings_repository.dart';

/// Stand-ins for everything that would talk to AppAmbit, so the screens can be driven without a
/// network. Each one can be told to fail, which is how the No connection banner is tested.
class FakeStore implements LocalStore {
  FakeStore({this.sellerId = 'seller-1', bool welcomeDone = true}) : _welcomeDone = welcomeDone;

  @override
  final String sellerId;
  bool _welcomeDone;

  @override
  bool get welcomeDone => _welcomeDone;

  @override
  Future<void> markWelcomeDone() async => _welcomeDone = true;
}

class FakeAnalytics implements Analytics {
  final events = <(String, Map<String, String>)>[];

  @override
  void track(String event, [Map<String, String> properties = const {}]) =>
      events.add((event, properties));

  List<String> get names => events.map((e) => e.$1).toList();
}

class FakeDiagnostics implements Diagnostics {
  int crashes = 0;

  @override
  void testCrash() => crashes++;
}

class FakeCloud implements CloudService {
  final calls = <(String, Map<String, dynamic>)>[];

  @override
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> body) async {
    calls.add((function, body));
    return {'ok': true};
  }
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({this.businessName = "Ana's Kitchen", this.weekStart = 'mon'});

  String businessName;
  String weekStart;
  AppFailure? failWith;

  @override
  Future<SellerProfile> hello() async {
    if (failWith != null) throw failWith!;
    return SellerProfile(businessName: businessName, weekStart: weekStart);
  }

  @override
  Future<SellerProfile> save({String? businessName, String? weekStart}) async {
    if (failWith != null) throw failWith!;
    if (businessName != null) this.businessName = businessName;
    if (weekStart != null) this.weekStart = weekStart;
    return SellerProfile(businessName: this.businessName, weekStart: this.weekStart);
  }
}

class FakeMenuRepository implements MenuRepository {
  FakeMenuRepository([List<Product>? products]) : products = products ?? [];

  List<Product> products;
  AppFailure? failWith;
  final added = <(String, String?)>[];
  final edited = <(String, String, String?)>[];
  final removed = <String>[];

  List<Product> _answer() {
    if (failWith != null) throw failWith!;
    return List.of(products);
  }

  @override
  Future<List<Product>> list() async => _answer();

  @override
  Future<List<Product>> add({required String name, required String? photo}) async {
    if (failWith != null) throw failWith!;
    added.add((name, photo));
    products = [
      ...products,
      Product(id: 'p${products.length + 1}', name: name, photo: photo, orders: 0),
    ];
    return _answer();
  }

  @override
  Future<List<Product>> edit({
    required String id,
    required String name,
    required String? photo,
  }) async {
    if (failWith != null) throw failWith!;
    edited.add((id, name, photo));
    products = [
      for (final p in products)
        if (p.id == id) Product(id: p.id, name: name, photo: photo, orders: p.orders) else p,
    ];
    return _answer();
  }

  @override
  Future<List<Product>> remove(String id) async {
    if (failWith != null) throw failWith!;
    removed.add(id);
    products = products.where((p) => p.id != id).toList();
    return _answer();
  }
}

class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository({this.days = const [], this.hits = const [], this.order});

  List<DayOrders> days;
  List<SearchHit> hits;
  Order? order;
  AppFailure? failWith;

  final saved = <Map<String, dynamic>>[];
  final pickedUp = <(String, bool)>[];
  final deleted = <String>[];
  final searched = <String>[];

  void _check() {
    if (failWith != null) throw failWith!;
  }

  @override
  Future<List<DayOrders>> week({required DateTime from, required DateTime to}) async {
    _check();
    // Every day of the range, filled from whatever `days` holds.
    final out = <DayOrders>[];
    for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
      final match = days.where((x) => Dates.key(x.date) == Dates.key(d));
      out.add(match.isEmpty ? DayOrders(date: d, orders: const []) : match.first);
    }
    return out;
  }

  @override
  Future<List<SearchHit>> search(String query) async {
    _check();
    searched.add(query);
    return hits;
  }

  @override
  Future<Order> get(String id) async {
    _check();
    final found = order;
    if (found == null) throw const AppFailure(FailureKind.notFound);
    return found;
  }

  @override
  Future<String> save({
    String? id,
    required String customer,
    required DateTime pickupDate,
    required String? note,
    required Map<String, int> quantities,
  }) async {
    _check();
    saved.add({
      'id': id,
      'customer': customer,
      'pickup_date': Dates.key(pickupDate),
      'note': note,
      'quantities': Map.of(quantities),
    });
    return id ?? 'new-order';
  }

  @override
  Future<void> setPickedUp({required String id, required bool pickedUp}) async {
    _check();
    this.pickedUp.add((id, pickedUp));
  }

  @override
  Future<void> delete(String id) async {
    _check();
    deleted.add(id);
  }
}

class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository(this.data);

  HomeData data;
  AppFailure? failWith;
  int loads = 0;

  @override
  Future<HomeData> load() async {
    loads++;
    if (failWith != null) throw failWith!;
    return data;
  }
}

/// Builds the HomeData a test needs without spelling out every field.
HomeData homeData({
  String businessName = "Ana's Kitchen",
  List<MakeItem> tomorrowItems = const [],
  List<Pickup> pickups = const [],
}) {
  final things = tomorrowItems.fold<int>(0, (sum, i) => sum + i.qty);
  return HomeData(
    businessName: businessName,
    tomorrow: TomorrowPlan(
      date: Dates.tomorrow(),
      things: things,
      orders: tomorrowItems.isEmpty ? 0 : 1,
      items: tomorrowItems,
    ),
    today: TodayPickups(
      date: Dates.today(),
      done: pickups.where((p) => p.pickedUp).length,
      total: pickups.length,
      pickups: pickups,
    ),
  );
}

Order fakeOrder({
  String id = 'o1',
  String customer = 'Laura Méndez',
  DateTime? pickupDate,
  String? note,
  bool pickedUp = false,
  List<OrderLine> items = const [
    OrderLine(productId: 'p1', name: 'Cookies', photo: 'cookies', qty: 12),
  ],
}) {
  return Order(
    id: id,
    customer: customer,
    pickupDate: pickupDate ?? Dates.tomorrow(),
    note: note,
    pickedUp: pickedUp,
    pickedUpAt: pickedUp ? DateTime.now() : null,
    createdAt: DateTime.now(),
    items: items,
  );
}

/// AppServices wired entirely with fakes.
AppServices fakeServices({
  HomeRepository? home,
  MenuRepository? menu,
  OrdersRepository? orders,
  SettingsRepository? settings,
  FakeAnalytics? analytics,
  FakeDiagnostics? diagnostics,
  FakeStore? store,
}) {
  return AppServices(
    cloud: FakeCloud(),
    analytics: analytics ?? FakeAnalytics(),
    diagnostics: diagnostics ?? FakeDiagnostics(),
    store: store ?? FakeStore(),
    platform: 'ios',
    appVersion: '1.0.0',
    home: home ?? FakeHomeRepository(homeData()),
    menu: menu ?? FakeMenuRepository(),
    orders: orders ?? FakeOrdersRepository(),
    settings: settings ?? FakeSettingsRepository(),
  );
}

/// Repositories that hold their answer until [release] is called, so a test can look at a screen
/// while it is still loading.
mixin _Held<T> {
  final _gate = Completer<void>();

  /// Lets the pending call finish.
  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  Future<void> get held => _gate.future;
}

class SlowHomeRepository with _Held<HomeData> implements HomeRepository {
  SlowHomeRepository(this.data);

  final HomeData data;

  @override
  Future<HomeData> load() async {
    await held;
    return data;
  }
}

class SlowMenuRepository with _Held<List<Product>> implements MenuRepository {
  @override
  Future<List<Product>> list() async {
    await held;
    return const [];
  }

  @override
  Future<List<Product>> add({required String name, required String? photo}) async => list();

  @override
  Future<List<Product>> edit({
    required String id,
    required String name,
    required String? photo,
  }) async => list();

  @override
  Future<List<Product>> remove(String id) async => list();
}

class SlowOrdersRepository with _Held<void> implements OrdersRepository {
  @override
  Future<List<DayOrders>> week({required DateTime from, required DateTime to}) async {
    await held;
    return [
      for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1)))
        DayOrders(date: d, orders: const []),
    ];
  }

  @override
  Future<List<SearchHit>> search(String query) async {
    await held;
    return const [];
  }

  @override
  Future<Order> get(String id) async {
    await held;
    return fakeOrder(id: id);
  }

  @override
  Future<String> save({
    String? id,
    required String customer,
    required DateTime pickupDate,
    required String? note,
    required Map<String, int> quantities,
  }) async {
    await held;
    return id ?? 'new-order';
  }

  @override
  Future<void> setPickedUp({required String id, required bool pickedUp}) => held;

  @override
  Future<void> delete(String id) => held;
}

class SlowSettingsRepository with _Held<SellerProfile> implements SettingsRepository {
  SlowSettingsRepository({this.weekStart = 'mon'});

  final String weekStart;

  @override
  Future<SellerProfile> hello() async {
    await held;
    return SellerProfile(businessName: "Ana's Kitchen", weekStart: weekStart);
  }

  @override
  Future<SellerProfile> save({String? businessName, String? weekStart}) => hello();
}
