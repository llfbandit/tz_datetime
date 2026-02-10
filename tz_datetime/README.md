# tz_datetime

A lightweight, cross-platform timezone-aware datetime package for Flutter and Dart applications.

This package serves as an alternative to the [Timezone](https://pub.dev/packages/timezone) package with enhanced performance characteristics and improved resource efficiency.

## Key Benefits

- **App Size**: No embedded IANA database in your app, keeping your application footprint small
- **Memory Efficiency**: IANA database is not loaded into memory, reducing RAM usage
- **Fast Startup**: Nothing to load before working with dates & timezones, improving app launch times
- **Native Integration**: Provides seamless calls to dedicated platform APIs
- **Complete Data**: No compromise on truncated databases - full timezone information available
- **Minimal Dependencies**: No heavy dependencies, only lightweight bindings to platform-specific implementations

## API Compatibility

The API is designed to be very similar to the [Timezone](https://pub.dev/packages/timezone) package, making migration straightforward.

Tests are adapted from the original package to ensure reliability and compatibility.

## Platform Support

| Platform | Database Type                                         | Requirement
|----------|-------------------------------------------------------|-------
| Android  | Native                                                | SDK 1.0+
| iOS      | Native                                                | SDK 8.0+
| Linux    | Native (through `date` and `timedatectl`)             | system.d
| macOS    | Native                                                | SDK 10.10+
| Web      | Native                                                | Browser earlier than 2021 (Desktop), 2023 (Mobile)
| Windows  | Embedded                                              |

On most platforms, the package leverages native system timezone databases for accuracy and efficiency.

On Windows, an embedded database approach is used to ensure consistent behavior.

## Usage

Basic usage example:

```dart
import 'package:tz_datetime/tz_datetime.dart';

void main() {
  final la = 'America/Los_Angeles';
  final ny = 'America/New_York';

  // Retrieve all available zones form platform
  final zones = TzDatetime.getAvailableTimezones();  // [Africa/Abidjan, Europe/Athens, ...]
  
  // Get offset from any date with Daylight Saving Times
  Duration offset = TzDatetime.getOffset(DateTime.now(), la);  // -8:00:00.000000

  final laTime = TzDatetime.now(la);  // 2026-02-09T03:17:03.964038-0800

  final nyTime = TzDatetime.from(laTime, ny);  // 2026-02-09T06:17:03.964038-0500
}
```

For more, see the API documentation.

## Contributing

Contributions are always welcome!

## License

This project is licensed under the BSD license.
