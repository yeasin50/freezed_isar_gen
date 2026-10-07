import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator.dart';

Builder isarBuilder(BuilderOptions options) {
  return IsarBuilder();
}

class IsarBuilder implements Builder {
  const IsarBuilder();

  @override
  Map<String, List<String>> get buildExtensions => {
    '^lib/{{}}.dart': ['lib/generated/isar/{{}}.isar.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final library = await buildStep.resolver.libraryFor(buildStep.inputId);

    final reader = LibraryReader(library);
    final generator = IsarGenerator();

    final output = generator.generate(reader, buildStep);

    if (output.trim().isEmpty) {
      return;
    }

    final outputId = AssetId(
      buildStep.inputId.package,
      'lib/generated/isar/${buildStep.inputId.path.substring('lib/'.length).replaceFirst('.dart', '.isar.dart')}',
    );

    await buildStep.writeAsString(outputId, output);
  }
}
