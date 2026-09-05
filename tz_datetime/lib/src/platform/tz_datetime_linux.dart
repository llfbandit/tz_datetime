import 'dart:io';
import 'dart:typed_data';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'tzif_platform.dart';

const _zoneInfoRoot = '/usr/share/zoneinfo';

// Subdirectories that duplicate the main zone set and should be excluded.
const _skipTopDirs = {'posix', 'right'};

// TZif files that are not zones.
const _skipFiles = {'localtime', 'posixrules'};

class TzDatetimeLinux extends TzifPlatform {
  late final _zoneIds = _listZones();

  @override
  List<String> getAvailableTimezones() => List.of(_zoneIds);

  List<String> _listZones() {
    final dir = Directory(_zoneInfoRoot);
    if (!dir.existsSync()) {
      throw TimeZoneInitException('tzdata not found at $_zoneInfoRoot');
    }

    final result = <String>[];
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is Directory) continue;
      final rel = entity.path.substring(_zoneInfoRoot.length + 1);
      final top = rel.contains('/') ? rel.substring(0, rel.indexOf('/')) : rel;
      // Check names first; opening every file is the slow part.
      if (_skipTopDirs.contains(top) || _skipFiles.contains(rel)) continue;
      if (_isTzif(entity.path)) result.add(rel);
    }
    return result..sort();
  }

  @override
  Uint8List? readZone(String zoneId) {
    final path = '$_zoneInfoRoot/$zoneId';
    final valid =
        zoneId.isNotEmpty &&
        !zoneId.startsWith('/') &&
        !zoneId.split('/').contains('..') &&
        _isTzif(path);
    return valid ? File(path).readAsBytesSync() : null;
  }
}

// Zone files, and symlinked aliases such as UTC, start with the TZif magic.
bool _isTzif(String path) {
  try {
    final file = File(path).openSync();
    try {
      return String.fromCharCodes(file.readSync(4)) == 'TZif';
    } finally {
      file.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}
