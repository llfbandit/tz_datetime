import 'package:test/test.dart';
import 'package:tz_datetime/tz_datetime.dart';

void main() {
  final detroit = 'America/Detroit';
  final la = 'America/Los_Angeles';
  final newYork = 'America/New_York';

  group('Helpers', () {
    test('all zones', () {
      final zones = TzDatetime.getAvailableTimezones();
      expect(zones, isNotEmpty);
      expect(zones.length, greaterThan(300));
    });

    test('local', () {
      final paris = 'Europe/Paris';

      expect(local, utc);

      setLocalZone(paris);
      expect(local, paris);
    });

    test('timezone name/offset', () {
      final paris = 'Europe/Paris';

      setLocalZone(paris);
      final dday = TzDatetime.local(1944, DateTime.june, 6);
      expect(dday.timeZoneName, paris);
      expect(dday.timeZoneOffset, Duration(hours: 2));
    });

    test('getOffset', () {
      final summerNy = TzDatetime.getOffset(DateTime.utc(2023, 7, 1), newYork);
      expect(summerNy, equals(const Duration(hours: -4)));
      final winterNy = TzDatetime.getOffset(DateTime.utc(2023, 1, 1), newYork);
      expect(winterNy, equals(const Duration(hours: -5)));
    });

    test('copyWith', () {
      final paris = 'Europe/Paris';

      setLocalZone(paris);
      final dday = TzDatetime.local(1944, DateTime.june, 6);
      expect(dday.timeZoneOffset, Duration(hours: 2));

      expect(
        dday.copyWith(month: DateTime.january).timeZoneOffset,
        Duration(hours: 1),
      );
    });

    test('copyWith preserves omitted fields', () {
      final t = TzDatetime(la, 2010, 6, 15, 12, 30, 45, 100, 200);
      final copy = t.copyWith(year: 2011);
      expect(copy.year, equals(2011));
      expect(copy.month, equals(6));
      expect(copy.day, equals(15));
      expect(copy.hour, equals(12));
      expect(copy.minute, equals(30));
      expect(copy.second, equals(45));
      expect(copy.millisecond, equals(100));
      expect(copy.microsecond, equals(200));
      expect(copy.timeZoneName, equals(la));
    });
  });

  group('Constructors', () {
    test('Default', () {
      final t = TzDatetime(la, 2010, 1, 2, 3, 4, 5, 6, 7);
      expect(t.toString(), equals('2010-01-02 03:04:05.006007-0800'));
    });

    test('Default, only year argument', () {
      final t = TzDatetime(la, 2010);
      expect(t.toString(), equals('2010-01-01 00:00:00.000-0800'));
    });

    test('from DateTime', () {
      final utcTime = DateTime.utc(2010, 1, 2, 3, 4, 5, 6, 7);
      final t = TzDatetime.from(utcTime, newYork);
      expect(t.toString(), equals('2010-01-01 22:04:05.006007-0500'));
    });

    test('from DateTime UTC', () {
      final utcTime = DateTime.utc(2010, 1, 2, 3, 4, 5, 6, 7);
      final t = TzDatetime.from(utcTime, utc);
      expect(t.toString(), equals('2010-01-02 03:04:05.006007Z'));
    });

    test('from local DateTime', () {
      final localTime = DateTime(2010, 1, 2, 3, 4, 5, 6);
      final newYorkTime = TzDatetime.from(localTime, newYork);
      // New York time should be 5 hours behind UTC.
      expect(
        newYorkTime.hour,
        equals(localTime.toUtc().subtract(const Duration(hours: 5)).hour),
      );
    });

    test('from TzDatetime', () {
      final laTime = TzDatetime(la, 2010, 1, 2, 3, 4, 5, 6, 7);
      final t = TzDatetime.from(laTime, newYork);
      expect(t.toString(), equals('2010-01-02 06:04:05.006007-0500'));
    });

    test('fromMilliseconds', () {
      final t = TzDatetime.fromMillisecondsSinceEpoch(newYork, 1262430245006);
      expect(t.toString(), equals('2010-01-02 06:04:05.006-0500'));
    });

    test('fromMicroseconds', () {
      final t = TzDatetime.fromMicrosecondsSinceEpoch(
        newYork,
        1262430245006007,
      );
      expect(t.toString(), equals('2010-01-02 06:04:05.006007-0500'));
    });

    test('utc', () {
      final t = TzDatetime.utc(2010, 1, 2, 3, 4, 5, 6, 7);
      expect(t.toString(), equals('2010-01-02 03:04:05.006007Z'));
    });

    test('local', () {
      setLocalZone('Europe/Paris');
      final t = TzDatetime.local(2010, 1, 2, 3, 4, 5, 6, 7);
      expect(t.toString(), equals('2010-01-02 03:04:05.006007+0100'));
    });

    test('now', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final t = TzDatetime.now(newYork);
      final after = DateTime.now().millisecondsSinceEpoch;
      expect(t.timeZoneName, equals(newYork));
      expect(t.millisecondsSinceEpoch, inInclusiveRange(before, after));
    });

    test('parse UTC string uses from()', () {
      // UTC ISO string → TzDatetime.from path: UTC 03:04 = NY 22:04 (UTC-5)
      final t = TzDatetime.parse('2010-01-02T03:04:05.006007Z', newYork);
      expect(t.toString(), equals('2010-01-01 22:04:05.006007-0500'));
    });

    test('parse non-UTC string uses wall-clock', () {
      // No offset → wall-clock time in given zone
      final t = TzDatetime.parse('2010-01-02T03:04:05.006007', la);
      expect(t.toString(), equals('2010-01-02 03:04:05.006007-0800'));
    });
  });

  group('Properties', () {
    test('individual getters', () {
      // 2010-03-15 is a Monday (weekday 1)
      final t = TzDatetime(la, 2010, 3, 15, 7, 30, 45, 123, 456);
      expect(t.year, equals(2010));
      expect(t.month, equals(3));
      expect(t.day, equals(15));
      expect(t.hour, equals(7));
      expect(t.minute, equals(30));
      expect(t.second, equals(45));
      expect(t.millisecond, equals(123));
      expect(t.microsecond, equals(456));
      expect(t.weekday, equals(DateTime.monday));
    });

    test('microsecondsSinceEpoch consistent with millisecondsSinceEpoch', () {
      final t = TzDatetime(la, 2010, 3, 15, 7, 30, 45, 123, 456);
      expect(
        t.microsecondsSinceEpoch,
        equals(t.millisecondsSinceEpoch * 1000 + 456),
      );
    });

    test('isUtc', () {
      expect(TzDatetime.utc(2010, 1, 1).isUtc, isTrue);
      expect(TzDatetime(la, 2010, 1, 1).isUtc, isFalse);
    });

    test('isLocal', () {
      setLocalZone('Europe/Paris');
      expect(TzDatetime.local(2010, 1, 1).isLocal, isTrue);
      expect(TzDatetime(la, 2010, 1, 1).isLocal, isFalse);
    });
  });

  group('Comparison', () {
    // la midnight = UTC 08:00; ny 03:00 = UTC 08:00 — same UTC instant
    final earlier = TzDatetime(la, 2010, 1, 1, 0); // UTC 2010-01-01 08:00
    final later = TzDatetime(la, 2010, 1, 2, 0); // UTC 2010-01-02 08:00
    final sameUtcInNy = TzDatetime(
      newYork,
      2010,
      1,
      1,
      3,
    ); // UTC 2010-01-01 08:00

    test('isBefore', () {
      expect(earlier.isBefore(later), isTrue);
      expect(later.isBefore(earlier), isFalse);
      expect(earlier.isBefore(sameUtcInNy), isFalse);
    });

    test('isBefore with plain DateTime', () {
      final dtAfter = DateTime.utc(2010, 1, 2, 9);
      final dtBefore = DateTime.utc(2010, 1, 1, 7);
      expect(earlier.isBefore(dtAfter), isTrue);
      expect(earlier.isBefore(dtBefore), isFalse);
    });

    test('isAfter', () {
      expect(later.isAfter(earlier), isTrue);
      expect(earlier.isAfter(later), isFalse);
      expect(earlier.isAfter(sameUtcInNy), isFalse);
    });

    test('isAfter with plain DateTime', () {
      final dtBefore = DateTime.utc(2010, 1, 1, 7);
      final dtAfter = DateTime.utc(2010, 1, 2, 9);
      expect(earlier.isAfter(dtBefore), isTrue);
      expect(earlier.isAfter(dtAfter), isFalse);
    });

    test('isAtSameMomentAs', () {
      expect(earlier.isAtSameMomentAs(sameUtcInNy), isTrue);
      expect(earlier.isAtSameMomentAs(later), isFalse);
    });

    test('isAtSameMomentAs with plain DateTime', () {
      final dtSame = DateTime.utc(2010, 1, 1, 8);
      final dtDiff = DateTime.utc(2010, 1, 2, 8);
      expect(earlier.isAtSameMomentAs(dtSame), isTrue);
      expect(earlier.isAtSameMomentAs(dtDiff), isFalse);
    });

    test('compareTo', () {
      expect(earlier.compareTo(later), isNegative);
      expect(later.compareTo(earlier), isPositive);
      expect(earlier.compareTo(TzDatetime(la, 2010, 1, 1, 0)), isZero);
    });

    test('difference', () {
      expect(later.difference(earlier), equals(const Duration(hours: 24)));
      expect(earlier.difference(later), equals(const Duration(hours: -24)));
    });

    test('difference with plain DateTime', () {
      // later UTC = 2010-01-02 08:00:00Z
      final dtUtc = DateTime.utc(2010, 1, 2, 8);
      expect(earlier.difference(dtUtc), equals(const Duration(hours: -24)));
    });
  });

  group('Equality', () {
    // la 03:00 = UTC 11:00; ny 06:00 = UTC 11:00 — same UTC instant
    final t1 = TzDatetime(la, 2010, 1, 2, 3);
    final t2 = TzDatetime(la, 2010, 1, 2, 3); // same moment, same zone
    final t3 = TzDatetime(
      newYork,
      2010,
      1,
      2,
      6,
    ); // same UTC moment, different zone
    final t4 = TzDatetime(la, 2010, 1, 3, 3); // different moment

    test('TzDatetime == itself (identical)', () {
      expect(t1 == t1, isTrue);
    });

    test('TzDatetime == TzDatetime same moment same zone', () {
      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
    });

    test('TzDatetime == TzDatetime same moment different zone is false', () {
      expect(t1 == t3, isFalse);
    });

    test('TzDatetime == TzDatetime different moment is false', () {
      expect(t1 == t4, isFalse);
    });

    test('TzDatetime == non-DateTime is false', () {
      // ignore: unrelated_type_equality_checks
      expect(t1 == 'not a datetime', isFalse);
    });

    test('UTC TzDatetime == UTC DateTime at same instant', () {
      final tUtc = TzDatetime.utc(2010, 1, 2, 11);
      final dUtc = DateTime.utc(2010, 1, 2, 11);
      expect(tUtc == dUtc, isTrue);
    });

    test('non-UTC TzDatetime == UTC DateTime is false despite same instant', () {
      // t1 (LA) and dtUtc have the same millisecondsSinceEpoch but different isUtc
      final dtUtc = DateTime.utc(2010, 1, 2, 11);
      expect(t1 == dtUtc, isFalse);
    });
  });

  group('Conversions', () {
    test('toUtc', () {
      final t = TzDatetime(la, 2010, 1, 2, 3); // 3am LA (UTC-8) = 11am UTC
      final u = t.toUtc();
      expect(u.isUtc, isTrue);
      expect(u.timeZoneName, equals(utc));
      expect(u.hour, equals(11));
      expect(u.millisecondsSinceEpoch, equals(t.millisecondsSinceEpoch));
    });

    test('toUtc when already UTC returns same', () {
      final u = TzDatetime.utc(2010, 1, 2, 3);
      expect(u.toUtc(), same(u));
    });

    test('toLocal', () {
      setLocalZone('Europe/Paris');
      // 3am LA (UTC-8) = 11am UTC = 12pm Paris (UTC+1 in January)
      final t = TzDatetime(la, 2010, 1, 2, 3);
      final l = t.toLocal();
      expect(l.timeZoneName, equals('Europe/Paris'));
      expect(l.hour, equals(12));
      expect(l.millisecondsSinceEpoch, equals(t.millisecondsSinceEpoch));
    });

    test('toLocal when already local returns same', () {
      setLocalZone('Europe/Paris');
      final l = TzDatetime.local(2010, 1, 2);
      expect(l.toLocal(), same(l));
    });

    test('toIso8601String uses T separator', () {
      final t = TzDatetime(la, 2010, 1, 2, 3, 4, 5, 6, 7);
      expect(t.toIso8601String(), equals('2010-01-02T03:04:05.006007-0800'));
    });

    test('toIso8601String UTC uses Z suffix', () {
      final u = TzDatetime.utc(2010, 1, 2, 3, 4, 5, 6, 7);
      expect(u.toIso8601String(), equals('2010-01-02T03:04:05.006007Z'));
    });

    // fourDigits() year-padding branches (lines not reached by 4-digit years)
    test('toString pads 3-digit year', () {
      expect(TzDatetime.utc(500).toString(), startsWith('0500-'));
    });

    test('toString pads 2-digit year', () {
      expect(TzDatetime.utc(50).toString(), startsWith('0050-'));
    });

    test('toString pads 1-digit year', () {
      expect(TzDatetime.utc(5).toString(), startsWith('0005-'));
    });
  });

  group('Offsets', () {
    group('UTC to America/Detroit', () {
      group('Simple translations', () {
        final u1 = DateTime.utc(1975, 1, 1, 5);
        final x1 = TzDatetime.from(u1, detroit);

        test('$u1 => 1975-01-01 00:00:00.000-0500', () {
          expect(x1.toString(), equals('1975-01-01 00:00:00.000-0500'));
        });

        final u2 = u1.subtract(const Duration(milliseconds: 1));
        final x2 = TzDatetime.from(u2, detroit);

        test('$u2 => 1974-12-31 23:59:59.999-0500', () {
          expect(x2.toString(), equals('1974-12-31 23:59:59.999-0500'));
        });

        final u3 = u1.add(const Duration(milliseconds: 1));
        final x3 = TzDatetime.from(u3, detroit);

        test('$u3 => 1975-01-01 00:00:00.001-0500', () {
          expect(x3.toString(), equals('1975-01-01 00:00:00.001-0500'));
        });
      });

      group('EWT/EPT boundaries', () {
        final u1 = DateTime.utc(1945, 09, 30, 6);
        final x1 = TzDatetime.from(u1, detroit);

        test('$u1 => 1945-09-30 01:00:00.000-0500', () {
          expect(x1.toString(), '1945-09-30 01:00:00.000-0500');
        });

        final u2 = u1.subtract(const Duration(milliseconds: 1));
        final x2 = TzDatetime.from(u2, detroit);

        test('$u2 => 1945-09-30 01:59:59.999-0400', () {
          expect(x2.toString(), equals('1945-09-30 01:59:59.999-0400'));
        });

        final u3 = u1.add(const Duration(milliseconds: 1));
        final x3 = TzDatetime.from(u3, detroit);

        test('$u3 => 1945-09-30 01:00:00.001-0500', () {
          expect(x3.toString(), equals('1945-09-30 01:00:00.001-0500'));
        });
      });
    });

    group('America/Detroit to UTC', () {
      group('EWT/EPT boundaries', () {
        final x1 = TzDatetime(detroit, 1945, 9, 30, 1);
        final u1 = DateTime.fromMillisecondsSinceEpoch(
          x1.millisecondsSinceEpoch,
          isUtc: true,
        );

        test('$x1 => 1945-09-30 05:00:00.000Z', () {
          expect(u1.toString(), '1945-09-30 05:00:00.000Z');
        });

        final x2 = x1.subtract(const Duration(milliseconds: 1));
        final u2 = DateTime.fromMillisecondsSinceEpoch(
          x2.millisecondsSinceEpoch,
          isUtc: true,
        );

        test('$x2 => 1945-09-30 04:59:59.999Z', () {
          expect(u2.toString(), equals('1945-09-30 04:59:59.999Z'));
        });

        final x3 = x1.add(const Duration(milliseconds: 1));
        final u3 = DateTime.fromMillisecondsSinceEpoch(
          x3.millisecondsSinceEpoch,
          isUtc: true,
        );

        test('$x3 => 1945-09-30 05:00:00.001Z', () {
          expect(u3.toString(), equals('1945-09-30 05:00:00.001Z'));
        });

        final x4 = x1.add(const Duration(hours: 1));
        final u4 = DateTime.fromMillisecondsSinceEpoch(
          x4.millisecondsSinceEpoch,
          isUtc: true,
        );

        test('$x4 => 1945-09-30 06:00:00.000Z', () {
          expect(u4.toString(), equals('1945-09-30 06:00:00.000Z'));
        });

        final x5 = x2.add(const Duration(hours: 1));
        final u5 = DateTime.fromMillisecondsSinceEpoch(
          x5.millisecondsSinceEpoch,
          isUtc: true,
        );

        test('$x5 => 1945-09-30 05:59:59.999Z', () {
          expect(u5.toString(), equals('1945-09-30 05:59:59.999Z'));
        });
      });
    });

    group('America/Detroit DST (negative offset)', () {
      // https://www.timeanddate.com/time/change/usa/detroit?year=2023
      group('EST/EDT transition', () {
        test('2 months before transition', () {
          final datetime = TzDatetime(detroit, 2023, 1, 12, 4);
          expect(datetime.toString(), '2023-01-12 04:00:00.000-0500');
        });

        test('1 hour before transition', () {
          final datetime = TzDatetime(detroit, 2023, 3, 12, 1);
          expect(datetime.toString(), '2023-03-12 01:00:00.000-0500');
        });

        test('last millisecond before gap', () {
          final datetime = TzDatetime(detroit, 2023, 3, 12, 1, 59, 59, 999);
          expect(datetime.toString(), '2023-03-12 01:59:59.999-0500');
        });

        test('lower transition', () {
          final datetime = TzDatetime(detroit, 2023, 3, 12, 2);
          expect(datetime.toString(), '2023-03-12 03:00:00.000-0400');
        });

        test('middle of gap snaps to post-gap instant', () {
          final datetime = TzDatetime(detroit, 2023, 3, 12, 2, 30);
          expect(datetime.toString(), '2023-03-12 03:00:00.000-0400');
        });

        test('microseconds preserved when snapping gap', () {
          final datetime = TzDatetime(detroit, 2023, 3, 12, 2, 30, 0, 0, 500);
          expect(datetime.toString(), '2023-03-12 03:00:00.000500-0400');
        });

        test('upper transition', () {
          final datetime = TzDatetime(detroit, 2023, 3, 12, 3);
          expect(datetime.toString(), '2023-03-12 03:00:00.000-0400');
        });

        test('1 hour after transition', () {
          final datetime = TzDatetime(detroit, 2023, 3, 12, 4);
          expect(datetime.toString(), '2023-03-12 04:00:00.000-0400');
        });

        test('2 months after transition', () {
          final datetime = TzDatetime(detroit, 2023, 5, 12, 4);
          expect(datetime.toString(), '2023-05-12 04:00:00.000-0400');
        });
      });

      group('EDT/EST transition', () {
        test('2 months before transition', () {
          final datetime = TzDatetime(detroit, 2023, 9, 5, 1);
          expect(datetime.toString(), '2023-09-05 01:00:00.000-0400');
        });

        test('1 hour before transition', () {
          final datetime = TzDatetime(detroit, 2023, 11, 5);
          expect(datetime.toString(), '2023-11-05 00:00:00.000-0400');
        });

        test('lower transition', () {
          final datetime = TzDatetime(detroit, 2023, 11, 5, 1);
          expect(datetime.toString(), '2023-11-05 01:00:00.000-0400');
        });

        test('upper transition', () {
          final datetime = TzDatetime(detroit, 2023, 11, 5, 2);
          expect(datetime.toString(), '2023-11-05 02:00:00.000-0500');
        });

        test('1 hour after transition', () {
          final datetime = TzDatetime(detroit, 2023, 11, 5, 3);
          expect(datetime.toString(), '2023-11-05 03:00:00.000-0500');
        });

        test('2 months after transition', () {
          final datetime = TzDatetime(detroit, 2024, 1, 5, 2);
          expect(datetime.toString(), '2024-01-05 02:00:00.000-0500');
        });
      });
    });

    group('Europe/Berlin DST (positive offset)', () {
      // https://www.timeanddate.com/time/change/germany/berlin?year=2023
      final berlin = 'Europe/Berlin';

      group('EST/EDT transition', () {
        test('2 months before transition', () {
          final datetime = TzDatetime(berlin, 2023, 1, 26, 2);
          expect(datetime.toString(), '2023-01-26 02:00:00.000+0100');
        });

        test('1 hour before transition', () {
          final datetime = TzDatetime(berlin, 2023, 3, 26, 1);
          expect(datetime.toString(), '2023-03-26 01:00:00.000+0100');
        });

        test('last millisecond before gap', () {
          final datetime = TzDatetime(berlin, 2023, 3, 26, 1, 59, 59, 999);
          expect(datetime.toString(), '2023-03-26 01:59:59.999+0100');
        });

        test('lower transition', () {
          final datetime = TzDatetime(berlin, 2023, 3, 26, 2);
          expect(datetime.toString(), '2023-03-26 03:00:00.000+0200');
        });

        test('middle of gap snaps to post-gap instant', () {
          final datetime = TzDatetime(berlin, 2023, 3, 26, 2, 30);
          expect(datetime.toString(), '2023-03-26 03:00:00.000+0200');
        });

        test('upper transition', () {
          final datetime = TzDatetime(berlin, 2023, 3, 26, 3);
          expect(datetime.toString(), '2023-03-26 03:00:00.000+0200');
        });

        test('1 hour after transition', () {
          final datetime = TzDatetime(berlin, 2023, 3, 26, 4);
          expect(datetime.toString(), '2023-03-26 04:00:00.000+0200');
        });

        test('2 months after transition', () {
          final datetime = TzDatetime(berlin, 2023, 5, 26, 3);
          expect(datetime.toString(), '2023-05-26 03:00:00.000+0200');
        });
      });

      group('EDT/EST transition', () {
        test('2 months before transition', () {
          final datetime = TzDatetime(berlin, 2023, 8, 29, 2);
          expect(datetime.toString(), '2023-08-29 02:00:00.000+0200');
        });

        test('1 hour before transition', () {
          final datetime = TzDatetime(berlin, 2023, 10, 29, 1);
          expect(datetime.toString(), '2023-10-29 01:00:00.000+0200');
        });

        test('lower transition', () {
          final datetime = TzDatetime(berlin, 2023, 10, 29, 2);
          expect(datetime.toString(), '2023-10-29 02:00:00.000+0100');
        });

        test('upper transition', () {
          final datetime = TzDatetime(berlin, 2023, 10, 29, 3);
          expect(datetime.toString(), '2023-10-29 03:00:00.000+0100');
        });

        test('1 hour after transition', () {
          final datetime = TzDatetime(berlin, 2023, 10, 29, 4);
          expect(datetime.toString(), '2023-10-29 04:00:00.000+0100');
        });

        test('2 months after transition', () {
          final datetime = TzDatetime(berlin, 2024, 1, 29, 3);
          expect(datetime.toString(), '2024-01-29 03:00:00.000+0100');
        });
      });
    });

    group('Australia/Lord_Howe DST (positive, non-standard 30-min gap)', () {
      // UTC+10:30 (LHST) / UTC+11:00 (LHDT), 30-minute DST shift.
      final lordHowe = 'Australia/Lord_Howe';

      group('spring-forward gap', () {
        // 2023-10-01: clocks advance 02:00 → 02:30 (+10:30 → +11:00).
        // Gap: 02:00–02:29:59 do not exist.

        test('before gap', () {
          final datetime = TzDatetime(lordHowe, 2023, 10, 1, 1, 59, 59, 999);
          expect(datetime.toString(), '2023-10-01 01:59:59.999+1030');
        });

        test('start of gap snaps to post-gap instant', () {
          final datetime = TzDatetime(lordHowe, 2023, 10, 1, 2, 0);
          expect(datetime.toString(), '2023-10-01 02:30:00.000+1100');
        });

        test('middle of gap snaps to post-gap instant', () {
          final datetime = TzDatetime(lordHowe, 2023, 10, 1, 2, 15);
          expect(datetime.toString(), '2023-10-01 02:30:00.000+1100');
        });

        test('post-gap instant', () {
          final datetime = TzDatetime(lordHowe, 2023, 10, 1, 2, 30);
          expect(datetime.toString(), '2023-10-01 02:30:00.000+1100');
        });

        test('1 hour after transition', () {
          final datetime = TzDatetime(lordHowe, 2023, 10, 1, 3);
          expect(datetime.toString(), '2023-10-01 03:00:00.000+1100');
        });
      });

      group('fall-back overlap', () {
        // 2023-04-02: clocks fall back 02:00 → 01:30 (+11:00 → +10:30).
        // Overlap: 01:30–01:59:59 occur twice.

        test('before overlap (unambiguous LHDT)', () {
          final datetime = TzDatetime(lordHowe, 2023, 4, 2, 1, 15);
          expect(datetime.toString(), '2023-04-02 01:15:00.000+1100');
        });

        test('start of overlap resolves to standard time', () {
          final datetime = TzDatetime(lordHowe, 2023, 4, 2, 1, 30);
          expect(datetime.toString(), '2023-04-02 01:30:00.000+1030');
        });

        test('post fall-back', () {
          final datetime = TzDatetime(lordHowe, 2023, 4, 2, 2, 0);
          expect(datetime.toString(), '2023-04-02 02:00:00.000+1030');
        });
      });
    });
  });
}
