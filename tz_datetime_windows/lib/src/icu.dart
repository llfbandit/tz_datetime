import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'icu_bindings.dart';

// UCalendarType
const _ucalDefault = 0;

// UCalendarDateFields
const _fieldZoneOffset = 15;
const _fieldDstOffset = 16;

// UTimeZoneTransitionType
const _tzTransitionNext = 0;

final _bindings = IcuBindings(DynamicLibrary.open('icu.dll'));

// --- Public API --------------------------------------------------------------

int localToUtcMicros(String zoneId, int localAsUtcMs, int us) {
  return using((arena) {
    final status = arena<UErrorCode>()..value = 0;
    final zonePtr = _toUChar(zoneId, arena);

    final cal = _bindings.ucal_open(
      zonePtr,
      zoneId.length,
      nullptr,
      _ucalDefault,
      status,
    );
    _checkStatus(status.value, 'ucal_open');

    try {
      // Gets total offset (zone + DST) in ms for the calendar at the given UTC time.
      // Reuses the open calendar to avoid repeated ucal_open/close overhead.
      int offsetAt(double ms) {
        status.value = 0;
        _bindings.ucal_setMillis(cal, ms, status);
        _checkStatus(status.value, 'ucal_setMillis');

        status.value = 0;
        final raw = _bindings.ucal_get(cal, _fieldZoneOffset, status);
        _checkStatus(status.value, 'ucal_get(ZONE_OFFSET)');

        status.value = 0;
        final dst = _bindings.ucal_get(cal, _fieldDstOffset, status);
        _checkStatus(status.value, 'ucal_get(DST_OFFSET)');

        return raw + dst;
      }

      final localOffset = offsetAt(localAsUtcMs.toDouble());
      final adjustedInstant = localAsUtcMs - localOffset;
      final adjOffset = offsetAt(adjustedInstant.toDouble());
      var resultMs = localAsUtcMs - adjOffset;

      if (localOffset != adjOffset) {
        if (adjOffset != offsetAt(resultMs.toDouble())) {
          // Spring-forward gap: ask ICU for the exact transition UTC instant.
          // This replaces the binary search with a single ucal_getTimeZoneTransitionDate call.
          final postGapOffset = localOffset > adjOffset
              ? localOffset
              : adjOffset;
          final loMs = adjOffset == postGapOffset ? resultMs : adjustedInstant;

          status.value = 0;
          _bindings.ucal_setMillis(cal, loMs.toDouble(), status);
          _checkStatus(status.value, 'ucal_setMillis');

          final transitionPtr = arena<Double>();
          status.value = 0;
          final found = _bindings.ucal_getTimeZoneTransitionDate(
            cal,
            _tzTransitionNext,
            transitionPtr,
            status,
          );
          _checkStatus(status.value, 'ucal_getTimeZoneTransitionDate');

          if (found != 0) {
            resultMs = transitionPtr.value.round();
          }
        }
      }

      return resultMs * 1000 + us;
    } finally {
      _bindings.ucal_close(cal);
    }
  });
}

Duration getOffset(String zoneId, int millisSinceEpoch) {
  return using((arena) {
    final status = arena<UErrorCode>()..value = 0;
    final zonePtr = _toUChar(zoneId, arena);

    final cal = _bindings.ucal_open(
      zonePtr,
      zoneId.length,
      nullptr,
      _ucalDefault,
      status,
    );
    _checkStatus(status.value, 'ucal_open');

    try {
      status.value = 0;
      _bindings.ucal_setMillis(cal, millisSinceEpoch.toDouble(), status);
      _checkStatus(status.value, 'ucal_setMillis');

      status.value = 0;
      final rawOffset = _bindings.ucal_get(cal, _fieldZoneOffset, status);
      _checkStatus(status.value, 'ucal_get(ZONE_OFFSET)');

      status.value = 0;
      final dstOffset = _bindings.ucal_get(cal, _fieldDstOffset, status);
      _checkStatus(status.value, 'ucal_get(DST_OFFSET)');

      return Duration(milliseconds: rawOffset + dstOffset);
    } finally {
      _bindings.ucal_close(cal);
    }
  });
}

List<String> getAvailableTimezones() {
  return using((arena) {
    final status = arena<UErrorCode>()..value = 0;

    final en = _bindings.ucal_openTimeZones(status);
    _checkStatus(status.value, 'ucal_openTimeZones');

    try {
      status.value = 0;
      final count = _bindings.uenum_count(en, status);
      _checkStatus(status.value, 'uenum_count');

      final lenPtr = arena<Int32>();
      final result = <String>[];

      for (var i = 0; i < count; i++) {
        status.value = 0;
        final chars = _bindings.uenum_unext(en, lenPtr, status);
        if (chars == nullptr) break;
        _checkStatus(status.value, 'uenum_unext');
        result.add(String.fromCharCodes(chars.asTypedList(lenPtr.value)));
      }

      return result;
    } finally {
      _bindings.uenum_close(en);
    }
  });
}

// --- Helpers -----------------------------------------------------------------

void _checkStatus(int status, String fn) {
  // ICU: status > 0 means error (U_FAILURE), <= 0 is success or warning
  if (status > 0) throw Exception('ICU error in $fn (code $status)');
}

Pointer<UChar> _toUChar(String s, Allocator alloc) {
  final units = s.codeUnits;
  final ptr = alloc<UChar>(units.length + 1);
  for (var i = 0; i < units.length; i++) {
    ptr[i] = units[i];
  }
  ptr[units.length] = 0;
  return ptr;
}
