import 'dart:io';
import 'dart:typed_data';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'tzif.dart';

/// Platform backed by TZif data read from the system.
abstract class TzifPlatform extends TzDatetimePlatform {
  final _zones = <String, TzifZone>{};

  /// Returns the TZif data of [zoneId], or null if it is unknown.
  Uint8List? readZone(String zoneId);

  @override
  Duration getOffset(DateTime date, String zoneId) {
    final offsetMs = _zone(zoneId).offsetMsAt(date.millisecondsSinceEpoch);
    return Duration(milliseconds: offsetMs);
  }

  TzifZone _zone(String zoneId) => _zones[zoneId] ??= _load(zoneId);

  TzifZone _load(String zoneId) {
    final Uint8List? bytes;
    try {
      bytes = readZone(zoneId);
    } on FileSystemException catch (e) {
      throw TimeZoneInitException('Cannot read $zoneId: ${e.message}');
    } on TimeZoneInitException {
      if (_utcIds.contains(zoneId)) return TzifZone.utc;
      rethrow;
    }

    if (bytes == null) {
      if (_utcIds.contains(zoneId)) return TzifZone.utc;
      throw LocationNotFoundException(zoneId);
    }
    return TzifZone.tryParse(bytes) ??
        (throw TimeZoneInitException('Unsupported TZif data for $zoneId'));
  }
}

// Usable without any zone file installed.
const _utcIds = {'UTC', 'Etc/UTC', 'GMT', 'Etc/GMT'};
