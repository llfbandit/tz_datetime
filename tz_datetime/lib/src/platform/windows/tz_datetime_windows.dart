import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'icu.dart' as icu;

class TzDatetimeWindows extends TzDatetimePlatform {
  late final _zones = getAvailableTimezones().toSet();

  @override
  List<String> getAvailableTimezones() => icu.getAvailableTimezones();

  @override
  Duration getOffset(DateTime date, String zoneId) {
    _checkZone(zoneId);
    return icu.getOffset(zoneId, date.millisecondsSinceEpoch);
  }

  @override
  int localToUtcMicros(int localAsUtcMs, String zoneId, int us) {
    _checkZone(zoneId);
    return icu.localToUtcMicros(zoneId, localAsUtcMs, us);
  }

  // ICU silently falls back to GMT for unknown zones.
  void _checkZone(String zoneId) {
    if (!_zones.contains(zoneId)) throw LocationNotFoundException(zoneId);
  }
}
