# tz_datetime_linux

Linux implementation of the `tz_datetime` package.

## Overview

This package provides the Linux-specific implementation for the `tz_datetime` package, which offers timezone-aware datetime functionality for Flutter/Dart applications. It leverages native Android APIs for timezone operations.

Uses system utilities like `date` and `timedatectl` for timezone calculations.

## Usage

This package is used internally by `tz_datetime` when running on Linux platforms. Developers typically interact with the main `tz_datetime` package rather than this platform-specific implementation directly.

For general usage instructions, refer to the main [`tz_datetime`](https://pub.dev/packages/tz_datetime) package documentation.

## Contributing

Issues and pull requests should be directed to the main [`tz_datetime`](https://github.com/llfbandit/tz_datetime) repository.