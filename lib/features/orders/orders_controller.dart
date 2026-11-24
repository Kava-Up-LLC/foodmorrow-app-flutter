import '../../core/dates.dart';
import '../../core/loadable.dart';
import 'data/order.dart';
import 'data/orders_repository.dart';

/// The Orders tab: a week at a time, with one day selected.
class OrdersController extends LoadableController {
  OrdersController({
    required this.repository,
    required this.weekStart,
    DateTime? initialDay,
  })  : selectedDay = initialDay ?? Dates.today(),
        _weekAnchor = initialDay ?? Dates.today();

  final OrdersRepository repository;

  /// 'mon' or 'sun', from Settings.
  final String weekStart;

  /// The day whose orders are listed.
  DateTime selectedDay;

  /// Any day inside the week being shown.
  DateTime _weekAnchor;

  List<DayOrders> days = const [];

  List<DateTime> get weekDays => Dates.week(_weekAnchor, weekStart);

  @override
  Future<void> fetch() async {
    final week = weekDays;
    days = await repository.week(from: week.first, to: week.last);
  }

  /// The orders of the selected day.
  List<Order> get selectedOrders {
    final key = Dates.key(selectedDay);
    for (final day in days) {
      if (Dates.key(day.date) == key) return day.orders;
    }
    return const [];
  }

  /// How many orders each day of the week has, for the dots.
  int ordersOn(DateTime day) {
    final key = Dates.key(day);
    for (final d in days) {
      if (Dates.key(d.date) == key) return d.orders.length;
    }
    return 0;
  }

  /// "Wednesday · Tomorrow", or just "Wednesday" for a day that isn't close to now.
  String get selectedTitle {
    final relative = Dates.relative(selectedDay);
    final weekday = Dates.weekday(selectedDay);
    return relative == null ? weekday : '$weekday · $relative';
  }

  /// "3 orders" / "1 order" / "No orders".
  String get selectedCountLabel => switch (selectedOrders.length) {
        0 => 'No orders',
        1 => '1 order',
        final n => '$n orders',
      };

  /// The month above the title, from the week being shown.
  String get monthLabel => Dates.month(selectedDay);

  void selectDay(DateTime day) {
    selectedDay = DateTime(day.year, day.month, day.day);
    refresh();
  }

  /// Swipe the strip: one week back or forward. The same weekday stays selected.
  Future<void> moveWeek(int weeks) async {
    _weekAnchor = _weekAnchor.add(Duration(days: 7 * weeks));
    selectedDay = selectedDay.add(Duration(days: 7 * weeks));
    await load();
  }

  /// Jumps to the week a day belongs to and selects it (Home's "See all").
  Future<void> goToDay(DateTime day) async {
    _weekAnchor = day;
    selectedDay = DateTime(day.year, day.month, day.day);
    await load();
  }
}
