import 'dart:io';
import 'dart:typed_data';

import 'package:tz_datetime_platform_interface/tz_datetime_platform_interface.dart';

// Same lookup order as bionic.
const _paths = [
  '/apex/com.android.tzdata/etc/tz/tzdata', // API 29+
  '/data/misc/zoneinfo/current/tzdata', // API 26-28 with tzdata update
  '/system/usr/share/zoneinfo/tzdata', // API 26-28
];

/// Android packed tzdata file: a header, an index of zones, then TZif blobs.
class Tzdata {
  Tzdata._(this._path, this._entries);

  final String _path;
  final Map<String, (int, int)> _entries;

  static Tzdata open() {
    for (final path in _paths) {
      final file = File(path);
      if (file.existsSync()) return Tzdata._(path, _readIndex(file));
    }
    throw TimeZoneInitException('tzdata not found');
  }

  Iterable<String> get ids => _entries.keys;

  /// Returns the TZif data of [id], or null if it is unknown.
  Uint8List? read(String id) {
    final entry = _entries[id];
    if (entry == null) return null;

    final file = File(_path).openSync();
    try {
      file.setPositionSync(entry.$1);
      return file.readSync(entry.$2);
    } finally {
      file.closeSync();
    }
  }

  // Index entry: name[40], start, length, rawOffset (big-endian int32).
  static Map<String, (int, int)> _readIndex(File file) {
    final raf = file.openSync();
    try {
      final header = ByteData.sublistView(raf.readSync(24));
      if (String.fromCharCodes(header.buffer.asUint8List(0, 6)) != 'tzdata') {
        throw TimeZoneInitException('Invalid tzdata header');
      }
      final indexOffset = header.getUint32(12);
      final dataOffset = header.getUint32(16);

      raf.setPositionSync(indexOffset);
      final index = ByteData.sublistView(
        raf.readSync(dataOffset - indexOffset),
      );

      final entries = <String, (int, int)>{};
      for (var pos = 0; pos + 52 <= index.lengthInBytes; pos += 52) {
        final name = index.buffer.asUint8List(index.offsetInBytes + pos, 40);
        final end = name.indexOf(0);
        final id = String.fromCharCodes(end < 0 ? name : name.sublist(0, end));
        entries[id] = (
          dataOffset + index.getUint32(pos + 40),
          index.getUint32(pos + 44),
        );
      }
      return entries;
    } finally {
      raf.closeSync();
    }
  }
}
