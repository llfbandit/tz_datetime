import '../tz_datetime_platform.dart';

import 'cf.dart' as cf;

class TzDatetimeDarwin extends TzDatetimePlatform {
  late final _zoneIds = cf.getAvailableTimezones();

  @override
  List<String> getAvailableTimezones() => List.of(_zoneIds);

  @override
  Duration getOffset(DateTime date, String zoneId) {
    return cf.getOffset(zoneId, date.millisecondsSinceEpoch);
  }
}
