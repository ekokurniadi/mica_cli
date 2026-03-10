import 'dart:io';

import 'package:mica_cli/helpers/code_merge_helper.dart';
import 'package:mica_cli/helpers/format_helper.dart';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:mica_cli/generators/constant.dart';

class EntityGenerator {
  final String featureName;
  final http.Client _client;
  final Directory? _workingDir;

  EntityGenerator(
    this.featureName, {
    http.Client? client,
    Directory? workingDir,
  })  : _client = client ?? http.Client(),
        _workingDir = workingDir;

  // ── Public entry point ──────────────────────────────────────────────────

  Future<void> generate(JsonParseModel parser) async {
    // Fetch the template once; reuse for all entities in this run.
    final String templateBody = await _fetchTemplate();

    // Generate the root entity.
    await _generateOne(parser.entity, parser, templateBody, isNested: false);

    // Recursively generate every nested entity (depth-first).
    for (final nested in parser.entity.allNestedEntities()) {
      await _generateOne(nested, parser, templateBody, isNested: true);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<String> _fetchTemplate() async {
    final url = '$remoteUrl/entity_template.mustache';
    final response = await _client.get(Uri.parse(url));
    return response.body;
  }

  Future<void> _generateOne(
    EntityParserModel entity,
    JsonParseModel parser,
    String templateBody, {
    bool isNested = false,
  }) async {
    final dir = _workingDir ?? Directory.current;
    final effectiveFeatureName =
        isNested ? entity.name.snakeCase : featureName;
    final outputDir = Directory(
      path.join(
        dir.path,
        'lib',
        parser.generatedPath,
        effectiveFeatureName,
        'domain',
        'entities',
      ),
    );
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final outputFile = File(
      '${outputDir.path}/${entity.name.snakeCase}_entity.codegen.dart',
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

      // Append new property imports (non-primitive types only).
      var updated = existing;
      for (final prop in newProps) {
        if (prop.isPrimitive == false) {
          final importLine = _entityImportLine(
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
          .map((p) => '    ${_entityDecoratedType(p)} ${p.name},\n')
          .join();
      updated =
          CodeMergeHelper.injectIntoFreezedFactory(updated, factoryDecls);

      // Inject into the toModel() extension.
      final extensionLines = newProps
          .map((p) => '      ${p.name}: ${_toModelExpression(p)},\n')
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

    // Build the property list with Entity-suffixed types for non-primitives.
    final properties = entity.properties.map((p) {
      final map = p.toJson();
      map['type'] = _entityDecoratedType(p);
      map['transform_expression'] = _toModelExpression(p);
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

    // Inject imports for non-primitive (nested) entity types.
    for (final prop in entity.properties) {
      if (prop.isPrimitive == false) {
        final importLine = _entityImportLine(
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

  /// Decorated type for use inside an entity class, e.g.
  ///   `required AddressEntity`  /  `List<AddressEntity>?`  /  `required String`
  String _entityDecoratedType(EntityPropertiesModel prop) {
    if (prop.isPrimitive == true) return prop.type;

    final suffix = 'Entity';
    final typeName = '${prop.rawType}$suffix';
    final isList = prop.isList == true;
    final isRequired = prop.isRequired == true;

    if (isList) {
      return isRequired ? 'required List<$typeName>' : 'List<$typeName>?';
    }
    return isRequired ? 'required $typeName' : '$typeName?';
  }

  /// Expression used inside `toModel()` for this property.
  String _toModelExpression(EntityPropertiesModel prop) {
    final name = prop.name;
    if (prop.isPrimitive == true) return name;

    final isList = prop.isList == true;
    final isRequired = prop.isRequired == true;

    if (isList) {
      return isRequired
          ? '$name.map((e) => e.toModel()).toList()'
          : '$name?.map((e) => e.toModel()).toList()';
    }
    return isRequired ? '$name.toModel()' : '$name?.toModel()';
  }

  /// Import line for a nested entity type inside this feature.
  String _entityImportLine(
    String packageName,
    String generatedPath,
    String featureName,
    String typeName,
  ) {
    return "import 'package:$packageName/$generatedPath/${typeName.snakeCase}/"
        "domain/entities/${typeName.snakeCase}_entity.codegen.dart';";
  }
}
