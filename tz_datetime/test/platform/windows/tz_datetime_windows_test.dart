@TestOn('windows')
library;

import 'package:test/test.dart';
import 'package:tz_datetime/src/platform/windows/tz_datetime_windows.dart';
import 'package:tz_datetime/tz_datetime.dart';

void main() {
  final windows = TzDatetimeWindows();

  test('accepts custom offset IDs', () {
    expect(
      windows.getOffset(DateTime.utc(2023), 'GMT+05:00'),
      const Duration(hours: 5),
    );
    expect(
      windows.getOffset(DateTime.utc(2023), 'GMT-0330'),
      const Duration(hours: -3, minutes: -30),
    );
  });

  test('rejects unknown and empty IDs', () {
    for (final id in ['Europe/Pariss', 'Etc/Unknown', '']) {
      expect(
        () => windows.getOffset(DateTime.utc(2023), id),
        throwsA(isA<LocationNotFoundException>()),
        reason: id,
      );
    }
  });

  test('returns a copy of the zone list', () {
    final count = windows.getAvailableTimezones().length;
    windows.getAvailableTimezones().clear();
    expect(windows.getAvailableTimezones(), hasLength(count));
  });
}
