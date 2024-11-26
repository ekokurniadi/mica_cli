import 'dart:io';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:mica_cli/generators/constant.dart';

class RepositoryGenerator {
  final String featureName;

  const RepositoryGenerator(this.featureName);

  Future<void> generate(JsonParseModel parser) async{
    String url = remoteUrl+"/repository_template.mustache";
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
