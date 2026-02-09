import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tz_datetime_linux/tz_datetime_linux.dart';

void main() {
  final zones = TzDatetimeLinux().getAvailableTimezones();
  zones.forEach(debugPrint);

  const zoneId = 'America/Puerto_Rico';
  final offset = TzDatetimeLinux().getOffset(DateTime.now(), zoneId);
  debugPrint('Current UTC offset of $zoneId: $offset');

  exit(0);
}
