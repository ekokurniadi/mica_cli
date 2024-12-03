## Getting Started
## Installation
```bash
dart pub global activate --source git https://github.com/ekokurniadi/mica_cli.git
```
## Create file json on root project with name gen.json
```json
{
    "flutter_package_name": "flutter_pos",            # Project name, you can get it from pubspec.yaml
    "feature_name": "products",                       # Feature name
    "generated_path":"modules/ronpos/features",       # Target generated file
    "entity": {
        "name": "Product",                            # Entity Name
        "properties": [                               # Entity Properties
            {
                "name": "id",                         # Name of property using format camelCase
                "type": "int",                        # Data type of property (using dart data type)
                "is_required": false                  # Set the parameters is required or optional
            },
            {
                "name": "name",
                "type": "String",
                "is_required": true
            }
        ]
    },
    "usecases": [                                    # List of usecases on this feature
        {
            "name": "GetProductById",                # Name of usecase
            "return_type": "ProductModel",           # Return type
            "param": "int",                          # Parameter data type
            "param_name": "id"                       # Parameter name
        },
        {
            "name": "GetAllProducts",
            "return_type": "List<ProductModel>",
            "param": "int",
            "param_name": "page"
        }
    ],
    "datasources":["local","remote"]                # Datasources
}
```

## Using this cli
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
