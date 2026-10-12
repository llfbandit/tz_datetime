import '../platform/tz_datetime_platform.dart';

import '../platform/web/tz_datetime_web.dart';
import 'register.dart';

void register() {
  if (registered) return;

  TzDatetimePlatform.instance = TzDatetimeWeb();

  registered = true;
}
