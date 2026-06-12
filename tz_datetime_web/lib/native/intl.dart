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

extension type DateTimeFormatPart._(JSObject _) implements JSObject {
  external JSString get type;
  external JSString get value;
}

extension DateTimeFormatExtension on DateTimeFormat {
  external JSString format(JSAny /* JSObject | num */ date);
  external JSArray<DateTimeFormatPart> formatToParts(JSAny /* JSObject | num */ date);
}
