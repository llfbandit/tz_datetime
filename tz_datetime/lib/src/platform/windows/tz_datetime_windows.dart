import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'icu.dart' as icu;

class TzDatetimeWindows extends TzDatetimePlatform {
  late final _zoneIds = icu.getAvailableTimezones();

  @override
  List<String> getAvailableTimezones() => List.of(_zoneIds);

  @override
  Duration getOffset(DateTime date, String zoneId) {
    return icu.getOffset(zoneId, date.millisecondsSinceEpoch);
  }
}
