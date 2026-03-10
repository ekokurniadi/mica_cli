import 'package:test/test.dart';
import 'package:mica_cli/generators/json_parse_model.dart';

void main() {
  group('EntityPropertiesModel.fromJson', () {
    test('parses primitive property with defaults', () {
      final prop = EntityPropertiesModel.fromJson({
        'name': 'id',
        'type': 'int',
      });

      expect(prop.name, 'id');
      expect(prop.rawType, 'int');
      expect(prop.isRequired, true);
      expect(prop.isList, false);
      expect(prop.isPrimitive, true);
      expect(prop.nestedProperties, isNull);
      expect(prop.type, 'required int');
    });

    test('parses optional property', () {
      final prop = EntityPropertiesModel.fromJson({
        'name': 'nickname',
        'type': 'String',
        'is_required': false,
      });

      expect(prop.isRequired, false);
      expect(prop.type, 'String?');
    });

    test('parses list property', () {
      final prop = EntityPropertiesModel.fromJson({
        'name': 'tags',
        'type': 'String',
        'is_list': true,
      });

      expect(prop.isList, true);
      expect(prop.type, 'required List<String>');
    });

    test('parses optional list property', () {
      final prop = EntityPropertiesModel.fromJson({
        'name': 'tags',
        'type': 'String',
        'is_list': true,
        'is_required': false,
      });

      expect(prop.type, 'List<String>?');
    });

    test('parses non-primitive property with nested properties', () {
      final prop = EntityPropertiesModel.fromJson({
        'name': 'address',
        'type': 'Address',
        'is_primitive': false,
        'properties': [
          {'name': 'street', 'type': 'String'},
        ],
      });

      expect(prop.isPrimitive, false);
      expect(prop.rawType, 'Address');
      expect(prop.nestedProperties, isNotNull);
      expect(prop.nestedProperties!.length, 1);
      expect(prop.nestedProperties!.first.name, 'street');
    });

    test('parses non-primitive without properties array', () {
      final prop = EntityPropertiesModel.fromJson({
        'name': 'address',
        'type': 'Address',
        'is_primitive': false,
      });

      expect(prop.isPrimitive, false);
      expect(prop.nestedProperties, isNull);
    });
  });

  group('EntityParserModel.fromJson', () {
    test('parses name and properties', () {
      final entity = EntityParserModel.fromJson({
        'name': 'Product',
        'properties': [
          {'name': 'id', 'type': 'int'},
          {'name': 'name', 'type': 'String'},
        ],
      });

      expect(entity.name, 'Product');
      expect(entity.properties.length, 2);
    });
  });

  group('EntityParserModel.allNestedEntities', () {
    test('returns empty list when no nested properties', () {
      final entity = EntityParserModel.fromJson({
        'name': 'Product',
        'properties': [
          {'name': 'id', 'type': 'int'},
          {'name': 'name', 'type': 'String'},
        ],
      });

      expect(entity.allNestedEntities(), isEmpty);
    });

    test('returns one nested entity', () {
      final entity = EntityParserModel.fromJson({
        'name': 'UserManagement',
        'properties': [
          {'name': 'id', 'type': 'int'},
          {
            'name': 'address',
            'type': 'Address',
            'is_primitive': false,
            'properties': [
              {'name': 'street', 'type': 'String'},
            ],
          },
        ],
      });

      final nested = entity.allNestedEntities();
      expect(nested.length, 1);
      expect(nested.first.name, 'Address');
      expect(nested.first.properties.first.name, 'street');
    });

    test('returns multiple nested entities at same level', () {
      final entity = EntityParserModel.fromJson({
        'name': 'UserManagement',
        'properties': [
          {
            'name': 'address',
            'type': 'Address',
            'is_primitive': false,
            'properties': [
              {'name': 'street', 'type': 'String'},
            ],
          },
          {
            'name': 'roles',
            'type': 'Role',
            'is_primitive': false,
            'is_list': true,
            'properties': [
              {'name': 'roleId', 'type': 'int'},
            ],
          },
        ],
      });

      final nested = entity.allNestedEntities();
      expect(nested.length, 2);
      expect(nested.map((e) => e.name), containsAll(['Address', 'Role']));
    });

    test('returns deeply nested entities in depth-first order', () {
      final entity = EntityParserModel.fromJson({
        'name': 'UserManagement',
        'properties': [
          {
            'name': 'address',
            'type': 'Address',
            'is_primitive': false,
            'properties': [
              {'name': 'street', 'type': 'String'},
              {
                'name': 'location',
                'type': 'GeoLocation',
                'is_primitive': false,
                'properties': [
                  {'name': 'lat', 'type': 'double'},
                  {'name': 'lng', 'type': 'double'},
                ],
              },
            ],
          },
        ],
      });

      final nested = entity.allNestedEntities();
      expect(nested.length, 2);
      // depth-first: Address comes before GeoLocation
      expect(nested[0].name, 'Address');
      expect(nested[1].name, 'GeoLocation');
    });

    test('returns all entities from gen.json-style structure', () {
      final entity = EntityParserModel.fromJson({
        'name': 'UserManagement',
        'properties': [
          {'name': 'id', 'type': 'int'},
          {
            'name': 'address',
            'type': 'Address',
            'is_primitive': false,
            'properties': [
              {'name': 'street', 'type': 'String'},
              {
                'name': 'location',
                'type': 'GeoLocation',
                'is_primitive': false,
                'properties': [
                  {'name': 'lat', 'type': 'double'},
                  {'name': 'lng', 'type': 'double'},
                ],
              },
            ],
          },
          {
            'name': 'roles',
            'type': 'Role',
            'is_primitive': false,
            'is_list': true,
            'properties': [
              {'name': 'roleId', 'type': 'int'},
              {'name': 'roleName', 'type': 'String'},
            ],
          },
        ],
      });

      final nested = entity.allNestedEntities();
      expect(nested.length, 3);
      expect(nested.map((e) => e.name).toList(), ['Address', 'GeoLocation', 'Role']);
    });

    test('ignores non-primitive properties with no nested properties array', () {
      final entity = EntityParserModel.fromJson({
        'name': 'Product',
        'properties': [
          {
            'name': 'category',
            'type': 'Category',
            'is_primitive': false,
            // no 'properties' key
          },
        ],
      });

      expect(entity.allNestedEntities(), isEmpty);
    });
  });

  group('JsonParseModel.fromJson', () {
    test('parses all top-level fields', () {
      final model = JsonParseModel.fromJson({
        'flutter_package_name': 'my_app',
        'feature_name': 'products',
        'generated_path': 'modules/features',
        'entity': {
          'name': 'Product',
          'properties': [
            {'name': 'id', 'type': 'int'},
          ],
        },
        'usecases': [
          {
            'name': 'GetProductById',
            'return_type': 'ProductModel',
            'param': 'int',
            'param_name': 'id',
          },
        ],
        'datasources': ['remote', 'local'],
      });

      expect(model.flutterPackageName, 'my_app');
      expect(model.featureName, 'products');
      expect(model.generatedPath, 'modules/features');
      expect(model.entity.name, 'Product');
      expect(model.usecases, isNotNull);
      expect(model.usecases!.length, 1);
      expect(model.datasources, ['remote', 'local']);
    });

    test('parses with null usecases', () {
      final model = JsonParseModel.fromJson({
        'flutter_package_name': 'my_app',
        'feature_name': 'products',
        'generated_path': 'modules/features',
        'entity': {
          'name': 'Product',
          'properties': [],
        },
        'usecases': null,
        'datasources': [],
      });

      expect(model.usecases, isNull);
    });
  });

  group('UseCase.fromJson', () {
    test('parses all fields and generates camelCase methodName', () {
      final usecase = UseCase.fromJson({
        'name': 'GetProductById',
        'return_type': 'ProductModel',
        'param': 'int',
        'param_name': 'id',
      });

      expect(usecase.name, 'GetProductById');
      expect(usecase.methodName, 'getProductById');
      expect(usecase.returnType, 'ProductModel');
      expect(usecase.param, 'int');
      expect(usecase.paramName, 'id');
    });
  });
}
