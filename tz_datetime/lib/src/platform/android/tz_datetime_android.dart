import 'dart:typed_data';

import '../tzif/tzif_platform.dart';
import 'tzdata.dart';

class TzDatetimeAndroid extends TzifPlatform {
  late final _tzdata = Tzdata.open();

  @override
  List<String> listTimezones() => _tzdata.ids.toList()..sort();

  @override
  Uint8List? readZone(String zoneId) => _tzdata.read(zoneId);
}
