import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tz_datetime_darwin/tz_datetime_darwin.dart';

void main() {
  final zones = TzDatetimeDarwin().getAvailableTimezones();
  zones.forEach(debugPrint);

  const zoneId = 'America/Puerto_Rico';
  final offset = TzDatetimeDarwin().getOffset(DateTime.now(), zoneId);
  debugPrint('Current UTC offset of $zoneId: $offset');

  exit(0);
}
