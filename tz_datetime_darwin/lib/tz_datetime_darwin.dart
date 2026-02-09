import 'package:objective_c/objective_c.dart';
import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'package:tz_datetime_darwin/native/tz_datetime_bindings.dart';

class TzDatetimeDarwin extends TzDatetimePlatform {
  static void registerWith() {
    TzDatetimePlatform.instance = TzDatetimeDarwin();
  }

  @override
  List<String> getAvailableTimezones() {
    final zones = NSExtendedTimeZone.getKnownTimeZoneNames();

    final result = <String>[];
    for (var i = 0; i < zones.count; i++) {
      final nsString = zones.objectAtIndex(i) as NSString;
      result.add(nsString.toDartString());
    }
    return result;
  }

  @override
  Duration getOffset(DateTime date, String zoneId) {
    final nsZone = NSTimeZone.timeZoneWithName(zoneId.toNSString());
    if (nsZone == null) {
      throw LocationNotFoundException(zoneId);
    }

    return Duration(seconds: nsZone.secondsFromGMTForDate(date.toNSDate()));
  }
}
