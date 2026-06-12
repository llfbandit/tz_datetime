import 'dart:js_interop';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';
import 'package:tz_datetime_web/native/intl.dart';

class TzDatetimeWeb extends TzDatetimePlatform {
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
    final formatter = _makeFormatter(zoneId);

    final parts = formatter
        .formatToParts(date.millisecondsSinceEpoch.toJS)
        .toDart;
    for (final part in parts) {
      if (part.type.toDart == 'timeZoneName') {
        return Duration(milliseconds: _parseOffsetMs(part.value.toDart));
      }
    }
    return Duration.zero;
  }

  @override
  int localToUtcMicros(int localAsUtcMs, String zoneId, int us) {
    final formatter = _makeFormatter(zoneId);

    int offsetMs(int ms) {
      final parts = formatter.formatToParts(ms.toJS).toDart;
      for (final part in parts) {
        if (part.type.toDart == 'timeZoneName') {
          return _parseOffsetMs(part.value.toDart);
        }
      }
      return 0;
    }

    final localOffset = offsetMs(localAsUtcMs);
    final adjustedInstant = localAsUtcMs - localOffset;
    final adjOffset = offsetMs(adjustedInstant);
    var resultMs = localAsUtcMs - adjOffset;

    if (localOffset != adjOffset) {
      if (adjOffset != offsetMs(resultMs)) {
        // Spring-forward gap: binary-search for the first post-gap instant.
        final postGapOffset = localOffset > adjOffset ? localOffset : adjOffset;
        int lo, hi;
        if (adjOffset == postGapOffset) {
          lo = resultMs;
          hi = adjustedInstant;
        } else {
          lo = adjustedInstant;
          hi = resultMs;
        }
        while (hi - lo > 1000) {
          final mid = lo + (hi - lo) ~/ 2;
          if (offsetMs(mid) == postGapOffset) {
            hi = mid;
          } else {
            lo = mid;
          }
        }
        resultMs = hi;
      }
    }

    return Duration(milliseconds: resultMs, microseconds: us).inMicroseconds;
  }
}

DateTimeFormat _makeFormatter(String zoneId) => DateTimeFormat(
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

// Parses a longOffset timeZoneName value ("GMT+HH:MM", "GMT-HH:MM", "GMT", "UTC")
// into milliseconds.
int _parseOffsetMs(String tzName) {
  final plusIdx = tzName.indexOf('+');
  if (plusIdx != -1) return _hhmmToMs(tzName.substring(plusIdx + 1));
  final minusIdx = tzName.indexOf('-');
  if (minusIdx != -1) return -_hhmmToMs(tzName.substring(minusIdx + 1));
  return 0;
}

int _hhmmToMs(String hhmm) {
  final colon = hhmm.indexOf(':');
  return (int.parse(hhmm.substring(0, colon)) * 60 +
          int.parse(hhmm.substring(colon + 1))) *
      60000;
}
