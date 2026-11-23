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

  late final List<String> _zoneIds = listTimezones();

  /// Returns a copy of the zone list, which is read once per instance.
  List<String> getAvailableTimezones() => List.of(_zoneIds);

  /// Reads the zone IDs; [getAvailableTimezones] caches the result.
  List<String> listTimezones() {
    throw UnimplementedError('listTimezones() has not been implemented.');
  }

  Duration getOffset(DateTime date, String zoneId) {
    throw UnimplementedError('getOffset() has not been implemented.');
  }

  /// Resolves a wall-clock time in [zoneId] to a UTC instant and its offset.
  ///
  /// Uses the offset in effect before a transition, like Python's `fold=0`:
  /// a repeated time resolves to the earlier instant, and a skipped time
  /// shifts forward by the gap length.
  ///
  /// [localAsUtcMs] is `DateTime.utc(year, month, ...).millisecondsSinceEpoch`
  /// (wall-clock components treated as UTC).
  ({int utcMs, Duration offset}) localToUtc(int localAsUtcMs, String zoneId) {
    Duration offsetAt(int utcMs) => getOffset(
      // Clamp into the DateTime range; no zone has transitions there.
      DateTime.fromMillisecondsSinceEpoch(
        utcMs.clamp(-_maxMs, _maxMs),
        isUtc: true,
      ),
      zoneId,
    );

    // A day away is past any transition near this wall-clock time.
    const day = 86400000;
    final before = offsetAt(localAsUtcMs - day);
    final earlier = localAsUtcMs - before.inMilliseconds;
    final earlierOffset = offsetAt(earlier);
    if (earlierOffset == before) return (utcMs: earlier, offset: before);

    final after = offsetAt(localAsUtcMs + day);
    if (after != before) {
      final later = localAsUtcMs - after.inMilliseconds;
      if (offsetAt(later) == after) return (utcMs: later, offset: after);
    }
    // Skipped time: take the pre-gap instant, which lands after the gap.
    return (utcMs: earlier, offset: earlierOffset);
  }

  /// Largest millisecondsSinceEpoch a [DateTime] accepts.
  static const _maxMs = 8640000000000000;
}

class _TzDatetimePlatformStub extends TzDatetimePlatform {}
