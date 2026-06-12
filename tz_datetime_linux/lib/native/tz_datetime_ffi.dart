import 'dart:ffi';

import 'package:ffi/ffi.dart';

const _assetId = 'package:tz_datetime_linux/tz_datetime_linux.dart';

@Native<Int32 Function(Pointer<Utf8>, Int64)>(
  symbol: 'tz_get_offset',
  assetId: _assetId,
)
external int _nativeGetOffset(Pointer<Utf8> zoneId, int utcMillis);

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
