import 'package:flutter_test/flutter_test.dart';
import 'package:foodmorrow_app/core/dates.dart';

void main() {
  // A Wednesday, so starting the week on Monday and on Sunday give different answers.
  final wednesday = DateTime(2026, 11, 25);

  group('keys', () {
    test('are always YYYY-MM-DD, padded', () {
      expect(Dates.key(DateTime(2026, 1, 5)), '2026-01-05');
      expect(Dates.key(DateTime(2026, 11, 25, 23, 59)), '2026-11-25');
    });

    test('round-trip through parse', () {
      expect(Dates.key(Dates.parse('2026-11-25')), '2026-11-25');
    });

    test('tomorrow is the day after today', () {
      expect(
        Dates.parse(Dates.tomorrowKey()).difference(Dates.parse(Dates.todayKey())).inDays,
        1,
      );
    });
  });

  group('the week', () {
    test('starts on Monday when that is the setting', () {
      final week = Dates.week(wednesday, 'mon');
      expect(week.length, 7);
      expect(Dates.key(week.first), '2026-11-23');
      expect(Dates.key(week.last), '2026-11-29');
      expect(Dates.weekdayShort(week.first), 'Mon');
    });

    test('starts on Sunday when that is the setting', () {
      final week = Dates.week(wednesday, 'sun');
      expect(week.length, 7);
      expect(Dates.key(week.first), '2026-11-22');
      expect(Dates.key(week.last), '2026-11-28');
      expect(Dates.weekdayShort(week.first), 'Sun');
    });

    test('a Sunday belongs to the week that is about to end, when weeks start on Monday', () {
      expect(Dates.key(Dates.startOfWeek(DateTime(2026, 11, 29), 'mon')), '2026-11-23');
    });

    test('a Sunday starts its own week, when weeks start on Sunday', () {
      expect(Dates.key(Dates.startOfWeek(DateTime(2026, 11, 29), 'sun')), '2026-11-29');
    });

    test('a Monday starts its own week, when weeks start on Monday', () {
      expect(Dates.key(Dates.startOfWeek(DateTime(2026, 11, 23), 'mon')), '2026-11-23');
    });
  });

  group('labels', () {
    test('name today and tomorrow, and nothing further out', () {
      expect(Dates.relative(Dates.today()), 'Today');
      expect(Dates.relative(Dates.tomorrow()), 'Tomorrow');
      expect(Dates.relative(Dates.today().subtract(const Duration(days: 1))), 'Yesterday');
      expect(Dates.relative(Dates.today().add(const Duration(days: 3))), isNull);
    });

    test('read the way the screens show them', () {
      expect(Dates.short(wednesday), 'Wed, Nov 25');
      expect(Dates.long(DateTime(2026, 11, 24)), 'Tuesday, Nov 24');
      expect(Dates.weekday(wednesday), 'Wednesday');
      expect(Dates.month(wednesday), 'November');
      expect(Dates.dayAndMonth(wednesday), 'Nov 25');
      expect(Dates.buttonDay(wednesday), 'Wed 25');
    });
  });

  group('timestamps from the database', () {
    test('are read as UTC and shown in the phone\'s zone', () {
      final parsed = Dates.parseStamp('2026-11-24 18:30:12.345');
      expect(parsed, isNotNull);
      expect(parsed!.toUtc(), DateTime.utc(2026, 11, 24, 18, 30, 12, 345));
      expect(parsed.isUtc, isFalse);
    });

    test('survive a missing or broken one', () {
      expect(Dates.parseStamp(null), isNull);
      expect(Dates.parseStamp(''), isNull);
      expect(Dates.parseStamp('not a date'), isNull);
    });
  });
}
