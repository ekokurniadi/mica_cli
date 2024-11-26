import 'dart:io';

import 'package:mica_cli/generators/json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

class RepositoryGenerator {
  final String featureName;

  const RepositoryGenerator(this.featureName);

  void generate(JsonParseModel parser) {
     final scriptDir = path.dirname(Platform.script.toFilePath());
    final templatePath = path.join(
      scriptDir,
      'lib',
      'templates',
      'repository_template.mustache',
    );
    String content = File(templatePath).readAsStringSync();
    final template = Template(
      content,
      lenient: true,
      htmlEscapeValues: false,
    );

    final map = {
      'flutter_package_name': parser.flutterPackageName,
      'generated_path': parser.generatedPath,
      'feature_name': parser.featureName,
      'entity_name': parser.entity.name.snakeCase,
      'class_name': parser.featureName.titleCase,
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
    final write = File(path.join(dir.path, featureName, 'domain', 'repository'));
    final output = Directory(write.path);
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }

    final outputFile =
        File('${output.path}/${featureName.snakeCase}_repository.dart');

    outputFile.writeAsString(generateCode);
    print('${outputFile.path} generated');
  }
}
