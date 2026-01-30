import 'dart:io';

import 'package:mica_cli/helpers/format_helper.dart';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:mica_cli/generators/constant.dart';

class EntityGenerator {
  final String featureName;

  const EntityGenerator(this.featureName);

  Future<void> generate(JsonParseModel parser) async {
    String url = "$remoteUrl/entity_template.mustache";
    final response = await http.get(Uri.parse(url));
    final template = Template(
      response.body,
      lenient: true,
      htmlEscapeValues: false,
    );

    final newMap = parser.toJson();
    newMap['entity_name_snack_case'] = parser.entity.name.snakeCase;

    // Preprocess properties to add transform_expression
    if (newMap['entity'] != null && newMap['entity']['properties'] != null) {
      final properties = newMap['entity']['properties'] as List;
      for (var property in properties) {
        property['transform_expression'] = _getTransformExpression(property);
      }
    }

    final generateCode = template.renderString(newMap);

    final dir = Directory.current;
    final write = File(
      path.join(
        dir.path,
        'lib',
        parser.generatedPath,
        featureName,
        'domain',
        'entities',
      ),
    );
    final output = Directory(write.path);
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }

    final outputFile = File(
      '${output.path}/${parser.entity.name.snakeCase}_entity.codegen.dart',
    );

    outputFile.writeAsString(generateCode);
    await formatFile(outputFile.path);
    print('${outputFile.path} generated');
  }

  String _getTransformExpression(Map<String, dynamic> property) {
    final name = property['name'] as String;
    final isPrimitive = property['is_primitive'] as bool? ?? false;
    final isList = property['is_list'] as bool? ?? false;
    final isRequired = property['is_required'] as bool? ?? true;

    if (isPrimitive) {
      return name;
    } else if (isList) {
      if (isRequired) {
        return '$name.map((e) => e.toModel()).toList()';
      } else {
        return '$name?.map((e) => e.toModel()).toList()';
      }
    } else {
      if (isRequired) {
        return '$name.toModel()';
      } else {
        return '$name?.toModel()';
      }
    }
  }
}
