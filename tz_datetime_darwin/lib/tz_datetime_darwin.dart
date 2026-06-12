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

    NSDate msToNSDate(int ms) =>
        DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toNSDate();

    int offsetMs(int ms) =>
        nsZone.secondsFromGMTForDate(msToNSDate(ms)) * 1000;

    final localOffset = offsetMs(localAsUtcMs);
    final adjustedInstant = localAsUtcMs - localOffset;
    final adjOffset = offsetMs(adjustedInstant);
    var resultMs = localAsUtcMs - adjOffset;

    if (localOffset != adjOffset) {
      if (adjOffset != offsetMs(resultMs)) {
        // Spring-forward gap: ask NSTimeZone for the exact transition instant
        // instead of binary-searching.
        final postGapOffset = localOffset > adjOffset ? localOffset : adjOffset;
        final loMs = adjOffset == postGapOffset ? resultMs : adjustedInstant;
        final transition = nsZone.nextDaylightSavingTimeTransitionAfterDate(
          msToNSDate(loMs),
        );
        if (transition != null) {
          resultMs = transition.toDateTime().millisecondsSinceEpoch;
        }
      }
    }

    return Duration(milliseconds: resultMs, microseconds: us).inMicroseconds;
  }
}
