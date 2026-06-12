import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'native/tz_datetime_ffi.dart' as ffi;

class TzDatetimeAndroid extends TzDatetimePlatform {
  @override
  List<String> getAvailableTimezones() => ffi.getTimezones();

  @override
  Duration getOffset(DateTime date, String zoneId) {
    return Duration(
      milliseconds: ffi.getOffsetMs(zoneId, date.millisecondsSinceEpoch),
    );
  }
}
