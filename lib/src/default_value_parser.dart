import 'package:analyzer/dart/element/element.dart';

//// TODO:  WIll separate the parser here
mixin ClassParser {
  String? _defaultValue(FormalParameterElement parameter) {
    for (final annotation in parameter.metadata.annotations) {
      if (annotation.element?.enclosingElement?.name == 'Default') {
        final source = annotation.toSource();

        final start = source.indexOf('(');
        final end = source.lastIndexOf(')');

        if (start != -1 && end > start) {
          return source.substring(start + 1, end).trim();
        }
      }
    }

    return null;
  }
}
