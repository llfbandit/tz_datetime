import 'package:objective_c/objective_c.dart';
import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'package:tz_datetime_darwin/native/tz_datetime_bindings.dart';

class TzDatetimeDarwin extends TzDatetimePlatform {
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

  @override
  int localToUtcMicros(int localAsUtcMs, String zoneId, int us) {
    final nsZone = NSTimeZone.timeZoneWithName(zoneId.toNSString());
    if (nsZone == null) throw LocationNotFoundException(zoneId);

    // Calls secondsFromGMTForDate: directly on the cached nsZone, avoiding
    // repeated NSTimeZone.timeZoneWithName: lookups the Dart fallback would make.
    int offsetMs(int ms) {
      return nsZone.secondsFromGMTForDate(
            DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toNSDate(),
          ) *
          1000;
    }

    final localOffset = offsetMs(localAsUtcMs);
    final adjustedInstant = localAsUtcMs - localOffset;
    final adjOffset = offsetMs(adjustedInstant);
    var resultMs = localAsUtcMs - adjOffset;

    if (localOffset != adjOffset) {
      if (adjOffset != offsetMs(resultMs)) {
        // Spring-forward gap: binary-search for the first post-gap instant.
        final postGapOffset =
            localOffset > adjOffset ? localOffset : adjOffset;
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
