import '../tz_datetime_platform.dart';

import 'icu.dart' as icu;

class TzDatetimeWindows extends TzDatetimePlatform {
  @override
  List<String> listTimezones() => icu.getAvailableTimezones();

  @override
  Duration getOffset(DateTime date, String zoneId) {
    return icu.getOffset(zoneId, date.millisecondsSinceEpoch);
  }
}
