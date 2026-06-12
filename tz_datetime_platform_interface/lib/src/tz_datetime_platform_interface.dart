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

  /// Converts a wall-clock time to UTC microseconds since epoch for [zoneId],
  /// handling DST spring-forward gaps natively.
  ///
  /// [localAsUtcMs] is `DateTime.utc(year, month, ...).millisecondsSinceEpoch`
  /// (wall-clock components treated as UTC). [us] is the microsecond component.
  int localToUtcMicros(int localAsUtcMs, String zoneId, int us) {
    throw UnimplementedError('localToUtcMicros() has not been implemented.');
  }
}

class _TzDatetimePlatformStub extends TzDatetimePlatform {}
