import 'dart:io';

import 'package:mica_cli/generators/json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

class UsecaseGenerator {
  final String featureName;

  const UsecaseGenerator(this.featureName);

  void generate(JsonParseModel parser) {
     final scriptDir = path.dirname(Platform.script.toFilePath());
    final templatePath = path.join(
      scriptDir,
      'lib',
      'templates',
      'usecase_template.mustache',
    );
    String content = File(templatePath).readAsStringSync();
    final template = Template(
      content,
      lenient: true,
      htmlEscapeValues: false,
    );

    for (final usecase in parser.usecases!) {
      final map = {
        'flutter_package_name': parser.flutterPackageName,
        'feature_name': parser.featureName,
        'entity_name': parser.entity.name.snakeCase,
        'usecase': usecase.toJson(),
        'repository_name': parser.entity.name,
        'output_path': parser.generatedPath,
      };
      final generateCode = template.renderString(
        map,
      );

      final dir = Directory.current;
      final write = File(path.join(dir.path, featureName, 'domain', 'usecases'));
      final output = Directory(write.path);
      if (!output.existsSync()) {
        output.createSync(recursive: true);
      }

      final outputFile =
          File('${output.path}/${usecase.name.snakeCase}_usecase.dart');

      outputFile.writeAsString(generateCode);

      print('${outputFile.path} generated');
    }
  }
}
