## 1.2.0

* feat: Export LocationNotFoundException and TimeZoneInitException.
* fix: Throw LocationNotFoundException for unknown zones on all platforms.
* feat: Merge Android and Linux implementations.
* fix: Snap spring-forward gap to exact transition.
* fix: Read TZif data in Dart instead of changing process TZ.
* fix: Read updated tzdata on Android API 26-28.
* fix: List symlinked zone aliases on Linux.

## 1.1.0

* feat: Remove Flutter dependencies.
* fix: Parsing.
* fix: spring-forward gap.
* chore: Reaches 100% coverage.

## 1.0.2

* fix: Auto-register platform to get rid of Flutter mechanics for basic testing.

## 1.0.1

* fix: Add proper copyWith to adjust timezone offset.
* fix: pubspec.yaml infos.

## 1.0.0

* Initial release of tz_datetime package
* Provides timezone-aware datetime functionality
* Includes utilities for timezone conversion and manipulation
* Supports parsing and formatting of timezone-aware dates
* Compatible with standard Dart DateTime operations
* SDK 3.8.1 and Flutter 3.32.1
