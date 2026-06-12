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
}

class _TzDatetimePlatformStub extends TzDatetimePlatform {}
