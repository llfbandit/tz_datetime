import 'dart:typed_data';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';
import 'package:tz_datetime_windows/data/data.dart';
import 'package:tz_datetime_windows/src/location.dart';
import 'package:tz_datetime_windows/src/location_database.dart';
import 'package:tz_datetime_windows/src/tzdb.dart';

class TzDatetimeWindows extends TzDatetimePlatform {
  static void registerWith() {
    TzDatetimePlatform.instance = TzDatetimeWindows();
  }

  LocationDatabase? _db;

  @override
  List<String> getAvailableTimezones() {
    _initializeDatabase();

    return _db!.locations.keys.toList(growable: false);
  }

  @override
  Duration getOffset(DateTime date, String zoneId) {
    _initializeDatabase();

    final location = _db!.get(zoneId);
    final timeZone = location.timeZone(date.millisecondsSinceEpoch);

    return timeZone.offset;
  }

  /// Initialize Time zone database.
  void _initializeDatabase() {
    if (_db != null) return;

    final db = LocationDatabase();

    try {
      final rawData = Uint8List.fromList(embeddedData.codeUnits);

      for (final l in tzdbDeserialize(rawData)) {
        db.add(l);
      }

      db.add(Location('UTC', [minTime], [0], [TimeZone.UTC]));
    } catch (e) {
      throw TimeZoneInitException(e.toString());
    }

    _db = db;
  }
}
