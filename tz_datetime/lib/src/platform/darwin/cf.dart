import 'dart:ffi';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'cf_bindings.dart';

// Seconds from 1970-01-01 to CoreFoundation's 2001-01-01 reference date.
const _absoluteTimeSince1970 = 978307200;

// A system framework, so it is also loadable from sandboxed apps.
const _cfPath =
    '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation';

final _bindings = _openCoreFoundation();
const _cfMem = _CFAllocator();

// Zones stay open for the isolate's lifetime, one per ID.
final _zones = <String, CFTimeZoneRef>{};

Duration getOffset(String zoneId, int utcMs) {
  final at = utcMs / 1000 - _absoluteTimeSince1970;
  final seconds = _bindings.CFTimeZoneGetSecondsFromGMT(_zone(zoneId), at);
  return Duration(milliseconds: (seconds * 1000).round());
}

List<String> getAvailableTimezones() {
  final names = _bindings.CFTimeZoneCopyKnownNames();
  if (names == nullptr) {
    throw TimeZoneInitException('CFTimeZoneCopyKnownNames failed');
  }

  try {
    final count = _bindings.CFArrayGetCount(names);
    return [
      for (var i = 0; i < count; i++)
        _toDartString(_bindings.CFArrayGetValueAtIndex(names, i).cast()),
    ];
  } finally {
    _bindings.CFRelease(names.cast());
  }
}

CoreFoundationBindings _openCoreFoundation() {
  try {
    return CoreFoundationBindings(DynamicLibrary.open(_cfPath));
  } on ArgumentError catch (e) {
    throw TimeZoneInitException('CoreFoundation not available: ${e.message}');
  }
}

CFTimeZoneRef _zone(String zoneId) => _zones[zoneId] ??= _open(zoneId);

// Without abbreviations, IDs resolve as NSTimeZone.timeZoneWithName: does.
CFTimeZoneRef _open(String zoneId) {
  // Don't rely on CoreFoundation to reject it.
  if (zoneId.isEmpty) throw LocationNotFoundException(zoneId);

  final name = _toCFString(zoneId);
  try {
    final zone = _bindings.CFTimeZoneCreateWithName(nullptr, name, 0);
    if (zone == nullptr) throw LocationNotFoundException(zoneId);
    return zone;
  } finally {
    _bindings.CFRelease(name.cast());
  }
}

CFStringRef _toCFString(String value) {
  final length = value.length;
  final buffer = _cfMem<UniChar>(length);
  try {
    buffer.asTypedList(length).setAll(0, value.codeUnits);
    final string = _bindings.CFStringCreateWithCharacters(
      nullptr,
      buffer,
      length,
    );
    if (string == nullptr) {
      throw TimeZoneInitException('CFStringCreateWithCharacters failed');
    }
    return string;
  } finally {
    _cfMem.free(buffer);
  }
}

String _toDartString(CFStringRef string) {
  final length = _bindings.CFStringGetLength(string);
  if (length == 0) return '';

  final buffer = _cfMem<UniChar>(length);
  try {
    final range = Struct.create<CFRange>()
      ..location = 0
      ..length = length;
    _bindings.CFStringGetCharacters(string, range, buffer);
    return String.fromCharCodes(buffer.asTypedList(length));
  } finally {
    _cfMem.free(buffer);
  }
}

/// Allocator over the default CFAllocator, which is malloc-backed.
final class _CFAllocator implements Allocator {
  const _CFAllocator();

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    final pointer = _bindings.CFAllocatorAllocate(nullptr, byteCount, 0);
    if (pointer == nullptr) throw OutOfMemoryError();
    return pointer.cast();
  }

  @override
  void free(Pointer pointer) =>
      _bindings.CFAllocatorDeallocate(nullptr, pointer.cast());
}
