import 'dart:io';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'native/tz_datetime_ffi.dart' as ffi;

const _zoneInfoRoot = '/usr/share/zoneinfo';

// Subdirectories that duplicate the main zone set and should be excluded.
const _skipTopDirs = {'posix', 'right'};

// Non-timezone files present in the zoneinfo directory.
const _skipFiles = {
  '+VERSION',
  'iso3166.tab',
  'leap-seconds.list',
  'leapseconds',
  'localtime',
  'posixrules',
  'tzdata.zi',
  'stzdata.zi',
  'zone.tab',
  'zone1970.tab',
  'zonenow.tab',
};

class TzDatetimeLinux extends TzDatetimePlatform {
  @override
  List<String> getAvailableTimezones() {
    final dir = Directory(_zoneInfoRoot);
    if (!dir.existsSync()) {
      throw TimeZoneInitException('tzdata not found at $_zoneInfoRoot');
    }

    final result = <String>[];
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = entity.path.substring(_zoneInfoRoot.length + 1);
      final top = rel.contains('/') ? rel.substring(0, rel.indexOf('/')) : rel;
      if (_skipTopDirs.contains(top) || _skipFiles.contains(rel)) continue;
      result.add(rel);
    }
    return result..sort();
  }

  @override
  Duration getOffset(DateTime date, String zoneId) {
    return Duration(
      milliseconds: ffi.getOffsetMs(zoneId, date.millisecondsSinceEpoch),
    );
  }

  @override
  int localToUtcMicros(int localAsUtcMs, String zoneId, int us) {
    return ffi.localToUtcMicros(localAsUtcMs, zoneId, us);
  }
}
