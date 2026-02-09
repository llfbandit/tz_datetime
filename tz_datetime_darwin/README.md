Swift APIs can be made compatible with Objective-C, using the @objc annotation.

Then you can use the swiftc tool to build a dylib for the library using -emit-library, and generate an Objective-C wrapper header using -emit-objc-header-path filename.h:

```shell
swiftc -c src/tz_datetime_darwin.swift                           \
    -module-name tz_datetime_darwin_module                       \
    -emit-objc-header-path third_party/tz_datetime_darwin_api.h  \
    -emit-library -o tz_datetime_darwin.dylib
```

This should generate tz_datetime_darwin.dylib and tz_datetime_darwin_api.h.

Once you have an Objective-C wrapper header, FFIgen can parse it like any other header:

```shell
dart run ffigen --config ffigen.yaml
```
