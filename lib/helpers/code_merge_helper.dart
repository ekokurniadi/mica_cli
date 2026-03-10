import 'package:mica_cli/generators/json_parse_model.dart';

/// Helper for smart-append across all generated files.
class CodeMergeHelper {
  // ─────────────────────────────────────────────────────────────────────────
  // Usecase / Repository / Datasource helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns only usecases whose [methodName] does NOT already appear in [existingContent].
  static List<UseCase> filterNewUsecases(
    List<UseCase> usecases,
    String existingContent,
  ) {
    return usecases.where((usecase) {
      return !existingContent.contains('${usecase.methodName}(');
    }).toList();
  }

  /// Inserts [injection] just before the very last `}` in [source].
  static String injectBeforeLastBrace(String source, String injection) {
    final lastBrace = source.lastIndexOf('}');
    if (lastBrace == -1) return source + injection;
    return source.substring(0, lastBrace) +
        injection +
        source.substring(lastBrace);
  }

  /// Inserts [injection] just before the `}` that immediately precedes [nextMarker].
  /// Used to append into the abstract class body when an impl class follows.
  static String injectBeforeAbstractClassEnd(
    String source,
    String nextMarker,
    String injection,
  ) {
    final markerIndex = source.indexOf(nextMarker);
    if (markerIndex == -1) return injectBeforeLastBrace(source, injection);
    final abstractEnd = source.lastIndexOf('}', markerIndex - 1);
    if (abstractEnd == -1) return source;
    return source.substring(0, abstractEnd) +
        injection +
        source.substring(abstractEnd);
  }

  /// Builds an abstract method declaration line for [usecase].
  static String buildAbstractMethod(UseCase usecase) {
    return '\n  Future<Either<Failures, ${usecase.returnType}>> '
        '${usecase.methodName}(${usecase.param} ${usecase.paramName});\n';
  }

  /// Builds an `@override` implementation stub for [usecase].
  static String buildImplMethod(UseCase usecase) {
    return '''

  @override
  Future<Either<Failures, ${usecase.returnType}>> ${usecase.methodName}(${usecase.param} ${usecase.paramName}) async {
    //TODO: implements ${usecase.methodName}
    throw UnimplementedError();
  }
''';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Entity / Model (freezed) smart-append helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns only properties whose [name] does NOT already appear as a
  /// named argument `name:` in [existingContent] (matches extension call site).
  static List<EntityPropertiesModel> filterNewProperties(
    List<EntityPropertiesModel> properties,
    String existingContent,
  ) {
    return properties.where((prop) {
      // The extension toModel/toEntity call has `  fieldName: fieldName,`
      // so searching for `${name}:` is a reliable indicator.
      return !existingContent.contains('${prop.name}:');
    }).toList();
  }

  /// Injects [propertyDecl] (e.g. `  required String email,\n`) into the
  /// freezed factory constructor, just before `}) = _ClassName`.
  static String injectIntoFreezedFactory(
    String source,
    String propertyDecl,
  ) {
    // The factory constructor ends with `}) = _`
    const marker = '}) = _';
    final idx = source.indexOf(marker);
    if (idx == -1) return source;

    // Ensure the existing last parameter has a trailing comma before injection.
    final before = source.substring(0, idx);
    final trimmed = before.trimRight();
    final needsComma = trimmed.isNotEmpty && !trimmed.endsWith(',');
    final prefix = needsComma ? ',\n' : '';

    return trimmed + prefix + propertyDecl + source.substring(idx);
  }

  /// Injects [mappingLine] (e.g. `    email: email,\n`) into the
  /// `toModel()` / `toEntity()` extension call, just before its closing `  );`.
  static String injectIntoExtensionCall(
    String source,
    String mappingLine,
  ) {
    // The extension method body ends with `  );`
    const marker = '  );';
    final idx = source.lastIndexOf(marker);
    if (idx == -1) return source;
    return source.substring(0, idx) + mappingLine + source.substring(idx);
  }

  /// Injects [importLine] into [source] after the last existing `import` line.
  static String injectImportLine(String source, String importLine) {
    // Find last import statement
    final lines = source.split('\n');
    int lastImportIdx = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trimLeft().startsWith('import ')) lastImportIdx = i;
    }
    if (lastImportIdx == -1) {
      // No imports found, prepend
      return '$importLine\n$source';
    }
    lines.insert(lastImportIdx + 1, importLine);
    return lines.join('\n');
  }
}
