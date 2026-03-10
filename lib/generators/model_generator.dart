import 'dart:io';

import 'package:mica_cli/helpers/code_merge_helper.dart';
import 'package:mica_cli/helpers/format_helper.dart';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:mica_cli/generators/constant.dart';

class ModelGenerator {
  final String featureName;

  const ModelGenerator(this.featureName);

  // ── Public entry point ──────────────────────────────────────────────────

  Future<void> generate(JsonParseModel parser) async {
    final String templateBody = await _fetchTemplate();

    // Generate the root model.
    await _generateOne(parser.entity, parser, templateBody, isNested: false);

    // Recursively generate every nested model.
    for (final nested in parser.entity.allNestedEntities()) {
      await _generateOne(nested, parser, templateBody, isNested: true);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<String> _fetchTemplate() async {
    final url = '$remoteUrl/models_template.mustache';
    final response = await http.get(Uri.parse(url));
    return response.body;
  }

  Future<void> _generateOne(
    EntityParserModel entity,
    JsonParseModel parser,
    String templateBody, {
    bool isNested = false,
  }) async {
    final dir = Directory.current;
    final effectiveFeatureName =
        isNested ? entity.name.snakeCase : featureName;
    final outputDir = Directory(
      path.join(
        dir.path,
        'lib',
        parser.generatedPath,
        effectiveFeatureName,
        'data',
        'models',
      ),
    );
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final outputFile = File(
      '${outputDir.path}/${entity.name.snakeCase}_model.codegen.dart',
    );

    // ── Smart-append if file already exists ──────────────────────────────
    if (outputFile.existsSync()) {
      final existing = outputFile.readAsStringSync();

      final newProps = CodeMergeHelper.filterNewProperties(
        entity.properties,
        existing,
      );
      if (newProps.isEmpty) {
        print('${outputFile.path} – up to date, nothing to add');
        return;
      }

      var updated = existing;

      // Inject imports for new non-primitive types.
      for (final prop in newProps) {
        if (prop.isPrimitive == false) {
          final importLine = _modelImportLine(
            parser.flutterPackageName,
            parser.generatedPath,
            featureName,
            prop.rawType,
          );
          if (!updated.contains(importLine)) {
            updated = CodeMergeHelper.injectImportLine(updated, importLine);
          }
        }
      }

      // Inject into the freezed factory constructor.
      final factoryDecls = newProps
          .map((p) => '    ${_modelDecoratedType(p)} ${p.name},\n')
          .join();
      updated =
          CodeMergeHelper.injectIntoFreezedFactory(updated, factoryDecls);

      // Inject into the toEntity() extension.
      final extensionLines = newProps
          .map((p) => '      ${p.name}: ${_toEntityExpression(p)},\n')
          .join();
      updated =
          CodeMergeHelper.injectIntoExtensionCall(updated, extensionLines);

      outputFile.writeAsStringSync(updated);
      await formatFile(outputFile.path);
      print(
        '${outputFile.path} – appended ${newProps.length} new property(ies): '
        '${newProps.map((p) => p.name).join(', ')}',
      );
      return;
    }

    // ── First-time generation ─────────────────────────────────────────────
    final template = Template(
      templateBody,
      lenient: true,
      htmlEscapeValues: false,
    );

    final properties = entity.properties.map((p) {
      final map = p.toJson();
      map['type'] = _modelDecoratedType(p);
      map['transform_expression'] = _toEntityExpression(p);
      return map;
    }).toList();

    final map = {
      'flutter_package_name': parser.flutterPackageName,
      'generated_path': parser.generatedPath,
      'feature_name': parser.featureName,
      'entity_name_snack_case': entity.name.snakeCase,
      'entity': {
        'name': entity.name,
        'properties': properties,
      },
    };

    var generatedCode = template.renderString(map);

    // Inject imports for non-primitive (nested) model types.
    for (final prop in entity.properties) {
      if (prop.isPrimitive == false) {
        final importLine = _modelImportLine(
          parser.flutterPackageName,
          parser.generatedPath,
          featureName,
          prop.rawType,
        );
        generatedCode =
            CodeMergeHelper.injectImportLine(generatedCode, importLine);
      }
    }

    outputFile.writeAsStringSync(generatedCode);
    await formatFile(outputFile.path);
    print('${outputFile.path} generated');
  }

  // ── Type helpers ─────────────────────────────────────────────────────────

  /// Decorated type for use inside a model class.
  String _modelDecoratedType(EntityPropertiesModel prop) {
    if (prop.isPrimitive == true) return prop.type;

    final typeName = '${prop.rawType}Model';
    final isList = prop.isList == true;
    final isRequired = prop.isRequired == true;

    if (isList) {
      return isRequired ? 'required List<$typeName>' : 'List<$typeName>?';
    }
    return isRequired ? 'required $typeName' : '$typeName?';
  }

  /// Expression used inside `toEntity()` for this property.
  String _toEntityExpression(EntityPropertiesModel prop) {
    final name = prop.name;
    if (prop.isPrimitive == true) return name;

    final isList = prop.isList == true;
    final isRequired = prop.isRequired == true;

    if (isList) {
      return isRequired
          ? '$name.map((e) => e.toEntity()).toList()'
          : '$name?.map((e) => e.toEntity()).toList()';
    }
    return isRequired ? '$name.toEntity()' : '$name?.toEntity()';
  }

  /// Import line for a nested model type inside this feature.
  String _modelImportLine(
    String packageName,
    String generatedPath,
    String featureName,
    String typeName,
  ) {
    return "import 'package:$packageName/$generatedPath/${typeName.snakeCase}/"
        "data/models/${typeName.snakeCase}_model.codegen.dart';";
  }
}
