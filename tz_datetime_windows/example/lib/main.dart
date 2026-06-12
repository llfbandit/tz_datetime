import 'dart:io';

import 'package:tz_datetime_windows/tz_datetime_windows.dart';

void main() {
  final zones = TzDatetimeWindows().getAvailableTimezones();
  zones.forEach(print);

  const zoneId = 'America/Puerto_Rico';
  final offset = TzDatetimeWindows().getOffset(DateTime.now(), zoneId);
  print('Current UTC offset of $zoneId: $offset');

  exit(0);
}
