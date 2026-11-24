import '../../../core/dates.dart';

/// One product on the "For tomorrow" row: how many to make and how many orders asked for it.
class MakeItem {
  const MakeItem({required this.name, required this.photo, required this.qty, required this.orders});

  factory MakeItem.fromJson(Map<String, dynamic> json) => MakeItem(
        name: json['name'] as String,
        photo: json['photo'] as String?,
        qty: (json['qty'] as num).toInt(),
        orders: (json['orders'] as num).toInt(),
      );

  final String name;
  final String? photo;
  final int qty;
  final int orders;

  String get ordersLabel => orders == 1 ? '1 order' : '$orders orders';
}

/// What has to be made tomorrow, added up across every order of that day.
class TomorrowPlan {
  const TomorrowPlan({required this.date, required this.things, required this.orders, required this.items});

  factory TomorrowPlan.fromJson(Map<String, dynamic> json) => TomorrowPlan(
        date: Dates.parse(json['date'] as String),
        things: (json['things'] as num).toInt(),
        orders: (json['orders'] as num).toInt(),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => MakeItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  final DateTime date;

  /// Every quantity added together: "52 things to make".
  final int things;
  final int orders;

  /// Largest first, ties A→Z.
  final List<MakeItem> items;

  bool get isEmpty => items.isEmpty;

  /// The banner photo is the item with the most to make.
  String? get bannerPhoto => items.isEmpty ? null : items.first.photo;
}

/// One person picking up today.
class Pickup {
  const Pickup({required this.id, required this.customer, required this.pickedUp, required this.items});

  factory Pickup.fromJson(Map<String, dynamic> json) => Pickup(
        id: json['id'] as String,
        customer: json['customer'] as String,
        pickedUp: json['picked_up'] == true,
        items: ((json['items'] as List?) ?? const [])
            .map((e) => PickupLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  final String id;
  final String customer;
  final bool pickedUp;
  final List<PickupLine> items;

  /// "6 Brownies · 1 Lasagna".
  String get itemsLabel => items.map((i) => '${i.qty} ${i.name}').join(' · ');

  String? get photo => items.isEmpty ? null : items.first.photo;
}

class PickupLine {
  const PickupLine({required this.name, required this.photo, required this.qty});

  factory PickupLine.fromJson(Map<String, dynamic> json) => PickupLine(
        name: json['name'] as String,
        photo: json['photo'] as String?,
        qty: (json['qty'] as num).toInt(),
      );

  final String name;
  final String? photo;
  final int qty;
}

/// Today: who is coming, and how many have already been.
class TodayPickups {
  const TodayPickups({required this.date, required this.done, required this.total, required this.pickups});

  factory TodayPickups.fromJson(Map<String, dynamic> json) => TodayPickups(
        date: Dates.parse(json['date'] as String),
        done: (json['done'] as num).toInt(),
        total: (json['total'] as num).toInt(),
        pickups: ((json['pickups'] as List?) ?? const [])
            .map((e) => Pickup.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  final DateTime date;
  final int done;
  final int total;
  final List<Pickup> pickups;

  /// "1 of 2 done", or "None" when nobody is coming.
  String get doneLabel => total == 0 ? 'None' : '$done of $total done';
}

/// Everything Home draws.
class HomeData {
  const HomeData({required this.businessName, required this.tomorrow, required this.today});

  factory HomeData.fromJson(Map<String, dynamic> json) => HomeData(
        businessName: json['business_name'] as String,
        tomorrow: TomorrowPlan.fromJson(Map<String, dynamic>.from(json['tomorrow'] as Map)),
        today: TodayPickups.fromJson(Map<String, dynamic>.from(json['today'] as Map)),
      );

  final String businessName;
  final TomorrowPlan tomorrow;
  final TodayPickups today;
}
