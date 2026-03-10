import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:mica_cli/generators/datasource_generator.dart';
import 'generator_test_helpers.dart';

void main() {
  late String template;

  setUpAll(() {
    template = readLocalTemplate('datasource_template.mustache');
  });

  group('DatasourceGenerator – file path', () {
    test('creates one file per datasource under data/datasources/{source}/', () async {
      await withTempDir((tmp) async {
        final gen = DatasourceGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(
          featureName: 'product',
          datasources: ['remote', 'local'],
        ));

        expect(
          File(path.join(
            tmp.path, 'lib', 'modules/features', 'product',
            'data', 'datasources', 'remote', 'product_remote_datasource.dart',
          )).existsSync(),
          isTrue,
        );
        expect(
          File(path.join(
            tmp.path, 'lib', 'modules/features', 'product',
            'data', 'datasources', 'local', 'product_local_datasource.dart',
          )).existsSync(),
          isTrue,
        );
      });
    });

    test('each datasource gets its own subfolder', () async {
      await withTempDir((tmp) async {
        final gen = DatasourceGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(
          featureName: 'product',
          datasources: ['remote', 'local'],
        ));

        expect(
          Directory(path.join(
            tmp.path, 'lib', 'modules/features', 'product',
            'data', 'datasources', 'remote',
          )).existsSync(),
          isTrue,
        );
        expect(
          Directory(path.join(
            tmp.path, 'lib', 'modules/features', 'product',
            'data', 'datasources', 'local',
          )).existsSync(),
          isTrue,
        );
      });
    });
  });

  group('DatasourceGenerator – file content', () {
    test('generated file contains abstract datasource class', () async {
      await withTempDir((tmp) async {
        final gen = DatasourceGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product', datasources: ['remote']));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'datasources', 'remote', 'product_remote_datasource.dart',
        )).readAsStringSync();
        expect(content, contains('DataSource'));
      });
    });

    test('generated file contains usecase method stubs', () async {
      await withTempDir((tmp) async {
        final gen = DatasourceGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product', datasources: ['remote']));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'datasources', 'remote', 'product_remote_datasource.dart',
        )).readAsStringSync();
        expect(content, contains('getProductById'));
        expect(content, contains('getAllProducts'));
      });
    });

    test('generated file contains impl class with @override stubs', () async {
      await withTempDir((tmp) async {
        final gen = DatasourceGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product', datasources: ['remote']));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'datasources', 'remote', 'product_remote_datasource.dart',
        )).readAsStringSync();
        expect(content, contains('@override'));
        expect(content, contains('UnimplementedError'));
      });
    });
  });

  group('DatasourceGenerator – smart-append', () {
    test('appends new usecase method to existing datasource file', () async {
      await withTempDir((tmp) async {
        final gen = DatasourceGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );

        await gen.generate(buildParser(
          featureName: 'product',
          datasources: ['remote'],
          usecases: [
            {
              'name': 'GetProductById',
              'return_type': 'ProductModel',
              'param': 'int',
              'param_name': 'id',
            },
          ],
        ));

        await gen.generate(buildParser(
          featureName: 'product',
          datasources: ['remote'],
          usecases: [
            {
              'name': 'GetProductById',
              'return_type': 'ProductModel',
              'param': 'int',
              'param_name': 'id',
            },
            {
              'name': 'DeleteProduct',
              'return_type': 'bool',
              'param': 'int',
              'param_name': 'id',
            },
          ],
        ));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'datasources', 'remote', 'product_remote_datasource.dart',
        )).readAsStringSync();
        expect(content, contains('deleteProduct'));
      });
    });

    test('does not duplicate existing datasource methods', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product', datasources: ['remote']);
        final gen = DatasourceGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);
        await gen.generate(parser);

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'datasources', 'remote', 'product_remote_datasource.dart',
        )).readAsStringSync();
        expect('getProductById('.allMatches(content).length, 2); // abstract + impl
      });
    });
  });
}
