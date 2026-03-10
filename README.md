## Getting Started

## Installation
```bash
dart pub global activate --source git https://github.com/ekokurniadi/mica_cli.git
```

## Create file json on root project with name gen.json

### Basic example (flat properties)
```json
{
    "flutter_package_name": "flutter_pos",
    "feature_name": "products",
    "generated_path": "modules/ronpos/features",
    "entity": {
        "name": "Product",
        "properties": [
            {
                "name": "id",
                "type": "int",
                "is_required": false
            },
            {
                "name": "name",
                "type": "String",
                "is_required": true
            }
        ]
    },
    "usecases": [
        {
            "name": "GetProductById",
            "return_type": "ProductModel",
            "param": "int",
            "param_name": "id"
        },
        {
            "name": "GetAllProducts",
            "return_type": "List<ProductModel>",
            "param": "int",
            "param_name": "page"
        }
    ],
    "datasources": ["local", "remote"]
}
```

### Nested object example
Use `is_primitive: false` and provide a `properties` array to define nested objects. Nested objects can be deeply nested (any depth).

```json
{
    "flutter_package_name": "flutter_pos",
    "feature_name": "user_management",
    "generated_path": "modules/ronpos/features",
    "entity": {
        "name": "UserManagement",
        "properties": [
            {
                "name": "id",
                "type": "int",
                "is_required": false
            },
            {
                "name": "name",
                "type": "String",
                "is_required": true
            },
            {
                "name": "address",
                "type": "Address",
                "is_required": false,
                "is_primitive": false,
                "is_list": false,
                "properties": [
                    { "name": "street", "type": "String", "is_required": true },
                    { "name": "city",   "type": "String", "is_required": true },
                    {
                        "name": "location",
                        "type": "GeoLocation",
                        "is_required": false,
                        "is_primitive": false,
                        "is_list": false,
                        "properties": [
                            { "name": "lat", "type": "double", "is_required": true },
                            { "name": "lng", "type": "double", "is_required": true }
                        ]
                    }
                ]
            },
            {
                "name": "roles",
                "type": "Role",
                "is_required": true,
                "is_primitive": false,
                "is_list": true,
                "properties": [
                    { "name": "roleId",   "type": "int",    "is_required": true },
                    { "name": "roleName", "type": "String", "is_required": true }
                ]
            }
        ]
    },
    "usecases": [
        {
            "name": "GetUserById",
            "return_type": "UserManagementModel",
            "param": "int",
            "param_name": "id"
        }
    ],
    "datasources": ["remote", "local"]
}
```

### Property fields

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | String | yes | — | Property name (camelCase) |
| `type` | String | yes | — | Dart type (e.g. `String`, `int`, `Address`) |
| `is_required` | bool | no | `true` | Whether the field is required |
| `is_list` | bool | no | `false` | Whether the field is a `List<Type>` |
| `is_primitive` | bool | no | `true` | Set `false` for nested objects; enables sub-`properties` |
| `properties` | array | no | — | Nested property definitions (only when `is_primitive: false`) |

---

## Generated folder structure

Each **nested object** is generated into its **own feature folder** (named after the type, snake_case), at the same level as the root feature. This keeps nested types independently reusable.

Given the example above with `generated_path: "modules/ronpos/features"`:

```
lib/modules/ronpos/features/
├── user_management/
│   ├── domain/
│   │   ├── entities/
│   │   │   └── user_management_entity.codegen.dart
│   │   ├── repository/
│   │   │   └── user_management_repository.dart
│   │   └── usecases/
│   │       ├── get_user_by_id_usecase.dart
│   │       └── get_all_users_usecase.dart
│   ├── data/
│   │   ├── models/
│   │   │   └── user_management_model.codegen.dart
│   │   ├── repository/
│   │   │   └── user_management_repository_impl.dart
│   │   └── datasources/
│   │       ├── remote/
│   │       │   └── user_management_remote_datasource.dart
│   │       └── local/
│   │           └── user_management_local_datasource.dart
│   └── presentations/
│       └── pages/
│           └── user_management_page.dart
│
├── address/                          ← nested object, own folder
│   ├── domain/entities/
│   │   └── address_entity.codegen.dart
│   └── data/models/
│       └── address_model.codegen.dart
│
├── geo_location/                     ← deeply nested (inside address), own folder
│   ├── domain/entities/
│   │   └── geo_location_entity.codegen.dart
│   └── data/models/
│       └── geo_location_model.codegen.dart
│
└── role/                             ← nested list object, own folder
    ├── domain/entities/
    │   └── role_entity.codegen.dart
    └── data/models/
        └── role_model.codegen.dart
```

Import paths in the root entity/model are automatically generated to point to the correct nested feature folders.

---

## Using this CLI
```bash
mica_cli
Usage: mica_cli [options]
    --json_path      Path json file template
-a, --all            Generate all
-m, --model          Generate model
-e, --entity         Generate entity
-u, --usecase        Generate usecase
-r, --repository     Generate repository
-d, --datasources    Generate datasources
-p, --page           Generate page
-h, --help           Display help menu
```
