abstract class TzDatetimePlatform {
  static final Object _token = Object();
  final Object? _instanceToken;

  TzDatetimePlatform() : _instanceToken = _token;

  static TzDatetimePlatform _instance = _TzDatetimePlatformStub();

  static TzDatetimePlatform get instance => _instance;

  static set instance(TzDatetimePlatform instance) {
    if (!identical(instance._instanceToken, _token)) {
      throw AssertionError(
        'TzDatetimePlatform must be extended, not implemented.',
      );
    }
    _instance = instance;
  }

  List<String> getAvailableTimezones() {
    throw UnimplementedError(
      'getAvailableTimezones() has not been implemented.',
    );
  }

  Duration getOffset(DateTime date, String zoneId) {
    throw UnimplementedError('getOffset() has not been implemented.');
  }

  /// Converts a wall-clock time to UTC microseconds since epoch for [zoneId].
  ///
  /// Uses the offset in effect before a transition, like Python's `fold=0`:
  /// a repeated time resolves to the earlier instant, and a skipped time
  /// shifts forward by the gap length.
  ///
  /// [localAsUtcMs] is `DateTime.utc(year, month, ...).millisecondsSinceEpoch`
  /// (wall-clock components treated as UTC). [us] is the microsecond component.
  int localToUtcMicros(int localAsUtcMs, String zoneId, int us) {
    int offsetMs(int utcMs) => getOffset(
      DateTime.fromMillisecondsSinceEpoch(utcMs, isUtc: true),
      zoneId,
    ).inMilliseconds;

    // A day away is past any transition near this wall-clock time.
    const day = 86400000;
    final before = offsetMs(localAsUtcMs - day);
    final after = offsetMs(localAsUtcMs + day);

    var resultMs = localAsUtcMs - before;
    if (before != after && offsetMs(resultMs) != before) {
      final later = localAsUtcMs - after;
      // Neither offset fits in a gap, so keep the pre-gap one.
      if (offsetMs(later) == after) resultMs = later;
    }
    return resultMs * 1000 + us;
  }
}

class _TzDatetimePlatformStub extends TzDatetimePlatform {}
