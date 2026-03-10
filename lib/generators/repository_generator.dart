import 'dart:io';

import 'package:mica_cli/helpers/code_merge_helper.dart';
import 'package:mica_cli/helpers/format_helper.dart';

import 'json_parse_model.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import 'package:http/http.dart' as http;
import 'package:mica_cli/generators/constant.dart';

class RepositoryGenerator {
  final String featureName;

  const RepositoryGenerator(this.featureName);

  Future<void> generate(JsonParseModel parser) async {
    final dir = Directory.current;
    final write = File(
      path.join(
        dir.path,
        'lib',
        parser.generatedPath,
        featureName,
        'domain',
        'repository',
      ),
    );
    final output = Directory(write.path);
    if (!output.existsSync()) {
      output.createSync(recursive: true);
    }

    final outputFile =
        File('${output.path}/${featureName.snakeCase}_repository.dart');

    // ── Smart-append: file already exists ──────────────────────────────────
    if (outputFile.existsSync()) {
      final existingContent = outputFile.readAsStringSync();
      final newUsecases = CodeMergeHelper.filterNewUsecases(
        parser.usecases ?? [],
        existingContent,
      );

      if (newUsecases.isEmpty) {
        print('${outputFile.path} – up to date, nothing to add');
        return;
      }

      // Build abstract method declarations for each new usecase
      final injection =
          newUsecases.map(CodeMergeHelper.buildAbstractMethod).join();

      final updatedContent =
          CodeMergeHelper.injectBeforeLastBrace(existingContent, injection);

      outputFile.writeAsStringSync(updatedContent);
      await formatFile(outputFile.path);
      print(
        '${outputFile.path} – appended ${newUsecases.length} new method(s): '
        '${newUsecases.map((e) => e.methodName).join(', ')}',
      );
      return;
    }

    // ── First-time generation ──────────────────────────────────────────────
    String url = "$remoteUrl/repository_template.mustache";
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
      'class_name': parser.featureName.titleCase.replaceAll(' ', ''),
      'usecases': List.from(
        parser.usecases!.map(
          (e) => e.toJson(),
        ),
      ),
    };

    final generateCode = template.renderString(map);
    outputFile.writeAsStringSync(generateCode);
    await formatFile(outputFile.path);
    print('${outputFile.path} generated');
  }
}