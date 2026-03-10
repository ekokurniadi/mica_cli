import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mica_cli/generators/json_parse_model.dart';

/// Reads a local template file (relative to project root).
String readLocalTemplate(String name) =>
    File('lib/templates/$name').readAsStringSync();

/// A [MockClient] that returns [content] for any request.
MockClient mockClient(String content) =>
    MockClient((_) async => http.Response(content, 200));

/// A [MockClient] that maps URL substrings to template content.
MockClient mockClientForTemplates(Map<String, String> templates) {
  return MockClient((request) async {
    final url = request.url.toString();
    for (final entry in templates.entries) {
      if (url.contains(entry.key)) {
        return http.Response(entry.value, 200);
      }
    }
    return http.Response('', 404);
  });
}

/// Standard [JsonParseModel] used across generator tests.
JsonParseModel buildParser({
  String packageName = 'my_app',
  String featureName = 'product',
  String generatedPath = 'modules/features',
  List<Map<String, dynamic>>? extraProperties,
  List<Map<String, dynamic>>? usecases,
  List<String> datasources = const ['remote', 'local'],
}) {
  final properties = <Map<String, dynamic>>[
    {'name': 'id', 'type': 'int', 'is_required': false},
    {'name': 'name', 'type': 'String', 'is_required': true},
    ...?extraProperties,
  ];

  return JsonParseModel.fromJson({
    'flutter_package_name': packageName,
    'feature_name': featureName,
    'generated_path': generatedPath,
    'entity': {
      'name': 'Product',
      'properties': properties,
    },
    'usecases': usecases ??
        [
          {
            'name': 'GetProductById',
            'return_type': 'ProductModel',
            'param': 'int',
            'param_name': 'id',
          },
          {
            'name': 'GetAllProducts',
            'return_type': 'List<ProductModel>',
            'param': 'int',
            'param_name': 'page',
          },
        ],
    'datasources': datasources,
  });
}

/// Creates a temp directory and deletes it after [body] runs.
Future<void> withTempDir(Future<void> Function(Directory dir) body) async {
  final tmp = await Directory.systemTemp.createTemp('mica_test_');
  try {
    await body(tmp);
  } finally {
    await tmp.delete(recursive: true);
  }
}
