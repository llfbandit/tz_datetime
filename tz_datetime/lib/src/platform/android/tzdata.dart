import 'dart:io';
import 'dart:typed_data';

import '../../exceptions.dart';

// Known copies; bionic's lookup order varies across API levels.
const _paths = [
  '/apex/com.android.tzdata/etc/tz/tzdata', // API 29+ module
  '/data/misc/zoneinfo/current/tzdata', // API 26-30 updates
  '/data/misc/zoneinfo/tzdata', // API 21-25 updates
  '/system/usr/share/zoneinfo/tzdata', // System image
];

/// Android packed tzdata file: a header, an index of zones, then TZif blobs.
///
/// Keeps the file open so reads match the index even if an update replaces it.
class Tzdata {
  Tzdata._(this._file, this.version, this._entries);

  final RandomAccessFile _file;
  final Map<String, (int, int)> _entries;

  /// IANA release such as `2024a`.
  final String version;

  /// Opens the newest readable and valid file of [paths], the first on ties.
  static Tzdata open([List<String> paths = _paths]) {
    Tzdata? newest;
    for (final path in paths) {
      final tzdata = _tryOpen(path);
      if (tzdata == null) continue;
      if (newest == null || tzdata.version.compareTo(newest.version) > 0) {
        newest?.close();
        newest = tzdata;
      } else {
        tzdata.close();
      }
    }
    return newest ?? (throw TimeZoneInitException('tzdata not found'));
  }

  Iterable<String> get ids => _entries.keys;

  /// Returns the TZif data of [id], or null if it is unknown.
  Uint8List? read(String id) {
    final entry = _entries[id];
    if (entry == null) return null;

    _file.setPositionSync(entry.$1);
    return _file.readSync(entry.$2);
  }

  /// Closes the file; later reads throw.
  void close() => _file.closeSync();

  // Returns null if the file is missing, unreadable or malformed.
  // Index entry: name[40], start, length, rawOffset (big-endian int32).
  static Tzdata? _tryOpen(String path) {
    final RandomAccessFile raf;
    try {
      raf = File(path).openSync();
    } on FileSystemException {
      return null;
    }

    Tzdata? tzdata;
    try {
      final header = raf.readSync(24);
      if (header.length < 24 ||
          String.fromCharCodes(header, 0, 6) != 'tzdata') {
        return null;
      }
      final indexOffset = ByteData.sublistView(header).getUint32(12);
      final dataOffset = ByteData.sublistView(header).getUint32(16);
      final length = raf.lengthSync();
      if (indexOffset < 24 || indexOffset > dataOffset || dataOffset > length) {
        return null;
      }

      raf.setPositionSync(indexOffset);
      final index = raf.readSync(dataOffset - indexOffset);
      if (index.length != dataOffset - indexOffset) return null;
      final view = ByteData.sublistView(index);

      final entries = <String, (int, int)>{};
      for (var pos = 0; pos + 52 <= index.length; pos += 52) {
        final start = dataOffset + view.getUint32(pos + 40);
        final size = view.getUint32(pos + 44);
        if (start + size > length) continue;

        final name = Uint8List.sublistView(index, pos, pos + 40);
        final end = name.indexOf(0);
        entries[String.fromCharCodes(name, 0, end < 0 ? 40 : end)] = (
          start,
          size,
        );
      }
      final version = String.fromCharCodes(
        header.sublist(6, 12).takeWhile((c) => c != 0),
      );
      return tzdata = Tzdata._(raf, version, entries);
    } on FileSystemException {
      return null;
    } finally {
      if (tzdata == null) raf.closeSync();
    }
  }
}
