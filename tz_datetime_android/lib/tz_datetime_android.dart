import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'native/tz_datetime_ffi.dart' as ffi;

class TzDatetimeAndroid extends TzDatetimePlatform {
  late final _zones = getAvailableTimezones().toSet();

  @override
  List<String> getAvailableTimezones() => ffi.getTimezones();

  @override
  Duration getOffset(DateTime date, String zoneId) {
    _checkZone(zoneId);
    return Duration(
      milliseconds: ffi.getOffsetMs(zoneId, date.millisecondsSinceEpoch),
    );
  }

  @override
  int localToUtcMicros(int localAsUtcMs, String zoneId, int us) {
    _checkZone(zoneId);
    return ffi.localToUtcMicros(localAsUtcMs, zoneId, us);
  }

  // Bionic silently falls back to GMT for unknown zones.
  void _checkZone(String zoneId) {
    if (!_zones.contains(zoneId)) throw LocationNotFoundException(zoneId);
  }
}
