import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    if (input.config.code.targetOS != OS.linux) return;

    final builder = CBuilder.library(
      name: 'tz_datetime_linux',
      assetName: 'tz_datetime_linux.dart',
      sources: ['src/tz_datetime.cpp'],
    );

    await builder.run(input: input, output: output);
  });
}
