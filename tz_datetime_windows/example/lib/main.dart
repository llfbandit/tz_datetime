import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tz_datetime_windows/tz_datetime_windows.dart';

void main() {
  final zones = TzDatetimeWindows().getAvailableTimezones();
  zones.forEach(debugPrint);

  const zoneId = 'America/Puerto_Rico';
  final offset = TzDatetimeWindows().getOffset(DateTime.now(), zoneId);
  debugPrint('Current UTC offset of $zoneId: $offset');
  exit(0);
}
