import 'dart:io';

import 'package:mica_cli/generators/json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';

class PagesGenerator {
  final String featureName;

  const PagesGenerator(this.featureName);

  void generate(JsonParseModel parser) {
     final templatePath = join(
      'lib',
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
    final write = File(join(dir.path, featureName, 'presentations', 'pages'));
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
