import 'dart:io';

import 'package:tz_datetime_darwin/tz_datetime_darwin.dart';
import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';
import 'package:tz_datetime_windows/tz_datetime_windows.dart';

import '../platform/tz_datetime_android.dart';
import '../platform/tz_datetime_linux.dart';
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
