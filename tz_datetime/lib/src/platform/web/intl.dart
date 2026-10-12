import 'dart:js_interop';

@JS('Intl')
external Intl get intl;

extension type Intl._(JSObject _) implements JSObject {
  external JSArray<JSString> supportedValuesOf(JSString key);
}

@JS('Intl.DateTimeFormat')
extension type DateTimeFormat._(JSObject _) implements JSObject {
  external DateTimeFormat(JSString locale, [JSObject? options]);

  external JSArray<DateTimeFormatPart> formatToParts(
    JSAny /* JSObject | num */ date,
  );
}

extension type DateTimeFormatPart._(JSObject _) implements JSObject {
  external JSString get type;
  external JSString get value;
}
