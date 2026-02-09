# tz_datetime_windows

Windows implementation of the `tz_datetime` package.

## Overview

This package provides the Windows-specific implementation for the `tz_datetime` package, which offers timezone-aware datetime functionality for Flutter/Dart applications. Unlike other platforms that use native system timezone databases, Windows uses an embedded IANA database approach.

## Features

- Windows-specific timezone implementation for the `tz_datetime` package
- Embedded IANA timezone database for reliable timezone operations
- Seamless integration with the cross-platform `tz_datetime` API
- Consistent behavior across different Windows versions

## Usage

This package is used internally by `tz_datetime` when running on Windows platforms. Developers typically interact with the main `tz_datetime` package rather than this platform-specific implementation directly.

For general usage instructions, refer to the main [`tz_datetime`](https://pub.dev/packages/tz_datetime) package documentation.

## Implementation Details

- Uses an embedded IANA timezone database
- Maintains compatibility with the broader `tz_datetime` ecosystem
- Follows the same API patterns as other platform implementations

## Contributing

Issues and pull requests should be directed to the main [`tz_datetime`](https://github.com/your-repo/tz_datetime) repository.