import 'dart:io';

import 'package:tz_datetime_linux/tz_datetime_linux.dart';

void main() {
  final zones = TzDatetimeLinux().getAvailableTimezones();
  zones.forEach(print);

  const zoneId = 'America/Puerto_Rico';
  final offset = TzDatetimeLinux().getOffset(DateTime.now(), zoneId);
  print('Current UTC offset of $zoneId: $offset');

  exit(0);
}
