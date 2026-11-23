/// @docImport 'tz_datetime.dart';
library;

String _local = utc;

/// UTC zone
String get utc => 'UTC';

/// Local zone
///
/// By default, set to [utc]
String get local => _local;

/// Sets the zone used by [TzDatetime.local], [TzDatetime.toLocal] and [TzDatetime.isLocal].
///
/// [zoneId] is not validated.
void setLocalZone(String zoneId) {
  _local = zoneId;
}
