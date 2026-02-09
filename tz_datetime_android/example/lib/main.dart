import 'package:flutter/foundation.dart';
import 'package:tz_datetime_android/tz_datetime_android.dart';

void main() {
  final zones = TzDatetimeAndroid().getAvailableTimezones();
  zones.forEach(debugPrint);

  const zoneId = 'America/Puerto_Rico';
  final offset = TzDatetimeAndroid().getOffset(DateTime.now(), zoneId);
  debugPrint('Current UTC offset of $zoneId: $offset');
}
