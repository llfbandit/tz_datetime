@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/test.dart';
import 'package:tz_datetime/src/platform/web/tz_datetime_web.dart';
import 'package:tz_datetime/tz_datetime.dart';

void main() {
  final intl = globalContext['Intl'] as JSObject;

  // Removes [name] from Intl for the current test, as on old browsers.
  void removeIntl(String name) {
    final original = intl[name];
    intl[name] = null;
    addTearDown(() => intl[name] = original);
  }

  test('rejects unknown zones on supported browsers', () {
    expect(
      () => TzDatetimeWeb().getOffset(DateTime.utc(2023), 'Europe/Pariss'),
      throwsA(isA<LocationNotFoundException>()),
    );
  });

  test('reports missing Intl.DateTimeFormat support', () {
    removeIntl('DateTimeFormat');
    expect(
      () => TzDatetimeWeb().getOffset(DateTime.utc(2023), 'Europe/Paris'),
      throwsA(isA<TimeZoneInitException>()),
    );
  });

  test('reports missing Intl.supportedValuesOf support', () {
    removeIntl('supportedValuesOf');
    expect(
      () => TzDatetimeWeb().getAvailableTimezones(),
      throwsA(isA<TimeZoneInitException>()),
    );
  });
}
