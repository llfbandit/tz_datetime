import 'dart:io';
import 'dart:typed_data';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import '../tzif/tzif_platform.dart';

// Fallbacks after TZDIR; NixOS uses /etc/zoneinfo.
const _defaultRoots = ['/usr/share/zoneinfo', '/etc/zoneinfo'];

// Subdirectories that duplicate the main zone set and should be excluded.
const _skipTopDirs = {'posix', 'right'};

// TZif files that are not zones.
const _skipFiles = {'localtime', 'posixrules'};

// Linux errno values for a path component or target that is not a file.
const _enotdir = 20, _eisdir = 21;

/// Returns the zoneinfo directory, honouring TZDIR like glibc.
String resolveZoneInfoRoot(Map<String, String> environment) {
  // Like glibc, a set TZDIR is used even if missing, without falling back.
  final tzdir = environment['TZDIR'] ?? '';
  if (tzdir.isNotEmpty) return _trimSlash(tzdir);
  for (final root in _defaultRoots) {
    if (Directory(root).existsSync()) return root;
  }
  return _defaultRoots.first;
}

class TzDatetimeLinux extends TzifPlatform {
  TzDatetimeLinux([String? root])
    : _root = _trimSlash(root ?? resolveZoneInfoRoot(Platform.environment));

  final String _root;

  // The root with one trailing slash, also when it is '/'.
  late final _prefix = _root.endsWith('/') ? _root : '$_root/';
  late final _zoneIds = _listZones();

  @override
  List<String> getAvailableTimezones() => List.of(_zoneIds);

  List<String> _listZones() {
    final dir = Directory(_root);
    if (!dir.existsSync()) {
      throw TimeZoneInitException('tzdata not found at $_root');
    }

    final result = <String>[];
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is Directory) continue;
      final rel = entity.path.substring(_prefix.length);
      final top = rel.contains('/') ? rel.substring(0, rel.indexOf('/')) : rel;
      // Check names first; opening every file is the slow part.
      if (_skipTopDirs.contains(top) || _skipFiles.contains(rel)) continue;
      if (_isTzif(entity.path)) result.add(rel);
    }
    return result..sort();
  }

  @override
  Uint8List? readZone(String zoneId) {
    final parts = zoneId.split('/');
    // Accept only the IDs getAvailableTimezones lists.
    if (parts.any((p) => p.isEmpty || p == '.' || p == '..') ||
        _skipTopDirs.contains(parts.first) ||
        _skipFiles.contains(zoneId)) {
      return null;
    }

    final Uint8List bytes;
    try {
      bytes = File('$_prefix$zoneId').readAsBytesSync();
    } on FileSystemException catch (e) {
      if (!Directory(_root).existsSync()) {
        throw TimeZoneInitException('tzdata not found at $_root');
      }
      // Missing files and directories are unknown zones; other errors are I/O.
      final code = e.osError?.errorCode;
      if (e is PathNotFoundException || code == _enotdir || code == _eisdir) {
        return null;
      }
      rethrow;
    }
    return _hasTzifMagic(bytes) ? bytes : null;
  }
}

// Zone files, and symlinked aliases such as UTC, start with the TZif magic.
bool _isTzif(String path) {
  try {
    final file = File(path).openSync();
    try {
      return _hasTzifMagic(file.readSync(4));
    } finally {
      file.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}

bool _hasTzifMagic(Uint8List bytes) =>
    bytes.length >= 4 && String.fromCharCodes(bytes, 0, 4) == 'TZif';

String _trimSlash(String path) => path.length > 1 && path.endsWith('/')
    ? path.substring(0, path.length - 1)
    : path;
