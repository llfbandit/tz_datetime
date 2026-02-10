import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'env.dart';
import 'register/register.dart';

class TzDatetime implements DateTime {
  /// Gets all platform available zones.
  static List<String> getAvailableTimezones() {
    register();
    return TzDatetimePlatform.instance.getAvailableTimezones();
  }

  /// Gets the time zone offset for given [date],
  /// adjusted with daylight savings.
  static Duration getOffset(DateTime date, String zoneId) {
    register();
    return TzDatetimePlatform.instance.getOffset(date, zoneId);
  }

  /// Constructs a new [TzDatetime] instance based on [isoDate].
  ///
  /// Throws a [FormatException] if the input cannot be parsed.
  ///
  /// The function parses a subset of ISO 8601
  /// which includes the subset accepted by RFC 3339.
  ///
  /// The result is always in the time zone of the provided [zoneId].
  static TzDatetime parse(String isoDate, String zoneId) {
    return TzDatetime.from(DateTime.parse(isoDate), zoneId);
  }

  /// Constructs a [TzDatetime] instance specified at [zoneId].
  ///
  /// For example,
  /// to create a new TzDatetime object representing April 29, 2014, 6:04am
  /// in America/Puerto_Rico:
  ///
  /// ```dart
  /// TzDatetime('America/Puerto_Rico', 2014, DateTime.april, 29, 6, 4);
  /// ```
  TzDatetime(
    String zoneId,
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) : this.from(
         _utcFromLocalDateTime(
           DateTime.utc(
             year,
             month,
             day,
             hour,
             minute,
             second,
             millisecond,
             microsecond,
           ),
           zoneId,
         ),
         zoneId,
       );

  /// Constructs a [TzDatetime] instance specified in the UTC time zone.
  ///
  /// ```dart
  /// final dDay = TzDatetime.utc(1944, DateTime.june, 6);
  /// ```
  TzDatetime.utc(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) : this(
         utc,
         year,
         month,
         day,
         hour,
         minute,
         second,
         millisecond,
         microsecond,
       );

  /// Constructs a [TzDatetime] instance specified in the local time zone.
  ///
  /// ```dart
  /// setLocalZone('Europe/Paris'); // local is now globally set.
  /// final dDay = TzDatetime.local(1944, DateTime.june, 6);
  /// ```
  TzDatetime.local(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) : this(
         local,
         year,
         month,
         day,
         hour,
         minute,
         second,
         millisecond,
         microsecond,
       );

  /// Constructs a [TzDatetime] instance with current date and time in the
  /// [zoneId].
  ///
  /// ```dart
  /// final thisInstant = TzDatetime.now('America/Puerto_Rico');
  /// ```
  TzDatetime.now(String zoneId) : this.from(DateTime.now(), zoneId);

  /// Constructs a new [TzDatetime] instance with the given
  /// [millisecondsSinceEpoch].
  ///
  /// The constructed [TzDatetime] represents
  /// 1970-01-01T00:00:00Z + [millisecondsSinceEpoch] ms in the given
  /// time zone [zoneId].
  TzDatetime.fromMillisecondsSinceEpoch(
    String zoneId,
    int millisecondsSinceEpoch,
  ) : this.from(
        DateTime.fromMillisecondsSinceEpoch(
          millisecondsSinceEpoch,
          isUtc: true,
        ),
        zoneId,
      );

  TzDatetime.fromMicrosecondsSinceEpoch(
    String zoneId,
    int microsecondsSinceEpoch,
  ) : this.from(
        DateTime.fromMicrosecondsSinceEpoch(
          microsecondsSinceEpoch,
          isUtc: true,
        ),
        zoneId,
      );

  TzDatetime.from(DateTime other, String zoneId)
    : this._(_toNative(other).toUtc(), zoneId, getOffset(other, zoneId));

  TzDatetime._(this._utcDatetime, this._zoneId, this._offset)
    : _localDatetime = _utcDatetime.add(_offset);

  /// Time zone identifier.
  final String _zoneId;

  /// UTC representation.
  final DateTime _utcDatetime;

  /// Local representation.
  final DateTime _localDatetime;

  /// Gap between [_localDatetime] and [_utcDatetime]
  final Duration _offset;

  @override
  TzDatetime add(Duration duration) {
    return TzDatetime.from(_utcDatetime.add(duration), _zoneId);
  }

  @override
  TzDatetime subtract(Duration duration) {
    return TzDatetime.from(_utcDatetime.subtract(duration), _zoneId);
  }

  @override
  Duration difference(DateTime other) {
    return _utcDatetime.difference(_toNative(other));
  }

  @override
  bool isBefore(DateTime other) => _utcDatetime.isBefore(_toNative(other));

  @override
  bool isAfter(DateTime other) => _utcDatetime.isAfter(_toNative(other));

  @override
  bool isAtSameMomentAs(DateTime other) {
    return _utcDatetime.isAtSameMomentAs(_toNative(other));
  }

  @override
  int compareTo(DateTime other) => _utcDatetime.compareTo(_toNative(other));

  /// Returns an ISO-8601 full-precision extended format representation.
  ///
  /// The format is yyyy-MM-ddTHH:mm:ss.mmmuuuZ for UTC time, and
  /// yyyy-MM-ddTHH:mm:ss.mmmuuu±hhmm for local/non-UTC time.
  @override
  String toIso8601String() => _toString(iso8601: true);

  /// Returns this DateTime value in the local time zone.
  ///
  /// Returns `this` if it is already in the local time zone.
  @override
  TzDatetime toLocal() =>
      isLocal ? this : TzDatetime.from(_utcDatetime, _zoneId);

  /// Returns this DateTime value in the UTC time zone.
  ///
  /// Returns `this` if it is already in UTC.
  @override
  TzDatetime toUtc() => isUtc ? this : TzDatetime.from(_utcDatetime, utc);

  @override
  int get day => _localDatetime.day;

  @override
  int get hour => _localDatetime.hour;

  @override
  int get microsecond => _localDatetime.microsecond;

  @override
  int get microsecondsSinceEpoch => _utcDatetime.microsecondsSinceEpoch;

  @override
  int get millisecond => _localDatetime.millisecond;

  @override
  int get millisecondsSinceEpoch => _utcDatetime.millisecondsSinceEpoch;

  @override
  int get minute => _localDatetime.minute;

  @override
  int get month => _localDatetime.month;

  @override
  int get second => _localDatetime.second;

  @override
  int get weekday => _localDatetime.weekday;

  @override
  int get year => _localDatetime.year;

  @override
  bool get isUtc => identical(_zoneId, utc);

  bool get isLocal => identical(_zoneId, local);

  @override
  String get timeZoneName => _zoneId;

  @override
  Duration get timeZoneOffset => _offset;

  /// Creates a new [TzDatetime] from this one by updating individual properties.
  TzDatetime copyWith({
    String? zoneId,
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return TzDatetime(
      zoneId ?? _zoneId,
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }

  /// Returns true if [other] is a [TzDatetime] at the same moment and in the
  /// same zone ID.
  ///
  /// See [isAtSameMomentAs] for a comparison that adjusts for time zone.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TzDatetime &&
            _utcDatetime.isAtSameMomentAs(other._utcDatetime) &&
            _zoneId == other._zoneId;
  }

  @override
  int get hashCode => _utcDatetime.hashCode;

  @override
  String toString() => _toString(iso8601: false);

  String _toString({bool iso8601 = true}) {
    String fourDigits(int n) {
      final absN = n.abs();
      final sign = n < 0 ? '-' : '';
      if (absN >= 1000) return '$n';
      if (absN >= 100) return '${sign}0$absN';
      if (absN >= 10) return '${sign}00$absN';
      return '${sign}000$absN';
    }

    String threeDigits(int n) {
      if (n >= 100) return '$n';
      if (n >= 10) return '0$n';
      return '00$n';
    }

    String twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    final y = fourDigits(year);
    final m = twoDigits(month);
    final d = twoDigits(day);
    final sep = iso8601 ? 'T' : ' ';
    final h = twoDigits(hour);
    final min = twoDigits(minute);
    final sec = twoDigits(second);
    final ms = threeDigits(millisecond);
    final us = microsecond == 0 ? '' : threeDigits(microsecond);

    if (isUtc) {
      return '$y-$m-$d$sep$h:$min:$sec.$ms${us}Z';
    } else {
      final offSign = _offset.isNegative ? '-' : '+';
      final offsetSeconds = _offset.abs().inSeconds;
      final offH = twoDigits(offsetSeconds ~/ 3600);
      final offM = twoDigits((offsetSeconds % 3600) ~/ 60);

      return '$y-$m-$d$sep$h:$min:$sec.$ms$us$offSign$offH$offM';
    }
  }

  /// Returns the native [DateTime] object.
  static DateTime _toNative(DateTime t) => t is TzDatetime ? t._utcDatetime : t;

  /// Converts a [_localDateTime] into a correct [DateTime].
  static DateTime _utcFromLocalDateTime(DateTime local, String zoneId) {
    int getOffsetMillis(int millisSinceEpoch) {
      return getOffset(
        DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch, isUtc: true),
        zoneId,
      ).inMilliseconds;
    }

    // Get the offset at local (first estimate).
    final localInstant = local.millisecondsSinceEpoch;
    final localOffset = getOffsetMillis(local.millisecondsSinceEpoch);

    // Adjust localInstant using the estimate and recalculate the offset.
    final adjustedInstant = localInstant - localOffset;
    final adjustedOffset = getOffsetMillis(adjustedInstant);

    var milliseconds = localInstant - adjustedOffset;

    // If the offsets differ, we must be near a DST boundary
    if (localOffset != adjustedOffset) {
      // We need to ensure that time is always after the DST gap
      // this happens naturally for positive offsets, but not for negative.
      // If we just use adjustedOffset then the time is pushed back before the
      // transition, whereas it should be on or after the transition
      if (localOffset - adjustedOffset < 0 &&
          adjustedOffset != getOffsetMillis(localInstant - adjustedOffset)) {
        milliseconds = adjustedInstant;
      }
    }

    // Ensure original microseconds are preserved regardless of TZ shift.
    final microsecondsSinceEpoch = Duration(
      milliseconds: milliseconds,
      microseconds: local.microsecond,
    ).inMicroseconds;

    return DateTime.fromMicrosecondsSinceEpoch(
      microsecondsSinceEpoch,
      isUtc: true,
    );
  }
}
