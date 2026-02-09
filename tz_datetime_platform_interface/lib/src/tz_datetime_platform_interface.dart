import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class TzDatetimePlatform extends PlatformInterface {
  /// Constructs a TzDatetimePlatform.
  TzDatetimePlatform() : super(token: _token);

  static final Object _token = Object();

  static TzDatetimePlatform _instance = _TzDatetimePlatformStub();

  /// The default instance of [TzDatetimePlatform] to use.
  static TzDatetimePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TzDatetimePlatform] when
  /// they register themselves.
  static set instance(TzDatetimePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Gets all available zones from the platform.
  List<String> getAvailableTimezones() {
    throw UnimplementedError(
      'getAvailableTimezones() has not been implemented.',
    );
  }

  /// Gets the current offset from the given [date] and zone identifier.
  Duration getOffset(DateTime date, String zoneId) {
    throw UnimplementedError('getOffset() has not been implemented.');
  }
}

/// A stub implementation of the TzDatetimePlatform interface.
///
class _TzDatetimePlatformStub extends TzDatetimePlatform {}
