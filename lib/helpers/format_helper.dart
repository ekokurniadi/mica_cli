import 'dart:io';

Future<void> formatFile(String filePath) async {
  try {
    final result = await Process.run('dart', ['format', filePath]);

    if (result.exitCode == 0) {
      print('Formatting successful: ${result.stdout}');
    } else {
      print('Formatting failed: ${result.stderr}');
    }
  } catch (e) {
    print('Error running dart format: $e');
  }
}
