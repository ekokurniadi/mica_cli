import 'dart:io';

import 'package:mica_cli/helpers/format_helper.dart';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:mica_cli/generators/constant.dart';

class PagesGenerator {
  final String featureName;

  const PagesGenerator(this.featureName);

  Future<void> generate(JsonParseModel parser) async {
    String url = "$remoteUrl/pages_template.mustache";
    final response = await http.get(Uri.parse(url));
    final template = Template(
      response.body,
      lenient: true,
      htmlEscapeValues: false,
    );

    final generateCode = template.renderString(
      {'feature_name': parser.featureName.titleCase.replaceAll(' ', '')},
    );

    final dir = Directory.current;
    final write = File(
      path.join(
        dir.path,
        'lib',
        parser.generatedPath,
        featureName,
        'presentations',
        'pages',
      ),
    );
    final output = Directory(write.path);
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }

    final outputFile =
        File('${output.path}/${parser.featureName.snakeCase}_page.dart');

    outputFile.writeAsString(generateCode);
    await formatFile(outputFile.path);
    print('${outputFile.path} generated');
  }
}
