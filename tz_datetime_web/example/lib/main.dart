import 'package:flutter/widgets.dart';
import 'package:tz_datetime_web/tz_datetime_web.dart';

void main() {
  final zones = TzDatetimeWeb().getAvailableTimezones();
  zones.forEach(debugPrint);

  const zoneId = 'America/Puerto_Rico';
  final offset = TzDatetimeWeb().getOffset(DateTime.now(), zoneId);
  debugPrint('Current UTC offset of $zoneId: $offset');
}
