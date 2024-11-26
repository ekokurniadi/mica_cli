import 'dart:io';

import 'package:mica_cli/generators/json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';

class EntityGenerator {
  final String featureName;

  const EntityGenerator(this.featureName);

  void generate(JsonParseModel parser) {
    String content = File(
      'lib/templates/entity_template.mustache',
    ).readAsStringSync();
    final template = Template(
      content,
      lenient: true,
      htmlEscapeValues: false,
    );

    final generateCode = template.renderString(
      parser.toJson(),
    );

    final dir = Directory.current;
    final write = File(join(dir.path, featureName, 'domain', 'entities'));
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
