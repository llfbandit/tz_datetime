@TestOn('linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:tz_datetime/src/platform/tz_datetime_linux.dart';
import 'package:tz_datetime/tz_datetime.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('zoneinfo_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('resolveZoneInfoRoot', () {
    test('uses TZDIR', () {
      expect(resolveZoneInfoRoot({'TZDIR': dir.path}), dir.path);
      expect(resolveZoneInfoRoot({'TZDIR': '${dir.path}/'}), dir.path);
    });

    test('keeps a missing TZDIR', () {
      final missing = '${dir.path}/missing';
      expect(resolveZoneInfoRoot({'TZDIR': missing}), missing);
      expect(
        () => TzDatetimeLinux(missing).getAvailableTimezones(),
        throwsA(isA<TimeZoneInitException>()),
      );
    });

    test('falls back when TZDIR is unset or empty', () {
      for (final env in [
        <String, String>{},
        {'TZDIR': ''},
      ]) {
        expect(resolveZoneInfoRoot(env), '/usr/share/zoneinfo');
      }
    });
  });

  test('reads zones from a custom root', () {
    Directory('${dir.path}/Europe').createSync();
    File(
      '/usr/share/zoneinfo/Europe/Paris',
    ).copySync('${dir.path}/Europe/Paris');
    Link('${dir.path}/Alias').createSync('Europe/Paris');
    Link('${dir.path}/Folder').createSync('Europe');
    File('${dir.path}/zone.tab').writeAsStringSync('');
    File('${dir.path}/SECURITY').writeAsStringSync('');
    File('${dir.path}/Bad').writeAsStringSync('TZif');

    final linux = TzDatetimeLinux('${dir.path}/');

    expect(linux.getAvailableTimezones(), ['Alias', 'Bad', 'Europe/Paris']);
    linux.getAvailableTimezones().clear();
    expect(linux.getAvailableTimezones(), hasLength(3));
    expect(
      linux.getOffset(DateTime.utc(2023, 7), 'Alias'),
      const Duration(hours: 2),
    );
    expect(
      () => linux.getOffset(DateTime.utc(2023), 'Asia/Tokyo'),
      throwsA(isA<LocationNotFoundException>()),
    );
    expect(
      () => linux.getOffset(DateTime.utc(2023), 'zone.tab'),
      throwsA(isA<LocationNotFoundException>()),
    );
    expect(
      () => linux.getOffset(DateTime.utc(2023), 'Bad'),
      throwsA(isA<TimeZoneInitException>()),
    );
  });

  test('rejects zone IDs that are not listed', () {
    const paris = '/usr/share/zoneinfo/Europe/Paris';
    for (final sub in ['Europe', 'posix/Europe', 'right/Europe']) {
      Directory('${dir.path}/$sub').createSync(recursive: true);
      File(paris).copySync('${dir.path}/$sub/Paris');
    }
    File(paris).copySync('${dir.path}/posixrules');
    File(paris).copySync('${dir.path}/localtime');

    final linux = TzDatetimeLinux(dir.path);

    expect(linux.getAvailableTimezones(), ['Europe/Paris']);
    for (final id in [
      'posix/Europe/Paris',
      'right/Europe/Paris',
      'posixrules',
      'localtime',
      './Europe/Paris',
      'Europe/./Paris',
      'Europe//Paris',
      'Europe/Paris/',
      '/Europe/Paris',
      '',
    ]) {
      expect(
        () => linux.getOffset(DateTime.utc(2023), id),
        throwsA(isA<LocationNotFoundException>()),
        reason: id,
      );
    }
  });

  test(
    'reports unreadable zones as I/O errors',
    () {
      Directory('${dir.path}/Europe').createSync();
      final paris = '${dir.path}/Europe/Paris';
      File('/usr/share/zoneinfo/Europe/Paris').copySync(paris);
      Process.runSync('chmod', ['000', paris]);
      addTearDown(() => Process.runSync('chmod', ['644', paris]));

      final linux = TzDatetimeLinux(dir.path);

      expect(
        () => linux.getOffset(DateTime.utc(2023), 'Europe/Paris'),
        throwsA(isA<TimeZoneInitException>()),
      );
      for (final id in ['Europe', 'Europe/Paris/Extra']) {
        expect(
          () => linux.getOffset(DateTime.utc(2023), id),
          throwsA(isA<LocationNotFoundException>()),
          reason: id,
        );
      }
    },
    skip: Platform.environment['USER'] == 'root' ? 'root reads any file' : null,
  );

  test('reports a missing root, keeping UTC', () {
    final linux = TzDatetimeLinux('${dir.path}/missing');

    expect(
      () => linux.getOffset(DateTime.utc(2023), 'Europe/Paris'),
      throwsA(isA<TimeZoneInitException>()),
    );
    expect(linux.getOffset(DateTime.utc(2023), 'UTC'), Duration.zero);
  });

  test('keeps UTC without zone files', () {
    final linux = TzDatetimeLinux(dir.path);

    for (final id in ['UTC', 'Etc/UTC', 'GMT', 'Etc/GMT']) {
      expect(linux.getOffset(DateTime.utc(2023), id), Duration.zero);
    }
    expect(
      () => linux.getOffset(DateTime.utc(2023), 'Europe/Paris'),
      throwsA(isA<LocationNotFoundException>()),
    );
  });
}
