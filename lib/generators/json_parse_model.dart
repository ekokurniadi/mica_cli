import 'package:recase/recase.dart';

class JsonParseModel {
  const JsonParseModel({
    required this.flutterPackageName,
    required this.featureName,
    required this.entity,
    this.usecases,
    required this.generatedPath,
    required this.datasources,
  });
  final String flutterPackageName;
  final String featureName;
  final EntityParserModel entity;
  final List<UseCase>? usecases;
  final String generatedPath;
  final List<dynamic> datasources;

  factory JsonParseModel.fromJson(Map<String, dynamic> json) => JsonParseModel(
        flutterPackageName: json['flutter_package_name'],
        featureName: json['feature_name'],
        entity: EntityParserModel.fromJson(json['entity']),
        usecases: json['usecases'] != null
            ? List.from(json['usecases'].map((e) => UseCase.fromJson(e)))
            : null,
        generatedPath: json['generated_path'],
        datasources: json['datasources'],
      );

  Map<String, dynamic> toJson() => {
        'flutter_package_name': flutterPackageName,
        'feature_name': featureName,
        'entity': entity.toJson(),
        'usecases':
            usecases != null ? List.from(usecases!.map((e) => e.toJson())) : null,
        'generated_path': generatedPath,
        'datasources': datasources,
      };
}

class EntityParserModel {
  const EntityParserModel({required this.name, required this.properties});

  final String name;
  final List<EntityPropertiesModel> properties;

  factory EntityParserModel.fromJson(Map<String, dynamic> json) =>
      EntityParserModel(
        name: json['name'],
        properties: List.from(
          json['properties'].map((e) => EntityPropertiesModel.fromJson(e)),
        ),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'properties': properties.map((e) => e.toJson()).toList(),
      };

  /// Returns this entity plus every nested entity found recursively.
  List<EntityParserModel> allNestedEntities() {
    final result = <EntityParserModel>[];
    for (final prop in properties) {
      if (prop.nestedProperties != null && prop.nestedProperties!.isNotEmpty) {
        final nested = EntityParserModel(
          name: prop.rawType,
          properties: prop.nestedProperties!,
        );
        result.add(nested);
        result.addAll(nested.allNestedEntities());
      }
    }
    return result;
  }
}

class EntityPropertiesModel {
  const EntityPropertiesModel({
    required this.name,
    required this.type,
    required this.rawType,
    this.isRequired = true,
    this.isList = false,
    this.isPrimitive = true,
    this.nestedProperties,
  });

  final String name;

  /// Decorated type: e.g. `required String` or `int?`
  final String type;

  /// Raw type name without required/? decoration: e.g. `String`, `Address`
  final String rawType;

  final bool? isRequired;
  final bool? isList;
  final bool? isPrimitive;

  /// Non-null when this property is a nested object (is_primitive: false)
  /// and a `properties` array was supplied in gen.json.
  final List<EntityPropertiesModel>? nestedProperties;

  factory EntityPropertiesModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String;
    final isRequired = json['is_required'] as bool? ?? true;
    final isList = json['is_list'] as bool? ?? false;
    final isPrimitive = json['is_primitive'] as bool? ?? true;

    // Base decorated type (entity/model suffix added later in generators)
    final String decoratedType;
    if (isList) {
      decoratedType =
          isRequired ? 'required List<$rawType>' : 'List<$rawType>?';
    } else {
      decoratedType = isRequired ? 'required $rawType' : '$rawType?';
    }

    List<EntityPropertiesModel>? nested;
    if (json['properties'] != null) {
      nested = List<EntityPropertiesModel>.from(
        (json['properties'] as List).map(
          (e) => EntityPropertiesModel.fromJson(e as Map<String, dynamic>),
        ),
      );
    }

    return EntityPropertiesModel(
      name: json['name'] as String,
      type: decoratedType,
      rawType: rawType,
      isRequired: isRequired,
      isList: isList,
      isPrimitive: isPrimitive,
      nestedProperties: nested,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'raw_type': rawType,
        'is_required': isRequired,
        'is_list': isList,
        'is_primitive': isPrimitive,
      };

  Map<String, dynamic> toJsonFillParser() => {
        'name': name,
        'type': isRequired == true ? 'required $type' : '$type?',
        'raw_type': rawType,
        'is_required': isRequired,
        'is_list': isList,
        'is_primitive': isPrimitive,
      };
}

class UseCase {
  final String name;
  final String methodName;
  final String returnType;
  final String param;
  final String paramName;
  const UseCase({
    required this.name,
    required this.methodName,
    required this.returnType,
    required this.param,
    required this.paramName,
  });

  factory UseCase.fromJson(Map<String, dynamic> json) => UseCase(
        name: json['name'],
        methodName: (json['name'] as String).camelCase,
        returnType: json['return_type'],
        param: json['param'],
        paramName: json['param_name'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'method_name': methodName,
        'return_type': returnType,
        'param': param,
        'param_name': paramName,
      };
}