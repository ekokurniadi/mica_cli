import 'dart:io';

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

  Future<void> generate(JsonParseModel parser) async {
    String url = "$remoteUrl/models_template.mustache";
    final response = await http.get(Uri.parse(url));
    final template = Template(
      response.body,
      lenient: true,
      htmlEscapeValues: false,
    );

    final newMap = parser.toJson();
    newMap['entity_name_snack_case'] = parser.entity.name.snakeCase;

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
        'data',
        'models',
      ),
    );
    final output = Directory(write.path);
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }

    final outputFile = File(
      '${output.path}/${parser.entity.name.snakeCase}_model.codegen.dart',
    );

    outputFile.writeAsString(generateCode);
    await formatFile(outputFile.path);
    print('${outputFile.path} generated');
  }

  String _getTransformExpression(Map<String, dynamic> property) {
    final name = property['name'] as String;
    final isPrimitive = property['is_primitive'] as bool? ?? true;
    final isList = property['is_list'] as bool? ?? false;
    final isRequired = property['is_required'] as bool? ?? true;

    if (isPrimitive) {
      return name;
    } else if (isList) {
      if (isRequired) {
        return '$name.map((e) => e.toEntity()).toList()';
      } else {
        return '$name?.map((e) => e.toEntity()).toList()';
      }
    } else {
      if (isRequired) {
        return '$name.toEntity()';
      } else {
        return '$name?.toEntity()';
      }
    }
  }
}
