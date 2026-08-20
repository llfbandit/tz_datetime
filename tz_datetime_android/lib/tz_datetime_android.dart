import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';
import 'package:tz_datetime_platform_interface/tzif.dart';

import 'src/tzdata.dart';

class TzDatetimeAndroid extends TzDatetimePlatform {
  late final _tzdata = Tzdata.open();
  final _zones = <String, TzifZone>{};

  @override
  List<String> getAvailableTimezones() => _tzdata.ids.toList();

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
    final bytes = _tzdata.read(zoneId);
    final zone = bytes != null ? TzifZone.tryParse(bytes) : null;
    if (zone == null) throw LocationNotFoundException(zoneId);
    return zone;
  }
}
