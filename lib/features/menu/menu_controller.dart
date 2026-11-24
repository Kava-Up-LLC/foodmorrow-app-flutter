import '../../core/loadable.dart';
import 'data/product.dart';
import 'menu_repository.dart';

/// The Menu tab: what this seller sells.
class MenuListController extends LoadableController {
  MenuListController({required this.repository});

  final MenuRepository repository;

  List<Product> products = const [];

  @override
  Future<void> fetch() async {
    products = await repository.list();
  }

  /// "4 items" above the title.
  String get countLabel => products.length == 1 ? '1 item' : '${products.length} items';
}
