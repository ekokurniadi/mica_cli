import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:mica_cli/generators/entity_generator.dart';
import 'generator_test_helpers.dart';

void main() {
  late String template;

  setUpAll(() {
    template = readLocalTemplate('entity_template.mustache');
  });

  group('EntityGenerator – file path', () {
    test('root entity written to featureName/domain/entities/', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = EntityGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final expected = path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'entities', 'product_entity.codegen.dart',
        );
        expect(File(expected).existsSync(), isTrue,
            reason: 'Root entity file should exist at $expected');
      });
    });

    test('nested entity written to its own feature folder', () async {
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
        final gen = EntityGenerator(
          'user_management',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final nestedFile = path.join(
          tmp.path, 'lib', 'modules/features', 'address',
          'domain', 'entities', 'address_entity.codegen.dart',
        );
        expect(File(nestedFile).existsSync(), isTrue,
            reason: 'Nested entity should be in address/ feature folder');
      });
    });

    test('deeply nested entity gets its own feature folder', () async {
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
        final gen = EntityGenerator(
          'user_management',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final geoFile = path.join(
          tmp.path, 'lib', 'modules/features', 'geo_location',
          'domain', 'entities', 'geo_location_entity.codegen.dart',
        );
        expect(File(geoFile).existsSync(), isTrue,
            reason: 'Deeply nested entity should have its own feature folder');
      });
    });
  });

  group('EntityGenerator – file content', () {
    test('generated file contains entity class name', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = EntityGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'entities', 'product_entity.codegen.dart',
        ));
        final content = file.readAsStringSync();
        expect(content, contains('ProductEntity'));
      });
    });

    test('generated file contains property names', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = EntityGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'entities', 'product_entity.codegen.dart',
        ));
        final content = file.readAsStringSync();
        expect(content, contains('id'));
        expect(content, contains('name'));
      });
    });

    test('root entity imports nested entity from its own feature folder', () async {
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
        final gen = EntityGenerator(
          'user_management',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final rootFile = File(path.join(
          tmp.path, 'lib', 'modules/features', 'user_management',
          'domain', 'entities', 'product_entity.codegen.dart',
        ));
        final content = rootFile.readAsStringSync();
        expect(content, contains('address/domain/entities/address_entity.codegen.dart'));
      });
    });

    test('generated file contains toModel() extension', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = EntityGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser);

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'entities', 'product_entity.codegen.dart',
        ));
        final content = file.readAsStringSync();
        expect(content, contains('toModel()'));
      });
    });
  });

  group('EntityGenerator – smart-append', () {
    test('appends new property to existing entity file', () async {
      await withTempDir((tmp) async {
        // First generation
        final parser1 = buildParser(featureName: 'product');
        final gen = EntityGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(parser1);

        // Second generation with an extra property
        final parser2 = buildParser(
          featureName: 'product',
          extraProperties: [
            {'name': 'price', 'type': 'double', 'is_required': true},
          ],
        );
        final gen2 = EntityGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen2.generate(parser2);

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'entities', 'product_entity.codegen.dart',
        ));
        final content = file.readAsStringSync();
        expect(content, contains('price'));
      });
    });

    test('does not duplicate properties already in file', () async {
      await withTempDir((tmp) async {
        final parser = buildParser(featureName: 'product');
        final gen = EntityGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        // Generate twice with same parser
        await gen.generate(parser);
        await gen.generate(parser);

        final file = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'domain', 'entities', 'product_entity.codegen.dart',
        ));
        final content = file.readAsStringSync();
        // 'id:' should appear exactly once in the toModel mapping
        expect('id:'.allMatches(content).length, 1);
      });
    });
  });
}
