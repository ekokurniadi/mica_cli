import 'dart:io';

import 'package:mica_cli/generators/json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

class ModelGenerator {
  final String featureName;
  const ModelGenerator(this.featureName);

  void generate(JsonParseModel parser) {
     final scriptDir = path.dirname(Platform.script.toFilePath());
     final templatePath = path.join(
      scriptDir,
      'lib',
      'templates',
      'models_template.mustache',
    );
    String content = File(templatePath).readAsStringSync();
    final template = Template(
      content,
      lenient: true,
      htmlEscapeValues: false,
    );

    final generateCode = template.renderString(
      parser.toJson(),
    );

    final dir = Directory.current;
    final write = File(path.join(dir.path, featureName, 'data', 'models'));
    final output = Directory(write.path);
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }

    final outputFile = File(
        '${output.path}/${parser.entity.name.snakeCase}_model.codegen.dart');

    outputFile.writeAsString(generateCode);
    print('${outputFile.path} generated');
  }
}
