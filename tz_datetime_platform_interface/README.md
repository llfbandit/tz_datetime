# tz_datetime_platform_interface

Platform interface for the `tz_datetime` package.

## Overview

This package defines the platform interface for `tz_datetime`, which provides timezone-aware datetime functionality for Flutter/Dart applications. It specifies the common API contract that all platform implementations must adhere to.

## Purpose

The platform interface package serves as:

- An abstract contract defining the core timezone functionality
- A bridge between the main `tz_datetime` package and platform-specific implementations
- A way to define method channels and platform communication protocols
- A foundation for supporting multiple platforms consistently

## Architecture

This package follows the Flutter federated plugin architecture:

- `tz_datetime` - Main package providing the public API
- `tz_datetime_platform_interface` - Defines the common interface
- Platform-specific packages (`tz_datetime_android`, `tz_datetime_darwin`, etc.) - Implement the interface for each platform

## Usage

This package is primarily used by:

- The main `tz_datetime` package
- Platform-specific implementations
- Plugin developers extending timezone functionality

Regular users of the `tz_datetime` package typically don't interact directly with this package.

For general usage instructions, refer to the main [`tz_datetime`](https://pub.dev/packages/tz_datetime) package documentation.

## Contributing

Issues and pull requests should be directed to the main [`tz_datetime`](https://github.com/your-repo/tz_datetime) repository.