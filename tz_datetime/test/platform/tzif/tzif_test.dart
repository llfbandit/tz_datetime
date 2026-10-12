@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tz_datetime/src/platform/tzif/tzif.dart';

void main() {
  group('footer', () {
    test('accepts rules with days in range', () {
      for (final rule in [
        'XXX3YYY,J1,J365',
        'XXX3YYY,0,365',
        'CET-1CEST,M3.5.0,M10.5.0/3',
        'XXX3YYY,M1.1.0,M12.5.6',
      ]) {
        expect(TzifZone.tryParse(_tzif(rule)), isNotNull, reason: rule);
      }
    });

    test('applies Julian day rules', () {
      final zone = TzifZone.tryParse(_tzif('XXX3YYY,J60,J300'))!;
      final july = DateTime.utc(2023, 7).millisecondsSinceEpoch;
      final january = DateTime.utc(2023).millisecondsSinceEpoch;

      expect(zone.offsetMsAt(july), -2 * 3600000);
      expect(zone.offsetMsAt(january), -3 * 3600000);
    });

    test('rejects rules with days out of range', () {
      for (final rule in [
        'XXX3YYY,J0,J300',
        'XXX3YYY,J1,J366',
        'XXX3YYY,0,366',
        'XXX3YYY,M0.1.0,M10.5.0',
        'XXX3YYY,M13.1.0,M10.5.0',
        'XXX3YYY,M3.0.0,M10.5.0',
        'XXX3YYY,M3.6.0,M10.5.0',
        'XXX3YYY,M3.1.7,M10.5.0',
      ]) {
        expect(TzifZone.tryParse(_tzif(rule)), isNull, reason: rule);
      }
    });
  });
}

// TZif v2 with one UTC type, no transitions and [footer].
Uint8List _tzif(String footer) {
  final header = ByteData(44)
    ..setUint32(0, 0x545A6966) // "TZif"
    ..setUint8(4, 0x32) // version 2
    ..setUint32(36, 1) // typecnt
    ..setUint32(40, 4); // charcnt
  final data = [0, 0, 0, 0, 0, 0, ...'UTC\x00'.codeUnits];

  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(data)
        ..add(header.buffer.asUint8List())
        ..add(data)
        ..add('\n$footer\n'.codeUnits))
      .takeBytes();
}
