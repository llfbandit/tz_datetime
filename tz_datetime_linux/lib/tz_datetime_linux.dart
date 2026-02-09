import 'dart:io';
import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

class TzDatetimeLinux extends TzDatetimePlatform {
  static void registerWith() {
    TzDatetimePlatform.instance = TzDatetimeLinux();
  }

  @override
  List<String> getAvailableTimezones() {
    final timezones = <String>[];

    final result = Process.runSync('timedatectl', [
      'list-timezones',
    ], runInShell: true);

    if (result.exitCode == 0) {
      final output = result.stdout.toString();

      final lines = output.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty) {
          timezones.add(trimmedLine);
        }
      }
    } else {
      throw LocationNotFoundException(
        'timedatectl result code: ${result.exitCode}',
      );
    }

    return timezones..sort();
  }

  @override
  Duration getOffset(DateTime date, String zoneId) {
    // Validate the zoneId format
    if (!_isValidZoneId(zoneId)) {
      throw LocationNotFoundException('Invalid timezone identifier: $zoneId');
    }

    // Use the date command to convert a UTC time to the target timezone
    // This approach handles historical timezone data correctly
    final utcDate = date.toUtc();
    final utcDateString = StringBuffer()
      ..write(utcDate.year)
      ..write('-')
      ..write(utcDate.month.toString().padLeft(2, '0'))
      ..write('-')
      ..write(utcDate.day.toString().padLeft(2, '0'))
      ..write(' ')
      ..write(utcDate.hour.toString().padLeft(2, '0'))
      ..write(':')
      ..write(utcDate.minute.toString().padLeft(2, '0'))
      ..write(':')
      ..write(utcDate.second.toString().padLeft(2, '0'))
      ..write(' +00')
      ..toString();

    final result = Process.runSync(
      'date',
      ['--date=$utcDateString', '+%z'],
      environment: {'TZ': zoneId},
      runInShell: true,
    );

    final offsetStr = result.stdout.toString().trim();
    return _parseOffset(offsetStr);
  }

  /// Validate if the zoneId follows a valid timezone format
  bool _isValidZoneId(String zoneId) {
    // Basic validation: should contain letters, numbers, underscores, hyphens, and slashes
    final regex = RegExp(r'^[a-zA-Z0-9_\-/]+$');
    return regex.hasMatch(zoneId);
  }

  /// Parse the offset string (like +0530 or -0800) into a Duration
  Duration _parseOffset(String offsetStr) {
    if (offsetStr.isEmpty) {
      return Duration.zero;
    }

    // Remove any leading/trailing whitespace
    offsetStr = offsetStr.trim();

    // Check if the string starts with + or -
    final isNegative = offsetStr.startsWith('-');
    final cleanStr = isNegative || offsetStr.startsWith('+')
        ? offsetStr.substring(1)
        : offsetStr;

    // Parse hours and minutes from the string (format: HHMM)
    if (cleanStr.length >= 4) {
      final hoursStr = cleanStr.substring(0, 2);
      final minutesStr = cleanStr.substring(2, 4);

      final hours = int.tryParse(hoursStr) ?? 0;
      final minutes = int.tryParse(minutesStr) ?? 0;

      var duration = Duration(hours: hours, minutes: minutes);
      if (isNegative) {
        duration = -duration;
      }

      return duration;
    } else {
      // If format is different, try parsing as decimal hours
      final offsetHours = double.tryParse(offsetStr);
      if (offsetHours != null) {
        final totalMinutes = (offsetHours * 60).round();
        return Duration(minutes: totalMinutes);
      }
    }

    return Duration.zero;
  }
}
