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

    final generateCode = template.renderString(
      newMap,
    );

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
        '${output.path}/${parser.entity.name.snakeCase}_model.codegen.dart');

    outputFile.writeAsString(generateCode);
    await formatFile(outputFile.path);
    print('${outputFile.path} generated');
  }
}
