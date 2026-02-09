import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

class TzDatetimeDarwin extends TzDatetimePlatform {
  static void registerWith() {
    TzDatetimePlatform.instance = TzDatetimeDarwin();
  }

  @override
  List<String> getAvailableTimezones() {
    return [];
  }

  @override
  Duration getOffset(DateTime date, String zoneId) {
    return Duration.zero;
  }
}
