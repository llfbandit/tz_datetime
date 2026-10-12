import 'dart:ffi';
import 'dart:math';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

import 'icu_bindings.dart';

// UCalendarType
const _ucalDefault = 0;

// UCalendarDateFields
const _fieldZoneOffset = 15;
const _fieldDstOffset = 16;

// ICU's UCAL_UNKNOWN_ZONE_ID, resolved for unrecognised zone IDs.
const _unknownZoneId = 'Etc/Unknown';

final _bindings = _openIcu();
const _coTaskMem = _CoTaskMemAllocator();

// Calendars stay open for the isolate's lifetime, one per zone.
final _calendars = <String, Pointer<UCalendar>>{};

// Scratch buffers reused by every call.
final _status = _coTaskMem<UErrorCode>();
final _length = _coTaskMem<Int32>();

Duration getOffset(String zoneId, int utcMs) =>
    Duration(milliseconds: _offsetAt(_calendar(zoneId), utcMs));

List<String> getAvailableTimezones() {
  _status.value = 0;
  final en = _bindings.ucal_openTimeZones(_status);
  _checkStatus('ucal_openTimeZones');

  try {
    final result = <String>[];
    while (true) {
      final chars = _bindings.uenum_unext(en, _length, _status);
      _checkStatus('uenum_unext');
      if (chars == nullptr) return result;
      result.add(String.fromCharCodes(chars.asTypedList(_length.value)));
    }
  } finally {
    _bindings.uenum_close(en);
  }
}

// Windows 10 1903+ ships icu.dll; 1703-1809 ship icuin.dll and icuuc.dll.
IcuBindings _openIcu() {
  try {
    return IcuBindings(DynamicLibrary.open('icu.dll'));
  } on ArgumentError {
    // Fall back to the split libraries below.
  }

  try {
    final i18n = DynamicLibrary.open('icuin.dll');
    final common = DynamicLibrary.open('icuuc.dll');
    return IcuBindings.fromLookup(
      <T extends NativeType>(symbol) => i18n.providesSymbol(symbol)
          ? i18n.lookup<T>(symbol)
          : common.lookup<T>(symbol),
    );
  } on ArgumentError catch (e) {
    throw TimeZoneInitException('ICU not available: ${e.message}');
  }
}

Pointer<UCalendar> _calendar(String zoneId) =>
    _calendars[zoneId] ??= _open(zoneId);

// ICU silently falls back to Etc/Unknown for unknown zones.
Pointer<UCalendar> _open(String zoneId) {
  // An empty ID would open the host's default zone.
  if (zoneId.isEmpty) throw LocationNotFoundException(zoneId);

  // Holds the requested ID, then the resolved one.
  final capacity = max(zoneId.length, _unknownZoneId.length);
  final buffer = _coTaskMem<UChar>(capacity);
  try {
    buffer.asTypedList(capacity).setAll(0, zoneId.codeUnits);
    _status.value = 0;
    final cal = _bindings.ucal_open(
      buffer,
      zoneId.length,
      nullptr,
      _ucalDefault,
      _status,
    );
    _checkStatus('ucal_open');

    final length = _bindings.ucal_getTimeZoneID(cal, buffer, capacity, _status);
    // On failure the buffer still holds zoneId, which would pass as known.
    if (_status.value > 0) _bindings.ucal_close(cal);
    _checkStatus('ucal_getTimeZoneID');
    final resolved = buffer.asTypedList(min(length, capacity));
    if (String.fromCharCodes(resolved) == _unknownZoneId) {
      _bindings.ucal_close(cal);
      throw LocationNotFoundException(zoneId);
    }
    return cal;
  } finally {
    _coTaskMem.free(buffer);
  }
}

// Total offset (zone + DST) in ms at [utcMs].
int _offsetAt(Pointer<UCalendar> cal, int utcMs) {
  // ICU calls are no-ops once status holds an error, so one check suffices.
  _status.value = 0;
  _bindings.ucal_setMillis(cal, utcMs.toDouble(), _status);
  final raw = _bindings.ucal_get(cal, _fieldZoneOffset, _status);
  final dst = _bindings.ucal_get(cal, _fieldDstOffset, _status);
  _checkStatus('ucal_get');
  return raw + dst;
}

void _checkStatus(String fn) {
  // ICU: status > 0 means error (U_FAILURE), <= 0 is success or warning.
  final status = _status.value;
  if (status > 0) {
    throw TimeZoneInitException('ICU error in $fn (code $status)');
  }
}

final _ole32 = DynamicLibrary.open('ole32.dll');
final _coTaskMemAlloc = _ole32
    .lookupFunction<Pointer Function(Size), Pointer Function(int)>(
      'CoTaskMemAlloc',
    );
final _coTaskMemFree = _ole32
    .lookupFunction<Void Function(Pointer), void Function(Pointer)>(
      'CoTaskMemFree',
    );

/// Allocator over CoTaskMemAlloc, as package:ffi uses on Windows.
final class _CoTaskMemAllocator implements Allocator {
  const _CoTaskMemAllocator();

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    final pointer = _coTaskMemAlloc(byteCount);
    if (pointer == nullptr) throw OutOfMemoryError();
    return pointer.cast();
  }

  @override
  void free(Pointer pointer) => _coTaskMemFree(pointer);
}
