import 'dart:io';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:mica_cli/generators/constant.dart';

class RepositoryImplGenerator {
  final String featureName;

  const RepositoryImplGenerator(this.featureName);

  void generate(JsonParseModel parser) {
    String url = remoteUrl+"/repository_impl_template.mustache";
    final response = await http.get(Uri.parse(url));
    final template = Template(
      response.body,
      lenient: true,
      htmlEscapeValues: false,
    );

    final map = {
      'flutter_package_name': parser.flutterPackageName,
      'generated_path': parser.generatedPath,
      'feature_name': parser.featureName,
      'entity_name': parser.entity.name.snakeCase,
      'class_name': parser.featureName.titleCase.replaceAll(' ',''),
      'datasources': List.from(parser.datasources.map((e) {
        final result = {
          'datasource_name': '${parser.featureName.snakeCase}$e'.replaceAll(' ',''),
          'datasource_class_name': '${parser.featureName.titleCase}${e.toString().titleCase}'.replaceAll(' ',''),
          'datasource_field_name': '${parser.featureName.camelCase}${e.toString().titleCase}'.replaceAll(' ',''),
          'datasource_file_name': '${parser.featureName.snakeCase}_${e.toString().snakeCase}'.replaceAll(' ',''),
          'source': e,
        };
        return result;
      })),
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
    final write = File(path.join(dir.path, featureName, 'data', 'repository'));
    final output = Directory(write.path);
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }

    final outputFile =
        File('${output.path}/${featureName.snakeCase}_repository_impl.dart');

    outputFile.writeAsString(generateCode);
    print('${outputFile.path} generated');
  }
}
