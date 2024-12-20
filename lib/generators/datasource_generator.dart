import 'dart:io';

import 'package:mica_cli/helpers/format_helper.dart';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:mica_cli/generators/constant.dart';

class DatasourceGenerator {
  final String featureName;

  const DatasourceGenerator(this.featureName);

  Future<void> generate(JsonParseModel parser) async {
    String url = "$remoteUrl/datasource_template.mustache";
    final response = await http.get(Uri.parse(url));

    final template = Template(
      response.body,
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
            '${parser.featureName.titleCase}${sources.toString().titleCase}'
                .replaceAll(' ', ''),
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
      final write = File(
        path.join(
          dir.path,
          'lib',
          parser.generatedPath,
          featureName,
          'data',
          'datasources',
          sources,
        ),
      );
      final output = Directory(write.path);
      if (!output.existsSync()) {
        output.createSync(recursive: true);
      }

      final outputFile = File(
          '${output.path}/${featureName.snakeCase}_${sources}_datasource.dart');

      outputFile.writeAsString(generateCode);
      await formatFile(outputFile.path);
      print('${outputFile.path} generated');
    }
  }
}
