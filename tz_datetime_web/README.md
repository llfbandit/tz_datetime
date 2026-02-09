# tz_datetime_web

Web implementation of the `tz_datetime` package.

## Overview

This package provides the web-specific implementation for the `tz_datetime` package, which offers timezone-aware datetime functionality for Flutter/Dart applications. It leverages native web browser APIs for timezone operations.

## Features

- Web-specific timezone implementation for the `tz_datetime` package
- Integration with native JavaScript Date and Intl APIs
- Seamless integration with the cross-platform `tz_datetime` API
- Consistent behavior across different web browsers

## Usage

This package is used internally by `tz_datetime` when running on web platforms. Developers typically interact with the main `tz_datetime` package rather than this platform-specific implementation directly.

For general usage instructions, refer to the main [`tz_datetime`](https://pub.dev/packages/tz_datetime) package documentation.

## Implementation Details

- Leverages native JavaScript Date and Intl APIs for timezone operations
- Maintains compatibility with the broader `tz_datetime` ecosystem
- Follows the same API patterns as other platform implementations

## Contributing

Issues and pull requests should be directed to the main [`tz_datetime`](https://github.com/your-repo/tz_datetime) repository.