import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';
import 'package:tz_datetime_web/tz_datetime_web.dart';

import 'register.dart';

void register() {
  if (registered) return;

  TzDatetimePlatform.instance = TzDatetimeWeb();

  registered = true;
}
