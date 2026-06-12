# tz_datetime_windows

Windows implementation of the `tz_datetime` package.

## Overview

This package provides the Windows-specific implementation for the `tz_datetime` package, which offers timezone-aware datetime functionality for Flutter/Dart applications.

It uses the [ICU](https://icu.unicode.org/) library (`icu.dll`) that ships with Windows 10 version 1703 (April 2017 Creators Update).

## Requirements

- Windows 10 version 1703 (build 15063) or later

## Usage

This package is used internally by `tz_datetime` when running on Windows platforms. Developers typically interact with the main `tz_datetime` package rather than this platform-specific implementation directly.

For general usage instructions, refer to the main [`tz_datetime`](https://pub.dev/packages/tz_datetime) package documentation.

## Contributing

Issues and pull requests should be directed to the main [`tz_datetime`](https://github.com/llfbandit/tz_datetime) repository.