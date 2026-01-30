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
    'usecases': usecases != null
        ? List.from(usecases!.map((e) => e.toJson()))
        : null,
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
}

class EntityPropertiesModel {
  const EntityPropertiesModel({
    required this.name,
    required this.type,
    this.isRequired = true,
    this.isList = false,
    this.isPrimitive = false,
  });

  final String name;
  final String type;
  final bool? isRequired;
  final bool? isList;
  final bool? isPrimitive;

  factory EntityPropertiesModel.fromJson(Map<String, dynamic> json) =>
      EntityPropertiesModel(
        name: json['name'],
        type: json['is_required']
            ? "required ${json['type']}"
            : '${json['type']}?',
        isRequired: json['is_required'] ?? true,
        isList: json['is_list'] ?? false,
        isPrimitive: json['is_primitive'] ?? false,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'is_required': isRequired,
    'is_list': isList,
    'is_primitive': isPrimitive,
  };

  Map<String, dynamic> toJsonFillParser() => {
    'name': name,
    'type': isRequired == true ? 'required $type' : '$type?',
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
