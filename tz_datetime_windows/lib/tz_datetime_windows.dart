import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'src/icu.dart' as icu;

class TzDatetimeWindows extends TzDatetimePlatform {
  @override
  List<String> getAvailableTimezones() => icu.getAvailableTimezones();

  @override
  Duration getOffset(DateTime date, String zoneId) {
    return icu.getOffset(zoneId, date.millisecondsSinceEpoch);
  }

  @override
  int localToUtcMicros(int localAsUtcMs, String zoneId, int us) {
    return icu.localToUtcMicros(zoneId, localAsUtcMs, us);
  }
}
