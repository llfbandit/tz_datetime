// Copyright (c) 2014, the timezone project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found at https://github.com/dart-lang/labs/blob/main/pkgs/timezone/LICENSE.

/// Thrown when the platform time zone database can't be loaded.
class TimeZoneInitException implements Exception {
  final String msg;

  TimeZoneInitException(this.msg);

  @override
  String toString() => msg;
}

/// Thrown for a zone ID the platform doesn't know.
class LocationNotFoundException implements Exception {
  final String msg;

  LocationNotFoundException(this.msg);

  @override
  String toString() => msg;
}
