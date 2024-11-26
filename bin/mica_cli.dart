import 'dart:convert';
import 'dart:io';

import 'package:mica_cli/generators/datasource_generator.dart';
import 'package:mica_cli/generators/json_parse_model.dart';
import 'package:mica_cli/generators/entity_generator.dart';
import 'package:mica_cli/generators/model_generator.dart';
import 'package:mica_cli/generators/pages_generator.dart';
import 'package:mica_cli/generators/repository_generator.dart';
import 'package:mica_cli/generators/repository_impl_generator.dart';
import 'package:mica_cli/generators/usecase_generator.dart';
import 'package:path/path.dart';
import 'package:args/args.dart';

Future<void> main(List<String> args) async{
  final parser = ArgParser()
    ..addOption(
      'json_path',
      help: 'Path json file template',
    )
    ..addFlag(
      'all',
      abbr: 'a',
      defaultsTo: false,
      negatable: false,
      help: 'Generate all',
    )
    ..addFlag(
      'model',
      abbr: 'm',
      defaultsTo: false,
      negatable: false,
      help: 'Generate model',
    )
    ..addFlag(
      'entity',
      abbr: 'e',
      defaultsTo: false,
      negatable: false,
      help: 'Generate entity',
    )
    ..addFlag(
      'usecase',
      abbr: 'u',
      defaultsTo: false,
      negatable: false,
      help: 'Generate usecase',
    )
    ..addFlag(
      'repository',
      abbr: 'r',
      defaultsTo: false,
      negatable: false,
      help: 'Generate repository',
    )
    ..addFlag(
      'datasources',
      abbr: 'd',
      defaultsTo: false,
      negatable: false,
      help: 'Generate datasources',
    )
    ..addFlag(
      'page',
      abbr: 'p',
      defaultsTo: false,
      negatable: false,
      help: 'Generate page',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display help menu',
    );

  final argResults = parser.parse(args);
  String jsonPath = '';

  if (argResults['json_path'] == null) {
    jsonPath = 'gen.json';
  } else {
    jsonPath = argResults['json_path'] as String;
  }

  final currentDir = Directory.current;
  final jsonFile = File(
    join(
      currentDir.path,
      jsonPath,
    ),
  ).readAsStringSync();

  if (argResults['help'] as bool || args.isEmpty) {
    print('Usage: mica_cli [options]');
    print(parser.usage);
    exit(0);
  }

  final isGenerateModel = argResults['model'] as bool;
  final isGenerateEntity = argResults['entity'] as bool;
  final isGenerateUseCase = argResults['usecase'] as bool;
  final isGenerateRepository = argResults['repository'] as bool;
  final isGenerateDataSource = argResults['datasources'] as bool;
  final isGenerateAll = argResults['all'] as bool;
  final isGeneratePage = argResults['page'] as bool;

  final model = JsonParseModel.fromJson(
    json.decode(jsonFile),
  );

  final entity = EntityGenerator(model.featureName);
  final modelGen = ModelGenerator(model.featureName);
  final usecase = UsecaseGenerator(model.featureName);
  final repo = RepositoryGenerator(model.featureName);
  final repoImpl = RepositoryImplGenerator(model.featureName);
  final datasources = DatasourceGenerator(model.featureName);
  final page = PagesGenerator(model.featureName);

  if (isGenerateAll) {
     entity.generate(model);
     modelGen.generate(model);
     usecase.generate(model);
     repo.generate(model);
     repoImpl.generate(model);
    await datasources.generate(model);
     page.generate(model);
  } else {
    if (isGenerateEntity) {
       entity.generate(model);
    }

    if (isGenerateModel) {
       modelGen.generate(model);
    }

    if (isGenerateRepository) {
       repo.generate(model);
       repoImpl.generate(model);
    }

    if (isGenerateUseCase) {
       usecase.generate(model);
    }

    if (isGenerateDataSource) {
      await datasources.generate(model);
    }

    if (isGeneratePage) {
       page.generate(model);
    }
  }
}
