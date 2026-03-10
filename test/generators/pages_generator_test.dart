import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:mica_cli/generators/pages_generator.dart';
import 'generator_test_helpers.dart';

void main() {
  late String template;

  setUpAll(() {
    template = readLocalTemplate('pages_template.mustache');
  });

  group('PagesGenerator – file path', () {
    test('creates file at featureName/presentations/pages/', () async {
      await withTempDir((tmp) async {
        final gen = PagesGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final expected = path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'presentations', 'pages', 'product_page.dart',
        );
        expect(File(expected).existsSync(), isTrue);
      });
    });

    test('file name uses snake_case of featureName', () async {
      await withTempDir((tmp) async {
        final gen = PagesGenerator(
          'user_management',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'user_management'));

        final expected = path.join(
          tmp.path, 'lib', 'modules/features', 'user_management',
          'presentations', 'pages', 'user_management_page.dart',
        );
        expect(File(expected).existsSync(), isTrue);
      });
    });
  });

  group('PagesGenerator – file content', () {
    test('generated file contains page class name', () async {
      await withTempDir((tmp) async {
        final gen = PagesGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'presentations', 'pages', 'product_page.dart',
        )).readAsStringSync();
        expect(content, contains('Page'));
      });
    });

    test('generated file extends StatelessWidget', () async {
      await withTempDir((tmp) async {
        final gen = PagesGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'presentations', 'pages', 'product_page.dart',
        )).readAsStringSync();
        expect(content, contains('StatelessWidget'));
      });
    });

    test('generated file contains @RoutePage annotation', () async {
      await withTempDir((tmp) async {
        final gen = PagesGenerator(
          'product',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'product'));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'product',
          'presentations', 'pages', 'product_page.dart',
        )).readAsStringSync();
        expect(content, contains('@RoutePage'));
      });
    });

    test('feature name is used in class name (PascalCase)', () async {
      await withTempDir((tmp) async {
        final gen = PagesGenerator(
          'user_management',
          client: mockClient(template),
          workingDir: tmp,
        );
        await gen.generate(buildParser(featureName: 'user_management'));

        final content = File(path.join(
          tmp.path, 'lib', 'modules/features', 'user_management',
          'presentations', 'pages', 'user_management_page.dart',
        )).readAsStringSync();
        expect(content, contains('UserManagement'));
      });
    });
  });
}
