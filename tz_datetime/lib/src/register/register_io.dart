import 'dart:io';

import '../platform/tz_datetime_platform.dart';

import '../platform/android/tz_datetime_android.dart';
import '../platform/darwin/tz_datetime_darwin.dart';
import '../platform/linux/tz_datetime_linux.dart';
import '../platform/windows/tz_datetime_windows.dart';
import 'register.dart';

void register() {
  if (registered) return;

  if (Platform.isAndroid) {
    TzDatetimePlatform.instance = TzDatetimeAndroid();
  } else if (Platform.isIOS || Platform.isMacOS) {
    TzDatetimePlatform.instance = TzDatetimeDarwin();
  } else if (Platform.isLinux) {
    TzDatetimePlatform.instance = TzDatetimeLinux();
  } else if (Platform.isWindows) {
    TzDatetimePlatform.instance = TzDatetimeWindows();
  }

  registered = true;
}
