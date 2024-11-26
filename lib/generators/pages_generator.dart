import 'dart:io';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

class PagesGenerator {
  final String featureName;

  const PagesGenerator(this.featureName);

  void generate(JsonParseModel parser) {
     final scriptDir = path.dirname(Platform.script.toFilePath());
     final templatePath = path.join(
      scriptDir,
      'templates',
      'pages_template.mustache',
    );
    String content = File(templatePath).readAsStringSync();
    final template = Template(
      content,
      lenient: true,
      htmlEscapeValues: false,
    );

    final generateCode = template.renderString(
      {'feature_name':parser.featureName.titleCase},
    );

    final dir = Directory.current;
    final write = File(path.join(dir.path, featureName, 'presentations', 'pages'));
    final output = Directory(write.path);
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }

    final outputFile = File(
        '${output.path}/${parser.featureName.snakeCase}_page.dart');

    outputFile.writeAsString(generateCode);
    print('${outputFile.path} generated');
  }
}
