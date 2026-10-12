import 'dart:js_interop';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'intl.dart';

class TzDatetimeWeb extends TzDatetimePlatform {
  // Caches one formatter per zone, as creating one is costly.
  final _formatters = <String, DateTimeFormat>{};

  @override
  List<String> getAvailableTimezones() {
    final JSArray<JSString> zones;
    try {
      zones = intl.supportedValuesOf('timeZone'.toJS);
    } catch (_) {
      throw TimeZoneInitException('Intl.supportedValuesOf is not supported');
    }
    return [for (final zone in zones.toDart) zone.toDart];
  }

  @override
  Duration getOffset(DateTime date, String zoneId) {
    final offsetMs = _offsetMsAt(
      _formatter(zoneId),
      date.millisecondsSinceEpoch,
    );
    return Duration(milliseconds: offsetMs);
  }

  DateTimeFormat _formatter(String zoneId) =>
      _formatters[zoneId] ??= _makeFormatter(zoneId);

  DateTimeFormat _makeFormatter(String zoneId) {
    try {
      return _newFormatter(zoneId);
    } catch (_) {
      // Intl throws a RangeError for unknown zones and for options it lacks.
      if (!_intlSupported) {
        throw TimeZoneInitException('Intl longOffset names are not supported');
      }
      throw LocationNotFoundException(zoneId);
    }
  }

  // Probes with UTC, which every Intl implementation knows.
  late final bool _intlSupported = () {
    try {
      _newFormatter('UTC');
      return true;
    } catch (_) {
      return false;
    }
  }();
}

DateTimeFormat _newFormatter(String zoneId) => DateTimeFormat(
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

// Offset in ms of the formatter's zone at [utcMs].
int _offsetMsAt(DateTimeFormat formatter, int utcMs) {
  for (final part in formatter.formatToParts(utcMs.toJS).toDart) {
    if (part.type.toDart == 'timeZoneName') {
      return _parseOffsetMs(part.value.toDart);
    }
  }
  throw TimeZoneInitException('Intl returned no timeZoneName part');
}

// Matches the signed H:MM[:SS] part of a longOffset value.
final _offsetPattern = RegExp(r'([+\-−])(\d{1,2}):(\d{2})(?::(\d{2}))?$');

// Parses a longOffset value such as "GMT", "GMT+05:30" or "GMT-00:44:30".
int _parseOffsetMs(String value) {
  if (value == 'GMT' || value == 'UTC') return 0;
  final match = _offsetPattern.firstMatch(value);
  if (match == null) {
    throw TimeZoneInitException('Unexpected Intl offset "$value"');
  }

  final seconds =
      (int.parse(match[2]!) * 60 + int.parse(match[3]!)) * 60 +
      int.parse(match[4] ?? '0');
  return (match[1] == '+' ? seconds : -seconds) * 1000;
}
