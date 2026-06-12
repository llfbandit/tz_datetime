import 'dart:io' show stderr;

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    if (input.config.code.targetOS != OS.android) return;

    final builder = CBuilder.library(
      name: 'tz_datetime_android',
      assetName: 'tz_datetime_android.dart',
      sources: ['src/tz_datetime.cpp'],
    );

    hierarchicalLoggingEnabled = true;
    final logger = Logger('tz_datetime_android')
      ..level = Level.ALL
      ..onRecord.listen((record) => stderr.writeln(record.message));

    await builder.run(
      input: input,
      output: output,
      logger: logger,
    );
  });
}
