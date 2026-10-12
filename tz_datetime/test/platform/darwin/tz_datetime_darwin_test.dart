@TestOn('mac-os')
library;

import 'package:test/test.dart';
import 'package:tz_datetime/src/platform/darwin/tz_datetime_darwin.dart';
import 'package:tz_datetime/tz_datetime.dart';

void main() {
  final darwin = TzDatetimeDarwin();

  test('accepts custom offset IDs', () {
    expect(
      darwin.getOffset(DateTime.utc(2023), 'GMT+05:00'),
      const Duration(hours: 5),
    );
    expect(
      darwin.getOffset(DateTime.utc(2023), 'GMT-0330'),
      const Duration(hours: -3, minutes: -30),
    );
  });

  test('keeps zone files over abbreviations', () {
    // With abbreviations, CoreFoundation would map EST to America/New_York.
    expect(
      darwin.getOffset(DateTime.utc(2023, 7), 'EST'),
      const Duration(hours: -5),
    );
    expect(
      () => darwin.getOffset(DateTime.utc(2023), 'PDT'),
      throwsA(isA<LocationNotFoundException>()),
    );
  });

  test('returns local mean time offsets with seconds', () {
    expect(
      darwin.getOffset(DateTime.utc(1890), 'Europe/Paris'),
      const Duration(minutes: 9, seconds: 21),
    );
  });

  test('rejects miscased and placeholder IDs', () {
    for (final id in ['europe/paris', 'Etc/Unknown']) {
      expect(
        () => darwin.getOffset(DateTime.utc(2023), id),
        throwsA(isA<LocationNotFoundException>()),
        reason: id,
      );
    }
  });
}
