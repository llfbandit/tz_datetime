import 'package:jni/jni.dart';
import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'native/tz_datetime_bindings.dart';

class TzDatetimeAndroid extends TzDatetimePlatform {
  static void registerWith() {
    TzDatetimePlatform.instance = TzDatetimeAndroid();
  }

  @override
  List<String> getAvailableTimezones() {
    if (TzDatetime.getAvailableTimezones() case final zones?) {
      final result = zones
          .where((z) => z != null)
          .map((z) => z!.toDartString())
          .toList();

      zones.release();

      return result;
    }

    return <String>[];
  }

  @override
  Duration getOffset(DateTime date, String zoneId) {
    return Duration(
      milliseconds: TzDatetime.getOffset(
        zoneId.toJString(),
        date.millisecondsSinceEpoch,
      ),
    );
  }
}
