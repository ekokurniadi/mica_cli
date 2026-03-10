import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:mica_cli/generators/repository_generator.dart';
import 'generator_test_helpers.dart';

void main() {
  late String template;

  setUpAll(() {
    template = readLocalTemplate('repository_template.mustache');
  });

  group('RepositoryGenerator – file path', () {
    test('creates file at featureName/domain/repository/', () async {
      await withTempDir((tmp) async {
        final gen = RepositoryGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final expected = path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'repository', 'product_repository.dart',
        );
        expect(File(expected).existsSync(), isTrue);
      });
    });

    test('file name uses snake_case of featureName', () async {
      await withTempDir((tmp) async {
        final gen = RepositoryGenerator(
          'user_management',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'user_management'));

        final expected = path.join(
          tmp.path, 'lib', 'modules/features', 'user_management',
          'domain', 'repository', 'user_management_repository.dart',
        );
        expect(File(expected).existsSync(), isTrue);
      });
    });
  });

  group('RepositoryGenerator – file content', () {
    test('generated file contains abstract class name', () async {
      await withTempDir((tmp) async {
        final gen = RepositoryGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'repository', 'product_repository.dart',
        ));
        expect(file.readAsStringSync(), contains('ProductRepository'));
      });
    });

    test('generated file contains usecase method signatures', () async {
      await withTempDir((tmp) async {
        final gen = RepositoryGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'repository', 'product_repository.dart',
        )).readAsStringSync();
        expect(content, contains('getProductById'));
        expect(content, contains('getAllProducts'));
      });
    });
  });

  group('RepositoryGenerator – smart-append', () {
    test('appends new usecase method to existing repository', () async {
      await withTempDir((tmp) async {
        final gen = RepositoryGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );

        // First generation with one usecase
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

        // Second generation adds another usecase
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
          'domain', 'repository', 'product_repository.dart',
        )).readAsStringSync();
        expect(content, contains('getProductById'));
        expect(content, contains('deleteProduct'));
      });
    });

    test('does not duplicate existing usecase methods', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = RepositoryGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);
        await gen.generate(parser);

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'repository', 'product_repository.dart',
        )).readAsStringSync();
        expect('getProductById('.allMatches(content).length, 1);
      });
    });
  });
}
