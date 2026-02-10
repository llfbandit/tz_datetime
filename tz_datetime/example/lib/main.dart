import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tz_datetime/tz_datetime.dart';

void main() {
  final la = 'America/Los_Angeles';
  final ny = 'America/New_York';

  // Retrieve all available zones form platform
  final zones = TzDatetime.getAvailableTimezones();
  debugPrint(zones.toString()); // [Africa/Abidjan, Europe/Athens, ...]
  // Get offset from any date with Daylight Saving Times
  Duration offset = TzDatetime.getOffset(DateTime.now(), la);
  debugPrint(offset.toString()); // -8:00:00.000000

  final laTime = TzDatetime.now(la);
  debugPrint(laTime.toString()); // 2026-02-09T03:17:03.964038-0800

  final nyTime = TzDatetime.from(laTime, ny);
  debugPrint(nyTime.toString()); // 2026-02-09T06:17:03.964038-0500

  if (!kIsWeb) {
    exit(0);
  }
}
