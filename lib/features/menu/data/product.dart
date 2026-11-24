/// A menu item: what this seller sells.
class Product {
  const Product({required this.id, required this.name, required this.photo, required this.orders});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        photo: json['photo'] as String?,
        orders: ((json['orders'] as num?) ?? 0).toInt(),
      );

  final String id;
  final String name;
  final String? photo;

  /// Orders from today on that include this item: "In 3 orders".
  final int orders;

  /// "In 3 orders" / "In 1 order" / "Add a photo" is decided by the card, not here.
  String get ordersLabel => orders == 1 ? 'In 1 order' : 'In $orders orders';
}
