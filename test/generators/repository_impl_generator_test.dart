import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:mica_cli/generators/repository_impl_generator.dart';
import 'generator_test_helpers.dart';

void main() {
  late String template;

  setUpAll(() {
    template = readLocalTemplate('repository_impl_template.mustache');
  });

  group('RepositoryImplGenerator – file path', () {
    test('creates file at featureName/data/repository/', () async {
      await withTempDir((tmp) async {
        final gen = RepositoryImplGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final expected = path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'repository', 'product_repository_impl.dart',
        );
        expect(File(expected).existsSync(), isTrue);
      });
    });
  });

  group('RepositoryImplGenerator – file content', () {
    test('generated file contains impl class name', () async {
      await withTempDir((tmp) async {
        final gen = RepositoryImplGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'repository', 'product_repository_impl.dart',
        )).readAsStringSync();
        expect(content, contains('ProductRepositoryImpl'));
      });
    });

    test('generated file contains datasource field for each source', () async {
      await withTempDir((tmp) async {
        final gen = RepositoryImplGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(
          featureName: 'product',
          datasources: ['remote', 'local'],
        ));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'repository', 'product_repository_impl.dart',
        )).readAsStringSync();
        expect(content, anyOf(contains('RemoteDataSource'), contains('remote')));
        expect(content, anyOf(contains('LocalDataSource'), contains('local')));
      });
    });

    test('generated file contains @override method stubs', () async {
      await withTempDir((tmp) async {
        final gen = RepositoryImplGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'repository', 'product_repository_impl.dart',
        )).readAsStringSync();
        expect(content, contains('@override'));
        expect(content, contains('getProductById'));
      });
    });
  });

  group('RepositoryImplGenerator – smart-append', () {
    test('appends new usecase override to existing impl file', () async {
      await withTempDir((tmp) async {
        final gen = RepositoryImplGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );

        await gen.generate(buildParser(
          featureName: 'product',
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
          'data', 'repository', 'product_repository_impl.dart',
        )).readAsStringSync();
        expect(content, contains('deleteProduct'));
      });
    });

    test('does not duplicate existing override methods', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = RepositoryImplGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);
        await gen.generate(parser);

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'repository', 'product_repository_impl.dart',
        )).readAsStringSync();
        expect('getProductById('.allMatches(content).length, 1);
      });
    });
  });
}
