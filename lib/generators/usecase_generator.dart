import 'dart:io';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:mica_cli/generators/constant.dart';

class UsecaseGenerator {
  final String featureName;

  const UsecaseGenerator(this.featureName);

  Future<void> generate(JsonParseModel parser) async{
    String url = remoteUrl+"/usecase_template.mustache";
    final response = await http.get(Uri.parse(url));
    final template = Template(
      response.body,
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
        'generated_path': parser.generatedPath,
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
