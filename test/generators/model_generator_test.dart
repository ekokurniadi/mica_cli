import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:mica_cli/generators/model_generator.dart';
import 'generator_test_helpers.dart';

void main() {
  late String template;

  setUpAll(() {
    template = readLocalTemplate('models_template.mustache');
  });

  group('ModelGenerator – file path', () {
    test('root model written to featureName/data/models/', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = ModelGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final expected = path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'models', 'product_model.codegen.dart',
        );
        expect(File(expected).existsSync(), isTrue);
      });
    });

    test('nested model written to its own feature folder', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(
          featureName: 'user_management',
          extraProperties: [
            {
              'name': 'address',
              'type': 'Address',
              'is_primitive': false,
              'properties': [
                {'name': 'street', 'type': 'String'},
              ],
            },
          ],
        );
        final gen = ModelGenerator(
          'user_management',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final nestedFile = path.join(
          tmp.path, 'lib', 'modules/features', 'address',
          'data', 'models', 'address_model.codegen.dart',
        );
        expect(File(nestedFile).existsSync(), isTrue);
      });
    });

    test('deeply nested model gets its own feature folder', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(
          featureName: 'user_management',
          extraProperties: [
            {
              'name': 'address',
              'type': 'Address',
              'is_primitive': false,
              'properties': [
                {
                  'name': 'location',
                  'type': 'GeoLocation',
                  'is_primitive': false,
                  'properties': [
                    {'name': 'lat', 'type': 'double'},
                  ],
                },
              ],
            },
          ],
        );
        final gen = ModelGenerator(
          'user_management',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final geoFile = path.join(
          tmp.path, 'lib', 'modules/features', 'geo_location',
          'data', 'models', 'geo_location_model.codegen.dart',
        );
        expect(File(geoFile).existsSync(), isTrue);
      });
    });
  });

  group('ModelGenerator – file content', () {
    test('generated file contains model class name', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = ModelGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'models', 'product_model.codegen.dart',
        ));
        final content = file.readAsStringSync();
        expect(content, contains('ProductModel'));
      });
    });

    test('generated file contains fromJson factory', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = ModelGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'models', 'product_model.codegen.dart',
        ));
        final content = file.readAsStringSync();
        expect(content, contains('fromJson'));
      });
    });

    test('generated file contains toEntity() extension', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = ModelGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'models', 'product_model.codegen.dart',
        ));
        final content = file.readAsStringSync();
        expect(content, contains('toEntity()'));
      });
    });

    test('root model imports nested model from its own feature folder', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(
          featureName: 'user_management',
          packageName: 'my_app',
          extraProperties: [
            {
              'name': 'address',
              'type': 'Address',
              'is_primitive': false,
              'properties': [
                {'name': 'street', 'type': 'String'},
              ],
            },
          ],
        );
        final gen = ModelGenerator(
          'user_management',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final rootFile = File(path.join(
          tmp.path, 'lib', 'modules/features', 'user_management',
          'data', 'models', 'product_model.codegen.dart',
        ));
        final content = rootFile.readAsStringSync();
        expect(content, contains('address/data/models/address_model.codegen.dart'));
      });
    });
  });

  group('ModelGenerator – smart-append', () {
    test('appends new property to existing model file', () async {
      await withTempDir((tmp) async {
        final gen = ModelGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));
        await gen.generate(buildParser(
          featureName: 'product',
          extraProperties: [
            {'name': 'price', 'type': 'double', 'is_required': true},
          ],
        ));

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'models', 'product_model.codegen.dart',
        ));
        expect(file.readAsStringSync(), contains('price'));
      });
    });

    test('does not duplicate properties already in file', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = ModelGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);
        await gen.generate(parser);

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'data', 'models', 'product_model.codegen.dart',
        ));
        expect('id:'.allMatches(file.readAsStringSync()).length, 1);
      });
    });
  });
}
