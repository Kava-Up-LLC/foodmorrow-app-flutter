import 'package:intl/intl.dart';

/// Dates are the seller's calendar: they come from the phone, go to the cloud as 'YYYY-MM-DD', and
/// the cloud never works them out (spec §2 rule 2).
abstract final class Dates {
  /// 'YYYY-MM-DD' for a date, ignoring the time of day.
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parse(String key) => DateTime.parse(key);

  /// Midnight today on this phone.
  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime tomorrow() => today().add(const Duration(days: 1));

  static String todayKey() => key(today());
  static String tomorrowKey() => key(tomorrow());

  /// The 7 days of the week [date] falls in. [weekStart] is 'mon' or 'sun' (Settings).
  static List<DateTime> week(DateTime date, String weekStart) {
    final first = startOfWeek(date, weekStart);
    return List.generate(7, (i) => first.add(Duration(days: i)));
  }

  /// The first day of [date]'s week. DateTime.weekday is 1 = Monday … 7 = Sunday.
  static DateTime startOfWeek(DateTime date, String weekStart) {
    final day = DateTime(date.year, date.month, date.day);
    final back = weekStart == 'sun' ? day.weekday % 7 : day.weekday - 1;
    return day.subtract(Duration(days: back));
  }

  /// "Today" / "Tomorrow" / "Yesterday" for a date close to now, else null.
  static String? relative(DateTime date) {
    final days = DateTime(date.year, date.month, date.day).difference(today()).inDays;
    return switch (days) { 0 => 'Today', 1 => 'Tomorrow', -1 => 'Yesterday', _ => null };
  }

  /// "Wed, Nov 25".
  static String short(DateTime d) => DateFormat('EEE, MMM d').format(d);

  /// "Tuesday, Nov 24" — the line above the business name on Home.
  static String long(DateTime d) => DateFormat('EEEE, MMM d').format(d);

  /// "Wednesday".
  static String weekday(DateTime d) => DateFormat('EEEE').format(d);

  /// "Wed" — the day strip.
  static String weekdayShort(DateTime d) => DateFormat('EEE').format(d);

  /// "November" — above the Orders title.
  static String month(DateTime d) => DateFormat('MMMM').format(d);

  /// "Nov 23" — the timeline.
  static String dayAndMonth(DateTime d) => DateFormat('MMM d').format(d);

  /// "Wed 25" — the detail after the dot on the Save button.
  static String buttonDay(DateTime d) => DateFormat('EEE d').format(d);

  /// A timestamp from the database ('2026-11-24 18:30:12.345'), as local-ish date. The cloud writes
  /// UTC, so it is read as UTC and shown in the phone's zone.
  static DateTime? parseStamp(String? stamp) {
    if (stamp == null || stamp.isEmpty) return null;
    return DateTime.tryParse('${stamp.replaceFirst(' ', 'T')}Z')?.toLocal();
  }
}
