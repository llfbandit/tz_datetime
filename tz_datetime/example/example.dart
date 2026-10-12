import 'package:tz_datetime/tz_datetime.dart';

void main() {
  final la = 'America/Los_Angeles';
  final ny = 'America/New_York';

  // Retrieve all available zones from the platform
  final zones = TzDatetime.getAvailableTimezones();
  print(zones); // [Africa/Abidjan, Europe/Athens, ...]

  final laTime = TzDatetime(la, 2026, 2, 9, 3, 17, 3, 964, 38);
  print(laTime); // 2026-02-09 03:17:03.964038-0800

  // Get offset from any date with Daylight Saving Times
  final offset = TzDatetime.getOffset(laTime, la);
  print(offset); // -8:00:00.000000

  final nyTime = TzDatetime.from(laTime, ny);
  print(nyTime); // 2026-02-09 06:17:03.964038-0500

  // Current date time in `la` zone
  print(TzDatetime.now(la));
}
