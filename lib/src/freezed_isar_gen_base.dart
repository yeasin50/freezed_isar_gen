import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator.dart';

Builder isarBuilder(BuilderOptions options) {
  return IsarBuilder(
    outputDir: options.config['output_dir'] as String? ?? 'lib/generated/isar',
  );
}

class IsarBuilder implements Builder {
  final String outputDir;

  const IsarBuilder({required this.outputDir});

  @override
  Map<String, List<String>> get buildExtensions => {
    '^lib/{{}}.dart': ['$outputDir/{{}}.isar.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final library = await buildStep.resolver.libraryFor(buildStep.inputId);

    final output = IsarGenerator().generate(LibraryReader(library), buildStep);

    if (output.trim().isEmpty) {
      return;
    }

    final inputPath = buildStep.inputId.path;
    final relativePath = inputPath.substring('lib/'.length);

    final outputPath =
        '$outputDir/${relativePath.replaceFirst('.dart', '.isar.dart')}';

    final outputId = AssetId(buildStep.inputId.package, outputPath);

    await buildStep.writeAsString(outputId, output);
  }
}
