String _local = utc;

/// UTC zone
String get utc => 'UTC';

/// Local zone
///
/// By default, set to [utc]
String get local => _local;

/// Set global local [zoneId] for further usage.
void setLocalZone(String zoneId) {
  _local = zoneId;
}
