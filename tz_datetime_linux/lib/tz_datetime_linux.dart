import 'dart:io';
import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

class TzDatetimeLinux extends TzDatetimePlatform {
  @override
  List<String> getAvailableTimezones() {
    final result = Process.runSync('timedatectl', ['list-timezones']);

    if (result.exitCode != 0) {
      throw TimeZoneInitException(
        'timedatectl exited with code ${result.exitCode}',
      );
    }

    return result.stdout
        .toString()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList()
      ..sort();
  }

  @override
  Duration getOffset(DateTime date, String zoneId) {
    final utc = date.toUtc();
    final utcDateString =
        '${utc.year}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')} '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')} +00';

    final result = Process.runSync(
      'date',
      ['--date=$utcDateString', '+%z'],
      environment: {...Platform.environment, 'TZ': zoneId},
    );

    if (result.exitCode != 0) {
      throw LocationNotFoundException(zoneId);
    }

    return _parseOffset(result.stdout.toString().trim());
  }

  // Parses +%z output from `date` (format: +HHMM or -HHMM)
  Duration _parseOffset(String offsetStr) {
    if (offsetStr.length < 5) return Duration.zero;

    final isNegative = offsetStr.startsWith('-');
    final clean = offsetStr.substring(1);
    final hours = int.tryParse(clean.substring(0, 2)) ?? 0;
    final minutes = int.tryParse(clean.substring(2, 4)) ?? 0;
    final duration = Duration(hours: hours, minutes: minutes);

    return isNegative ? -duration : duration;
  }
}
