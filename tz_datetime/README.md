# tz_datetime

Time-zone-aware `DateTime` for Dart and Flutter, backed by each platform's own time zone database.  
An alternative to [timezone](https://pub.dev/packages/timezone) with a similar API.

## Key Benefits

- **Small**: no IANA database bundled in your app or loaded into memory, nothing to initialize.
- **Up to date**: uses the OS database, so zone rules follow system updates.
- **No dependencies**: pure Dart over `dart:ffi` and `dart:js_interop`.
- **Drop-in**: `TzDatetime` implements `DateTime`.

## Usage

```dart
import 'package:tz_datetime/tz_datetime.dart';

final la = 'America/Los_Angeles';
final ny = 'America/New_York';

final zones = TzDatetime.getAvailableTimezones();  // [Africa/Abidjan, Europe/Athens, ...]
final offset = TzDatetime.getOffset(DateTime.now(), la);  // -8:00:00.000000

final laTime = TzDatetime.now(la);  // 2026-02-09T03:17:03.964038-0800
final nyTime = TzDatetime.from(laTime, ny);  // 2026-02-09T06:17:03.964038-0500

setLocalZone(ny);  // sets ny as the local zone (default: UTC)
TzDatetime.local(2026, 1, 1);  // uses the zone set above
```

Times skipped by a DST change shift forward by the gap; repeated times resolve to the earlier
instant:

```dart
TzDatetime(ny, 2026, 3, 8, 2, 30);  // 2026-03-08T03:30:00.000-0400 (02:30 is skipped)
```

Unknown zones throw `LocationNotFoundException`.

## Platform Support

| Platform | Requirement |
|----------|-------------|
| Android  | SDK 21+ |
| iOS      | 8.0+ |
| macOS    | 10.10+ |
| Windows  | 10 1703+ |
| Linux    | tzdata in `$TZDIR`, `/usr/share/zoneinfo` or `/etc/zoneinfo` |
| Web      | Chrome 99+, Firefox 93+, Safari 15.4+ |

## License

This project is licensed under the BSD 2-Clause license.
