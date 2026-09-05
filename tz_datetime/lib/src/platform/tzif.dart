import 'dart:convert';
import 'dart:typed_data';

/// Time zone rules parsed from TZif data (RFC 8536).
class TzifZone {
  TzifZone._(this._transitions, this._offsets, this._initialOffset, this._rule);

  // Transition instants in UTC seconds, ascending.
  final Int64List _transitions;
  // Offset in seconds in effect from each transition.
  final Int32List _offsets;
  // Offset in seconds before the first transition.
  final int _initialOffset;
  // Footer rule for instants after the last transition.
  final _PosixRule? _rule;

  /// Fixed UTC zone, used when no zone file is installed.
  static final utc = TzifZone._(Int64List(0), Int32List(0), 0, null);

  /// Parses [bytes], or returns null if they are not valid TZif data.
  static TzifZone? tryParse(Uint8List bytes) {
    try {
      return _parse(ByteData.sublistView(bytes));
    } on RangeError {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Returns the UTC offset in milliseconds at [utcMs].
  int offsetMsAt(int utcMs) {
    final t = (utcMs - utcMs % 1000) ~/ 1000;
    final n = _transitions.length;
    final rule = _rule;

    if (rule != null && (n == 0 || t >= _transitions[n - 1])) {
      return rule.offsetAt(t) * 1000;
    }
    if (n == 0 || t < _transitions[0]) return _initialOffset * 1000;

    var lo = 0, hi = n - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_transitions[mid] <= t) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return _offsets[lo] * 1000;
  }

  /// Converts wall-clock [localAsUtcMs] to UTC microseconds.
  int localToUtcMicros(int localAsUtcMs, int us) {
    final localOffset = offsetMsAt(localAsUtcMs);
    final adjustedInstant = localAsUtcMs - localOffset;
    final adjOffset = offsetMsAt(adjustedInstant);
    var resultMs = localAsUtcMs - adjOffset;

    if (localOffset != adjOffset && adjOffset != offsetMsAt(resultMs)) {
      // Spring-forward gap: binary-search for the first post-gap instant.
      final postGapOffset = localOffset > adjOffset ? localOffset : adjOffset;
      var lo = adjOffset == postGapOffset ? resultMs : adjustedInstant;
      var hi = adjOffset == postGapOffset ? adjustedInstant : resultMs;
      while (hi - lo > 1) {
        final mid = lo + (hi - lo) ~/ 2;
        if (offsetMsAt(mid) == postGapOffset) {
          hi = mid;
        } else {
          lo = mid;
        }
      }
      resultMs = hi;
    }

    return resultMs * 1000 + us;
  }

  static TzifZone? _parse(ByteData data) {
    if (!_hasMagic(data, 0)) return null;

    var header = _Header(data, 0);
    var pos = _Header.size;
    var timeSize = 4;

    // Version 2+ repeats the data with 64-bit times, followed by a footer.
    if (data.getUint8(4) >= 0x32) {
      pos += header.dataLength(timeSize);
      if (!_hasMagic(data, pos)) return null;
      header = _Header(data, pos);
      pos += _Header.size;
      timeSize = 8;
    }
    if (header.typecnt == 0) return null;
    // Check counts before allocating from them.
    if (pos + header.dataLength(timeSize) > data.lengthInBytes) return null;
    // Leap-second zones (right/) use a different time scale.
    if (header.leapcnt > 0) return null;

    final transitions = Int64List(header.timecnt);
    for (var i = 0; i < header.timecnt; i++) {
      transitions[i] = timeSize == 8
          ? data.getInt64(pos + i * 8)
          : data.getInt32(pos + i * 4);
    }
    pos += header.timecnt * timeSize;

    final indicesPos = pos;
    pos += header.timecnt;

    final typeOffsets = Int32List(header.typecnt);
    for (var i = 0; i < header.typecnt; i++) {
      typeOffsets[i] = data.getInt32(pos + i * 6);
    }
    pos +=
        header.typecnt * 6 +
        header.charcnt +
        header.leapcnt * (timeSize + 4) +
        header.isstdcnt +
        header.isutcnt;

    final offsets = Int32List(header.timecnt);
    for (var i = 0; i < header.timecnt; i++) {
      final index = data.getUint8(indicesPos + i);
      if (index >= header.typecnt) return null;
      offsets[i] = typeOffsets[index];
    }

    _PosixRule? rule;
    if (timeSize == 8 &&
        pos < data.lengthInBytes &&
        data.getUint8(pos) == 0x0A) {
      final bytes = Uint8List.sublistView(data, pos + 1);
      final end = bytes.indexOf(0x0A);
      if (end < 0) return null;
      if (end > 0) {
        // Reject the zone rather than drop DST rules after the last transition.
        rule = _PosixRule.tryParse(ascii.decode(bytes.sublist(0, end)));
        if (rule == null) return null;
      }
    }

    return TzifZone._(transitions, offsets, typeOffsets[0], rule);
  }

  static bool _hasMagic(ByteData data, int pos) =>
      data.getUint32(pos) == 0x545A6966; // "TZif"
}

class _Header {
  static const size = 44;

  _Header(ByteData data, int pos)
    : isutcnt = data.getUint32(pos + 20),
      isstdcnt = data.getUint32(pos + 24),
      leapcnt = data.getUint32(pos + 28),
      timecnt = data.getUint32(pos + 32),
      typecnt = data.getUint32(pos + 36),
      charcnt = data.getUint32(pos + 40);

  final int isutcnt, isstdcnt, leapcnt, timecnt, typecnt, charcnt;

  int dataLength(int timeSize) =>
      timecnt * (timeSize + 1) +
      typecnt * 6 +
      charcnt +
      leapcnt * (timeSize + 4) +
      isstdcnt +
      isutcnt;
}

/// POSIX TZ rule such as `CET-1CEST,M3.5.0,M10.5.0/3`.
class _PosixRule {
  _PosixRule(this.std, this.dst, this.start, this.end);

  // Offsets in seconds east of UTC.
  final int std;
  final int? dst;
  final _RuleDate? start, end;

  static const _name = r'(?:[A-Za-z]{3,}|<[+\-0-9A-Za-z]+>)';
  static const _time = r'([+-]?\d{1,3}(?::\d{1,2}){0,2})';
  static const _date = '(J\\d{1,3}|\\d{1,3}|M\\d{1,2}\\.\\d\\.\\d)(?:/$_time)?';
  static final _regex = RegExp(
    '^$_name$_time(?:($_name)$_time?(?:,$_date,$_date)?)?\$',
  );

  static _PosixRule? tryParse(String value) {
    final m = _regex.firstMatch(value);
    if (m == null) return null;

    final std = -_seconds(m[1]!);
    if (m[2] == null) return _PosixRule(std, null, null, null);

    final dst = m[3] != null ? -_seconds(m[3]!) : std + 3600;
    // POSIX default when the rule part is omitted.
    final start = _RuleDate.parse(m[4] ?? 'M3.2.0', m[5]);
    final end = _RuleDate.parse(m[6] ?? 'M11.1.0', m[7]);
    if (start == null || end == null) return null;

    return _PosixRule(std, dst, start, end);
  }

  int offsetAt(int t) {
    final dst = this.dst;
    if (dst == null) return std;

    final year = DateTime.fromMillisecondsSinceEpoch(
      (t + std) * 1000,
      isUtc: true,
    ).year;
    final startUtc = start!.localSeconds(year) - std;
    final endUtc = end!.localSeconds(year) - dst;

    final inDst = startUtc < endUtc
        ? t >= startUtc && t < endUtc
        : !(t >= endUtc && t < startUtc);
    return inDst ? dst : std;
  }

  static int _seconds(String value) {
    final negative = value.startsWith('-');
    final parts = value.replaceFirst(RegExp('^[+-]'), '').split(':');
    var seconds = 0;
    for (var i = 0; i < 3; i++) {
      seconds = seconds * 60 + (i < parts.length ? int.parse(parts[i]) : 0);
    }
    return negative ? -seconds : seconds;
  }
}

/// Transition date of a POSIX TZ rule, in local wall-clock time.
class _RuleDate {
  _RuleDate._(this.kind, this.a, this.b, this.c, this.time);

  final String kind;
  final int a, b, c;
  final int time;

  static _RuleDate? parse(String date, String? time) {
    final seconds = time != null ? _PosixRule._seconds(time) : 7200;
    if (date.startsWith('J')) {
      final day = int.parse(date.substring(1));
      if (day < 1 || day > 365) return null;
      return _RuleDate._('J', day, 0, 0, seconds);
    }
    if (date.startsWith('M')) {
      final p = date.substring(1).split('.').map(int.parse).toList();
      if (p[0] < 1 || p[0] > 12 || p[1] < 1 || p[1] > 5 || p[2] > 6) {
        return null;
      }
      return _RuleDate._('M', p[0], p[1], p[2], seconds);
    }
    final day = int.parse(date);
    if (day > 365) return null;
    return _RuleDate._('n', day, 0, 0, seconds);
  }

  /// Returns the transition as seconds since epoch in local time for [year].
  int localSeconds(int year) {
    final DateTime day;
    switch (kind) {
      case 'J':
        // 1-based day of year, never counting February 29.
        final leap = DateTime.utc(year, 3, 0).day == 29;
        day = DateTime.utc(year, 1, a + (leap && a >= 60 ? 1 : 0));
      case 'n':
        day = DateTime.utc(year, 1, a + 1);
      default:
        // Day c (0 = Sunday) of week b (5 = last) of month a.
        final first = DateTime.utc(year, a, 1);
        final daysInMonth = DateTime.utc(year, a + 1, 0).day;
        var dayOfMonth = 1 + (c - first.weekday % 7 + 7) % 7 + (b - 1) * 7;
        if (dayOfMonth > daysInMonth) dayOfMonth -= 7;
        day = DateTime.utc(year, a, dayOfMonth);
    }
    return day.millisecondsSinceEpoch ~/ 1000 + time;
  }
}
