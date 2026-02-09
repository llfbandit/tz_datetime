import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';
import 'package:tz_datetime_web/native/intl.dart';

/// A web implementation of the TzDatetimePlatform of the TzDatetime plugin.
class TzDatetimeWeb extends TzDatetimePlatform {
  /// Constructs a TzDatetimeWeb
  TzDatetimeWeb();

  static void registerWith(Registrar registrar) {
    TzDatetimePlatform.instance = TzDatetimeWeb();
  }

  @override
  List<String> getAvailableTimezones() {
    final timeZones = intl.supportedValuesOf('timeZone'.toJS).toDart;

    final timeZoneList = <String>[];
    for (var i = 0; i < timeZones.length; i++) {
      timeZoneList.add(timeZones[i].toDart);
    }

    return timeZoneList;
  }

  @override
  Duration getOffset(DateTime date, String zoneId) {
    // Create a formatter that will show the timezone offset
    final formatter = DateTimeFormat(
      'en-US'.toJS,
      {
            'timeZone'.toJS: zoneId.toJS,
            'timeZoneName'.toJS: 'longOffset'.toJS,
            'hour'.toJS: '2-digit'.toJS,
            'minute'.toJS: '2-digit'.toJS,
            'hour12'.toJS: false.toJS,
          }.jsify()!
          as JSObject,
    );

    // Format the date to get the timezone offset string
    final formatted = formatter.format(date.millisecondsSinceEpoch.toJS).toDart;

    // Extract the timezone offset from the formatted string
    // The format typically includes the offset like "GMT+05:30" or "UTC+05:30"
    final regex = RegExp(r'(?:GMT|UTC)([+-])(\d{2}):(\d{2})');
    final match = regex.firstMatch(formatted);

    if (match != null) {
      final sign = match.group(1);
      final hours = int.parse(match.group(2)!);
      final minutes = int.parse(match.group(3)!);

      var totalMinutes = hours * 60 + minutes;
      if (sign == '-') {
        totalMinutes = -totalMinutes;
      }

      return Duration(minutes: totalMinutes);
    }

    // If we can't parse the offset from the formatted string, return zero as fallback
    return Duration.zero;
  }
}
