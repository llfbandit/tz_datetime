import 'dart:io';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'tzif.dart';

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
  final _zones = <String, TzifZone>{};

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
    final offsetMs = _zone(zoneId).offsetMsAt(date.millisecondsSinceEpoch);
    return Duration(milliseconds: offsetMs);
  }

  @override
  int localToUtcMicros(int localAsUtcMs, String zoneId, int us) {
    return _zone(zoneId).localToUtcMicros(localAsUtcMs, us);
  }

  TzifZone _zone(String zoneId) => _zones[zoneId] ??= _load(zoneId);

  TzifZone _load(String zoneId) {
    final file = File('$_zoneInfoRoot/$zoneId');
    final valid =
        zoneId.isNotEmpty &&
        !zoneId.startsWith('/') &&
        !zoneId.split('/').contains('..') &&
        file.existsSync();
    final zone = valid ? TzifZone.tryParse(file.readAsBytesSync()) : null;
    if (zone == null) throw LocationNotFoundException(zoneId);
    return zone;
  }
}
