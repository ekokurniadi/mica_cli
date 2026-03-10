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
  final http.Client _client;
  final Directory? _workingDir;

  PagesGenerator(
    this.featureName, {
    http.Client? client,
    Directory? workingDir,
  })  : _client = client ?? http.Client(),
        _workingDir = workingDir;

  Future<void> generate(JsonParseModel parser) async {
    String url = "$remoteUrl/pages_template.mustache";
    final response = await _client.get(Uri.parse(url));
    final template = Template(
      response.body,
      lenient: true,
      htmlEscapeValues: false,
    );

    final generateCode = template.renderString(
      {'feature_name': parser.featureName.titleCase.replaceAll(' ', '')},
    );

    final dir = _workingDir ?? Directory.current;
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

    await outputFile.writeAsString(generateCode);
    await formatFile(outputFile.path);
    print('${outputFile.path} generated');
  }
}
