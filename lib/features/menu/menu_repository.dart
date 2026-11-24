import '../../core/appambit/cloud_service.dart';
import '../../core/dates.dart';
import 'data/product.dart';

/// The menu, through the `products` Cloud Code function. Every call answers with the whole active
/// menu, so the screen never has to guess what changed.
abstract interface class MenuRepository {
  Future<List<Product>> list();
  Future<List<Product>> add({required String name, required String? photo});
  Future<List<Product>> edit({required String id, required String name, required String? photo});
  Future<List<Product>> remove(String id);
}

class CloudMenuRepository implements MenuRepository {
  CloudMenuRepository({required this.cloud, required this.sellerId});

  final CloudService cloud;
  final String sellerId;

  Future<List<Product>> _call(Map<String, dynamic> body) async {
    final res = await cloud.call('products', {
      'seller_id': sellerId,
      'today': Dates.todayKey(),
      ...body,
    });
    return ((res['products'] as List?) ?? const [])
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<Product>> list() => _call({'action': 'list'});

  @override
  Future<List<Product>> add({required String name, required String? photo}) =>
      _call({'action': 'add', 'name': name, 'photo': photo});

  @override
  Future<List<Product>> edit({required String id, required String name, required String? photo}) =>
      _call({'action': 'edit', 'id': id, 'name': name, 'photo': photo});

  @override
  Future<List<Product>> remove(String id) => _call({'action': 'remove', 'id': id});
}
