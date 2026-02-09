import 'dart:js_interop';

@JS('Intl')
external Intl get intl;

extension type Intl._(JSObject _) implements JSObject {
  external JSArray<JSString> supportedValuesOf(JSString key);
}

@JS('Intl.DateTimeFormat')
@staticInterop
class DateTimeFormat {
  external factory DateTimeFormat(JSString locale, [JSObject? options]);
}

extension DateTimeFormatExtension on DateTimeFormat {
  external JSString format(JSAny /* JSObject | num */ date);
}
