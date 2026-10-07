import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:path/path.dart' as p;

import 'annotation.dart';

class IsarGenerator extends Generator {
  static const _generateIsarChecker = TypeChecker.typeNamed(GenerateIsar);

  static const _embeddedChecker = TypeChecker.typeNamed(IsarEmbedded);

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final collections = library.classes
        .where(_generateIsarChecker.hasAnnotationOf)
        .toList();

    if (collections.isEmpty) {
      return '';
    }

    final output = StringBuffer();
    final generated = <String>{};
    final embedded = <ClassElement>[];
    final imports = <String>{};

    output.writeln('// GENERATED CODE  ');
    output.writeln();
    output.writeln("import 'package:isar_community/isar.dart';");
    output.writeln();

    final body = StringBuffer();

    for (final element in collections) {
      _generateClass(
        element,
        body,
        generated,
        embedded,
        imports,
        collection: true,
      );
    }

    // Generate embedded classes AFTER collection classes.
    for (final element in embedded) {
      _generateClass(
        element,
        body,
        generated,
        embedded,
        imports,
        collection: false,
      );
    }

    for (final imp in imports) {
      output.writeln("import '$imp';");
    }

    output.writeln();

    final fileName = p.basenameWithoutExtension(buildStep.inputId.path);
    output.writeln("part '$fileName.g.dart';");
    output.writeln();

    output.write(body);

    return output.toString();
  }

  bool _isEnum(DartType type) {
    return type is InterfaceType && type.element is EnumElement;
  }

  void _generateClass(
    ClassElement element,
    StringBuffer output,
    Set<String> generated,
    List<ClassElement> embedded,
    Set<String> imports, {
    required bool collection,
  }) {
    final className = '${element.name}Isar';

    if (!generated.add(className)) {
      return;
    }

    final constructor = _freezedConstructor(element);

    output.writeln(collection ? '@collection' : '@embedded');

    output.writeln('class $className {');

    for (final parameter in constructor.formalParameters) {
      final fieldType = _fieldType(parameter, embedded, imports);

      final nullable =
          parameter.type.nullabilitySuffix != NullabilitySuffix.none;

      if (_isEnum(parameter.type)) {
        output.writeln('  @Enumerated(EnumType.name)');
      }

      output.writeln(
        '  ${nullable ? '' : 'late '}$fieldType ${parameter.name};',
      );
    }

    output.writeln('}');
    output.writeln();
  }

  String _fieldType(
    FormalParameterElement parameter,
    List<ClassElement> embedded,
    Set<String> imports,
  ) {
    final type = parameter.type;

    // List<T>
    if (type is InterfaceType && type.isDartCoreList) {
      if (type.typeArguments.isEmpty) {
        return 'List<dynamic>';
      }

      final itemType = type.typeArguments.first;

      return 'List<${_resolveType(itemType, parameter, embedded, imports)}>${_nullableSuffix(type)}';
    }

    return _resolveType(type, parameter, embedded, imports);
  }

  void _addImport(Element element, Set<String> imports) {
    final uri = element.library?.uri;

    if (uri == null) return;

    // Don't import dart: libraries.
    if (uri.scheme == 'dart') return;

    imports.add(uri.toString());
  }

  String _resolveType(
    DartType type,
    FormalParameterElement parameter,
    List<ClassElement> embedded,
    Set<String> imports,
  ) {
    // Enum → keep the original enum.
    if (type is InterfaceType && type.element is EnumElement) {
      _addImport(type.element, imports);
      return type.getDisplayString();
    }

    // Primitive / DateTime / Duration.
    if (type is InterfaceType &&
        type.element is ClassElement &&
        _isPrimitive(type.element as ClassElement)) {
      _addImport(type.element, imports);
      return type.getDisplayString();
    }

    // Custom object.
    if (type is InterfaceType && type.element is ClassElement) {
      final classElement = type.element as ClassElement;

      _addImport(classElement, imports);

      if (!_isEmbedded(parameter)) {
        throw InvalidGenerationSourceError(
          '${classElement.name} is a custom object but is not marked '
          '@IsarEmbedded(). '
          'Add @IsarEmbedded() if it should be embedded, or make it '
          'a separate @GenerateIsar collection.',
          element: parameter,
        );
      }

      // Queue it. Do NOT generate it immediately.
      if (!embedded.contains(classElement)) {
        embedded.add(classElement);
      }

      return '${classElement.name}Isar${_nullableSuffix(type)}';
    }

    return type.getDisplayString();
  }

  bool _isEmbedded(FormalParameterElement parameter) {
    return _embeddedChecker.hasAnnotationOf(parameter);
  }

  String _nullableSuffix(DartType type) {
    return type.nullabilitySuffix == NullabilitySuffix.question ? '?' : '';
  }

  bool _isPrimitive(ClassElement element) {
    final name = element.name;

    return name == 'String' ||
        name == 'int' ||
        name == 'double' ||
        name == 'bool' ||
        name == 'DateTime' ||
        name == 'Duration';
  }

  ConstructorElement _freezedConstructor(ClassElement element) {
    return element.constructors.firstWhere(
      (constructor) => constructor.isFactory,
      orElse: () => throw InvalidGenerationSourceError(
        '${element.name} must have a Freezed factory constructor.',
        element: element,
      ),
    );
  }
}
