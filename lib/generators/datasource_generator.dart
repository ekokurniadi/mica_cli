import 'dart:io';

import 'package:mica_cli/helpers/code_merge_helper.dart';
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

      // ── Smart-append: file already exists ────────────────────────────────
      if (outputFile.existsSync()) {
        final existingContent = outputFile.readAsStringSync();
        final newUsecases = CodeMergeHelper.filterNewUsecases(
          parser.usecases ?? [],
          existingContent,
        );

        if (newUsecases.isEmpty) {
          print('${outputFile.path} – up to date, nothing to add');
          continue;
        }

        final abstractInjection =
            newUsecases.map(CodeMergeHelper.buildAbstractMethod).join();
        final implInjection =
            newUsecases.map(CodeMergeHelper.buildImplMethod).join();

        // The datasource file has two classes:
        //   abstract class XxxDataSource { ... }
        //   class XxxDataSourceImpl implements XxxDataSource { ... }
        //
        // Inject abstract methods before the `}` that precedes @LazySingleton,
        // and inject impl stubs before the final `}`.
        String updatedContent = CodeMergeHelper.injectBeforeAbstractClassEnd(
          existingContent,
          '@LazySingleton',
          abstractInjection,
        );
        updatedContent =
            CodeMergeHelper.injectBeforeLastBrace(updatedContent, implInjection);

        outputFile.writeAsStringSync(updatedContent);
        await formatFile(outputFile.path);
        print(
          '${outputFile.path} – appended ${newUsecases.length} new method(s): '
          '${newUsecases.map((e) => e.methodName).join(', ')}',
        );
        continue;
      }

      // ── First-time generation ─────────────────────────────────────────────
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

      final generateCode = template.renderString(map);
      outputFile.writeAsStringSync(generateCode);
      await formatFile(outputFile.path);
      print('${outputFile.path} generated');
    }
  }
}