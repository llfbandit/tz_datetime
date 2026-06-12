import 'dart:ffi';

import 'package:ffi/ffi.dart';

const _assetId = 'package:tz_datetime_android/tz_datetime_android.dart';

@Native<Int32 Function(Pointer<Utf8>, Int64)>(
  symbol: 'tz_get_offset',
  assetId: _assetId,
)
external int _nativeGetOffset(Pointer<Utf8> zoneId, int utcMillis);

@Native<Pointer<Utf8> Function(Pointer<Int32>)>(
  symbol: 'tz_get_timezones',
  assetId: _assetId,
)
external Pointer<Utf8> _nativeGetTimezones(Pointer<Int32> outLength);

@Native<Void Function(Pointer<Void>)>(
  symbol: 'tz_free_buffer',
  assetId: _assetId,
)
external void _nativeFreeBuffer(Pointer<Void> ptr);

@Native<Int64 Function(Pointer<Utf8>, Int64, Int32)>(
  symbol: 'tz_local_to_utc_micros',
  assetId: _assetId,
)
external int _nativeLocalToUtcMicros(Pointer<Utf8> zoneId, int localAsUtcMs, int us);

int getOffsetMs(String zoneId, int utcMillis) {
  final zonePtr = zoneId.toNativeUtf8(allocator: calloc);
  try {
    return _nativeGetOffset(zonePtr, utcMillis);
  } finally {
    calloc.free(zonePtr);
  }
}

int localToUtcMicros(int localAsUtcMs, String zoneId, int us) {
  final zonePtr = zoneId.toNativeUtf8(allocator: calloc);
  try {
    return _nativeLocalToUtcMicros(zonePtr, localAsUtcMs, us);
  } finally {
    calloc.free(zonePtr);
  }
}

List<String> getTimezones() {
  final outLength = calloc<Int32>();
  try {
    final buf = _nativeGetTimezones(outLength);
    if (buf == nullptr) return const [];
    try {
      final str = buf.toDartString(length: outLength.value);
      return str.split('\n').where((s) => s.isNotEmpty).toList();
    } finally {
      _nativeFreeBuffer(buf.cast());
    }
  } finally {
    calloc.free(outLength);
  }
}
