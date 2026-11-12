import '../tz_datetime_platform.dart';

import 'cf.dart' as cf;

class TzDatetimeDarwin extends TzDatetimePlatform {
  @override
  List<String> listTimezones() => cf.getAvailableTimezones();

  @override
  Duration getOffset(DateTime date, String zoneId) {
    return cf.getOffset(zoneId, date.millisecondsSinceEpoch);
  }
}
