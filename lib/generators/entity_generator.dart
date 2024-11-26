import 'dart:io';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:mica_cli/generators/constant.dart';

class EntityGenerator {
  final String featureName;

  const EntityGenerator(this.featureName);

  Future<void> generate(JsonParseModel parser) async{
    String url = remoteUrl+"/entity_template.mustache";
    final response = await http.get(Uri.parse(url));
    final template = Template(
      response.body,
      lenient: true,
      htmlEscapeValues: false,
    );

    final generateCode = template.renderString(
      parser.toJson(),
    );

    final dir = Directory.current;
    final write = File(path.join(dir.path, featureName, 'domain', 'entities'));
    final output = Directory(write.path);
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }

    final outputFile = File(
        '${output.path}/${parser.entity.name.snakeCase}_entity.codegen.dart');

    outputFile.writeAsString(generateCode);
    print('${outputFile.path} generated');
  }
}
