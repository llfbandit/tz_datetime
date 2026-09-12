@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tz_datetime/src/platform/tzdata.dart';
import 'package:tz_datetime/src/platform/tzif.dart';
import 'package:tz_datetime/tz_datetime.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('tzdata_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  String write(String name, List<int> bytes) {
    final file = File('${dir.path}/$name')..writeAsBytesSync(bytes);
    return file.path;
  }

  // Closes before tearDown so OS can delete the files.
  Tzdata open(List<String> paths) {
    final tzdata = Tzdata.open(paths);
    addTearDown(tzdata.close);
    return tzdata;
  }

  test('reads zones from a valid file', () {
    final tzdata = open([write('tzdata', _tzdata())]);

    expect(tzdata.ids, ['Europe/Test']);
    final zone = TzifZone.tryParse(tzdata.read('Europe/Test')!)!;
    expect(zone.offsetMsAt(0), 3600000);
    expect(tzdata.read('Europe/Unknown'), isNull);
  });

  test('falls back past missing, unreadable and malformed files', () {
    final valid = _tzdata();
    final badOffsets = Uint8List.fromList(valid);
    ByteData.sublistView(badOffsets).setUint32(12, 0xFFFF);

    final tzdata = open([
      '${dir.path}/missing',
      dir.path,
      write('truncated', 'tzdata'.codeUnits),
      write('bad_magic', List.filled(valid.length, 0)),
      write('bad_offsets', badOffsets),
      write('tzdata', valid),
    ]);

    expect(tzdata.ids, ['Europe/Test']);
  });

  test('skips entries outside the file', () {
    final valid = _tzdata();
    final path = write('tzdata', valid.sublist(0, valid.length - 1));

    expect(open([path]).ids, isEmpty);
  });

  test('opens the newest version, the first on ties', () {
    final older = write('older', _tzdata('2024a'));
    final newer = write('newer', _tzdata('2025b'));
    final same = write('same', _tzdata('2025b'));

    expect(open([older, newer]).version, '2025b');
    expect(open([newer, older]).version, '2025b');
    expect(open([newer, same]).read('Europe/Test'), isNotNull);
    expect(open([older]).version, '2024a');
  });

  test('keeps reading the opened file after it is replaced', () {
    final path = write('tzdata', _tzdata());
    final tzdata = open([path]);

    final update = write('update', _tzdata('2025b', 7200));
    File(update).renameSync(path);

    final zone = TzifZone.tryParse(tzdata.read('Europe/Test')!)!;
    expect(zone.offsetMsAt(0), 3600000);
  }, testOn: '!windows');

  test('throws when no file is usable', () {
    expect(
      () => open([write('truncated', 'tzdata'.codeUnits)]),
      throwsA(isA<TimeZoneInitException>()),
    );
  });
}

// Packed tzdata with one zone at UTC+1, or [offset] seconds.
Uint8List _tzdata([String version = '2024a', int offset = 3600]) {
  // TZif v1: header, one type (offset), designation "CET".
  final tzif = BytesBuilder()
    ..add('TZif'.codeUnits)
    ..add(List.filled(16, 0))
    ..add(_be32s([0, 0, 0, 0, 1, 4]))
    ..add(_be32s([offset]))
    ..add([0, 0])
    ..add('CET\x00'.codeUnits);
  final blob = tzif.takeBytes();

  const indexOffset = 24, dataOffset = indexOffset + 52;
  final name = List<int>.filled(40, 0)..setAll(0, 'Europe/Test'.codeUnits);

  return (BytesBuilder()
        ..add('tzdata$version\x00'.codeUnits)
        ..add(_be32s([indexOffset, dataOffset, dataOffset + blob.length]))
        ..add(name)
        ..add(_be32s([0, blob.length, offset]))
        ..add(blob))
      .takeBytes();
}

Uint8List _be32s(List<int> values) {
  final data = ByteData(values.length * 4);
  for (var i = 0; i < values.length; i++) {
    data.setUint32(i * 4, values[i]);
  }
  return data.buffer.asUint8List();
}
