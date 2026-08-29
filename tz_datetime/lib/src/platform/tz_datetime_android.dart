import 'dart:typed_data';

import 'tzdata.dart';
import 'tzif_platform.dart';

class TzDatetimeAndroid extends TzifPlatform {
  late final _tzdata = Tzdata.open();
  late final _zoneIds = _tzdata.ids.toList()..sort();

  @override
  List<String> getAvailableTimezones() => List.of(_zoneIds);

  @override
  Uint8List? readZone(String zoneId) => _tzdata.read(zoneId);
}
