import '../../../core/dates.dart';

/// One line of an order. The name and photo were copied when the order was saved, so an order
/// always shows what was ordered, even if the menu item was renamed or removed since.
class OrderLine {
  const OrderLine({required this.productId, required this.name, required this.photo, required this.qty});

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        productId: json['product_id'] as String,
        name: json['name'] as String,
        photo: json['photo'] as String?,
        qty: (json['qty'] as num).toInt(),
      );

  final String productId;
  final String name;
  final String? photo;
  final int qty;

  /// "12 Cookies".
  String get label => '$qty $name';
}

class Order {
  const Order({
    required this.id,
    required this.customer,
    required this.pickupDate,
    required this.note,
    required this.pickedUp,
    required this.pickedUpAt,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        customer: json['customer'] as String,
        pickupDate: Dates.parse(json['pickup_date'] as String),
        note: json['note'] as String?,
        pickedUp: json['picked_up'] == true,
        pickedUpAt: Dates.parseStamp(json['picked_up_at'] as String?),
        createdAt: Dates.parseStamp(json['created_at'] as String?),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  final String id;
  final String customer;
  final DateTime pickupDate;
  final String? note;
  final bool pickedUp;
  final DateTime? pickedUpAt;
  final DateTime? createdAt;
  final List<OrderLine> items;

  /// How many things in total, across every line: "13 items".
  int get itemCount => items.fold(0, (sum, i) => sum + i.qty);

  bool get hasNote => (note ?? '').trim().isNotEmpty;
}

/// One day of the week strip.
class DayOrders {
  const DayOrders({required this.date, required this.orders});

  factory DayOrders.fromJson(Map<String, dynamic> json) => DayOrders(
        date: Dates.parse(json['date'] as String),
        orders: ((json['orders'] as List?) ?? const [])
            .map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  final DateTime date;
  final List<Order> orders;
}

/// One hit of a search: the order and the day it is for.
class SearchHit {
  const SearchHit({required this.date, required this.order});

  factory SearchHit.fromJson(Map<String, dynamic> json) => SearchHit(
        date: Dates.parse(json['date'] as String),
        order: Order.fromJson(Map<String, dynamic>.from(json['order'] as Map)),
      );

  final DateTime date;
  final Order order;
}
