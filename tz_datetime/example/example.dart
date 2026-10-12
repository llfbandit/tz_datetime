import 'package:tz_datetime/tz_datetime.dart';

void main() {
  final la = 'America/Los_Angeles';
  final ny = 'America/New_York';

  // Retrieve all available zones from the platform
  final zones = TzDatetime.getAvailableTimezones();
  print(zones); // [Africa/Abidjan, Europe/Athens, ...]

  // Get offset from any date with Daylight Saving Times
  final offset = TzDatetime.getOffset(DateTime.now(), la);
  print(offset); // -8:00:00.000000

  final laTime = TzDatetime.now(la);
  print(laTime); // 2026-02-09T03:17:03.964038-0800

  final nyTime = TzDatetime.from(laTime, ny);
  print(nyTime); // 2026-02-09T06:17:03.964038-0500
}
