# tz_datetime_darwin

iOS/macOS implementation of the `tz_datetime` package.

## Overview

This package provides the iOS/macOS-specific implementation for the `tz_datetime` package, which offers timezone-aware datetime functionality for Flutter/Dart applications. It leverages native iOS/macOS APIs for timezone operations.

## Features

- iOS/macOS-specific timezone implementation for the `tz_datetime` package
- Integration with native iOS/macOS timezone APIs
- Seamless integration with the cross-platform `tz_datetime` API
- Consistent behavior across different macOS versions

## Usage

This package is used internally by `tz_datetime` when running on iOS/macOS platforms. Developers typically interact with the main `tz_datetime` package rather than this platform-specific implementation directly.

For general usage instructions, refer to the main [`tz_datetime`](https://pub.dev/packages/tz_datetime) package documentation.

## Implementation Details

- Leverages native iOS/macOS timezone APIs for accurate timezone operations
- Maintains compatibility with the broader `tz_datetime` ecosystem
- Follows the same API patterns as other platform implementations
- Optimized for iOS/macOS's timezone database and system services

## Contributing

Issues and pull requests should be directed to the main [`tz_datetime`](https://github.com/your-repo/tz_datetime) repository.