import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

class TzDatetime implements DateTime {
  /// Gets all available zones from the platform.
  static List<String> getAvailableTimezones() {
    return TzDatetimePlatform.instance.getAvailableTimezones();
  }

  /// Gets the current offset from the given [date].
  static Duration getOffset(DateTime date, String zoneId) {
    return TzDatetimePlatform.instance.getOffset(date, zoneId);
  }

  /// Constructs a new [TzDatetime] instance based on [isoDate].
  ///
  /// Throws a [FormatException] if the input cannot be parsed.
  ///
  /// The function parses a subset of ISO 8601
  /// which includes the subset accepted by RFC 3339.
  ///
  /// The result is always in the time zone of the provided location.
  static TzDatetime parse(String isoDate, String zoneId) {
    return TzDatetime.from(DateTime.parse(isoDate), zoneId);
  }

  /// Returns the native [DateTime] object.
  static DateTime _toNative(DateTime t) => t is TzDatetime ? t._utcDatetime : t;

  static const _utc = 'UTC';

  /// Converts a [_localDateTime] into a correct [DateTime].
  static DateTime _utcFromLocalDateTime(DateTime local, String zoneId) {
    int getOffsetMillis(int millisSinceEpoch) {
      return getOffset(
        DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch, isUtc: true),
        zoneId,
      ).inMilliseconds;
    }

    // Adapted from https://github.com/JodaOrg/joda-time/blob/main/src/main/java/org/joda/time/DateTimeZone.java#L951
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

  /// Constructs a [TZDateTime] instance specified at [location] time zone.
  ///
  /// For example,
  /// to create a new TZDateTime object representing April 29, 2014, 6:04am
  /// in America/Detroit:
  ///
  /// ```dart
  /// final detroit = getLocation('America/Detroit');
  ///
  /// final annularEclipse = TZDateTime(location,
  ///     2014, DateTime.APRIL, 29, 6, 4);
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

  /// Constructs a [TZDateTime] instance specified in the UTC time zone.
  ///
  /// ```dart
  /// final dDay = TZDateTime.utc(1944, TZDateTime.JUNE, 6);
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
         _utc,
         year,
         month,
         day,
         hour,
         minute,
         second,
         millisecond,
         microsecond,
       );

  /// Constructs a [TZDateTime] instance with current date and time in the
  /// [location] time zone.
  ///
  /// ```dart
  /// final detroit = getLocation('America/Detroit');
  ///
  /// final thisInstant = TZDateTime.now(detroit);
  /// ```
  TzDatetime.now(String zoneId) : this.from(DateTime.now(), zoneId);

  /// Constructs a new [TZDateTime] instance with the given
  /// [millisecondsSinceEpoch].
  ///
  /// The constructed [TZDateTime] represents
  /// 1970-01-01T00:00:00Z + [millisecondsSinceEpoch] ms in the given
  /// time zone [location].
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

  /// Time zone name
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

  /// Returns a [Duration] with the difference between `this` and [other].
  @override
  Duration difference(DateTime other) {
    return _utcDatetime.difference(_toNative(other));
  }

  /// Returns true if `this` occurs before [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in other
  /// time zone.
  @override
  bool isBefore(DateTime other) => _utcDatetime.isBefore(_toNative(other));

  /// Returns true if `this` occurs after [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in other
  /// time zone.
  @override
  bool isAfter(DateTime other) => _utcDatetime.isAfter(_toNative(other));

  /// Returns true if `this` occurs at the same moment as [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in other
  /// time zone.
  @override
  bool isAtSameMomentAs(DateTime other) {
    return _utcDatetime.isAtSameMomentAs(_toNative(other));
  }

  /// Compares this [TzDatetime] object to [other],
  /// returning zero if the values occur at the same moment.
  ///
  /// This function returns a negative integer
  /// if this [TzDatetime] is smaller (earlier) than [other],
  /// or a positive integer if it is greater (later).
  @override
  int compareTo(DateTime other) => _utcDatetime.compareTo(_toNative(other));

  /// Returns an ISO-8601 full-precision extended format representation.
  ///
  /// The format is yyyy-MM-ddTHH:mm:ss.mmmuuuZ for UTC time, and
  /// yyyy-MM-ddTHH:mm:ss.mmmuuu±hhmm for local/non-UTC time.
  @override
  String toIso8601String() => toString();

  /// Returns this DateTime value in the local time zone.
  ///
  /// Returns `this` if it is already in the local time zone.
  @override
  TzDatetime toLocal() => isUtc ? TzDatetime.from(_utcDatetime, _zoneId) : this;

  /// Returns this DateTime value in the UTC time zone.
  ///
  /// Returns `this` if it is already in UTC.
  @override
  TzDatetime toUtc() => isUtc ? this : TzDatetime.from(_utcDatetime, _utc);

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
  bool get isUtc => _offset.compareTo(Duration.zero) == 0;

  @override
  String get timeZoneName => _zoneId;

  @override
  Duration get timeZoneOffset => _offset;

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
  String toString() {
    final y = _fourDigits(year);
    final m = _twoDigits(month);
    final d = _twoDigits(day);
    final sep = 'T';
    final h = _twoDigits(hour);
    final min = _twoDigits(minute);
    final sec = _twoDigits(second);
    final ms = _threeDigits(millisecond);
    final us = microsecond == 0 ? '' : _threeDigits(microsecond);

    if (isUtc) {
      return '$y-$m-$d$sep$h:$min:$sec.$ms${us}Z';
    } else {
      final offSign = _offset.isNegative ? '-' : '+';
      final offsetSeconds = _offset.abs().inSeconds;
      final offH = _twoDigits(offsetSeconds ~/ 3600);
      final offM = _twoDigits((offsetSeconds % 3600) ~/ 60);

      return '$y-$m-$d$sep$h:$min:$sec.$ms$us$offSign$offH$offM';
    }
  }

  static String _fourDigits(int n) {
    final absN = n.abs();
    final sign = n < 0 ? '-' : '';
    if (absN >= 1000) return '$n';
    if (absN >= 100) return '${sign}0$absN';
    if (absN >= 10) return '${sign}00$absN';
    return '${sign}000$absN';
  }

  static String _threeDigits(int n) {
    if (n >= 100) return '$n';
    if (n >= 10) return '0$n';
    return '00$n';
  }

  static String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }
}
