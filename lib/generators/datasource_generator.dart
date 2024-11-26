import 'dart:io';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

class DatasourceGenerator {
  final String featureName;

  const DatasourceGenerator(this.featureName);

  void generate(JsonParseModel parser) {
    final scriptDir = path.dirname(Platform.script.toFilePath());
    final templatePath = path.join(
      scriptDir,
      'templates',
      'datasource_template.mustache',
    );
    String content = File(templatePath).readAsStringSync();
    final template = Template(
      content,
      lenient: true,
      htmlEscapeValues: false,
    );

    for (final sources in parser.datasources) {
      final map = {
        'flutter_package_name': parser.flutterPackageName,
        'generated_path': parser.generatedPath,
        'feature_name': parser.featureName,
        'entity_name': parser.entity.name.snakeCase,
        'class_name':
            '${parser.featureName.titleCase}${sources.toString().titleCase}',
        'usecases': List.from(
          parser.usecases!.map(
            (e) => e.toJson(),
          ),
        ),
      };

      final generateCode = template.renderString(
        map,
      );

      final dir = Directory.current;
      final write =
          File(path.join(dir.path, featureName, 'data', 'datasources', sources));
      final output = Directory(write.path);
      if (!output.existsSync()) {
        output.createSync(recursive: true);
      }

      final outputFile = File(
          '${output.path}/${featureName.snakeCase}_${sources}_datasource.dart');

      outputFile.writeAsString(generateCode);
      print('${outputFile.path} generated');
    }
  }
}
