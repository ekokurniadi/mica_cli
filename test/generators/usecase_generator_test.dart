import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:mica_cli/generators/usecase_generator.dart';
import 'generator_test_helpers.dart';

void main() {
  late String template;

  setUpAll(() {
    template = readLocalTemplate('usecase_template.mustache');
  });

  group('UsecaseGenerator – file path', () {
    test('creates one file per usecase in domain/usecases/', () async {
      await withTempDir((tmp) async {
        final gen = UsecaseGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final dir = path.join(
          tmp.path, 'lib', 'modules/features', 'product', 'domain', 'usecases',
        );
        expect(
          File(path.join(dir, 'get_product_by_id_usecase.dart')).existsSync(),
          isTrue,
        );
        expect(
          File(path.join(dir, 'get_all_products_usecase.dart')).existsSync(),
          isTrue,
        );
      });
    });

    test('file name uses snake_case of usecase name', () async {
      await withTempDir((tmp) async {
        final gen = UsecaseGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(
          featureName: 'product',
          usecases: [
            {
              'name': 'GetProductBySku',
              'return_type': 'ProductModel',
              'param': 'String',
              'param_name': 'sku',
            },
          ],
        ));

        final expected = path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'usecases', 'get_product_by_sku_usecase.dart',
        );
        expect(File(expected).existsSync(), isTrue);
      });
    });
  });

  group('UsecaseGenerator – file content', () {
    test('generated file contains UseCase class name', () async {
      await withTempDir((tmp) async {
        final gen = UsecaseGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'usecases', 'get_product_by_id_usecase.dart',
        )).readAsStringSync();
        expect(content, contains('GetProductByIdUseCase'));
      });
    });

    test('generated file contains repository reference', () async {
      await withTempDir((tmp) async {
        final gen = UsecaseGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'usecases', 'get_product_by_id_usecase.dart',
        )).readAsStringSync();
        expect(content, contains('ProductRepository'));
      });
    });

    test('generated file contains return type and param', () async {
      await withTempDir((tmp) async {
        final gen = UsecaseGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'usecases', 'get_product_by_id_usecase.dart',
        )).readAsStringSync();
        expect(content, contains('ProductModel'));
        expect(content, contains('int'));
      });
    });
  });

  group('UsecaseGenerator – skip existing', () {
    test('skips generation if usecase file already exists', () async {
      await withTempDir((tmp) async {
        final gen = UsecaseGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );

        // First generation
        await gen.generate(buildParser(featureName: 'product'));

        final filePath = path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'usecases', 'get_product_by_id_usecase.dart',
        );

        // Manually modify the file to simulate developer customization
        final file = File(filePath);
        file.writeAsStringSync('// custom content');

        // Second generation — should not overwrite
        await gen.generate(buildParser(featureName: 'product'));

        expect(file.readAsStringSync(), '// custom content');
      });
    });
  });
}
