import 'dart:io';

void main() {
  final grammarsDir = Directory('lib/grammars');
  final themesDir = Directory('lib/themes');

  _genDartMap(
    grammarsDir,
    'embeddedGrammars',
    'lib/src/grammars.dart',
  );
  _genDartMap(
    themesDir,
    'embeddedThemes',
    'lib/src/themes.dart',
  );
}

void _genDartMap(Directory dir, String varName, String outputPath) {
  final entries = <String>[];
  final files = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    if (!file.path.endsWith('.json')) continue;
    final name = file.uri.pathSegments.last.replaceAll('.json', '');
    final content = File(file.path).readAsStringSync();
    final escaped = _escapeDartString(content);
    entries.add("  '$name': '$escaped'");
  }

  final dartContent =
      '// Generated - do not edit manually. Run gen_embedded.dart to regenerate.\n'
      'const $varName = <String, String>{\n'
      '${entries.join(',\n')}\n'
      '};\n';

  File(outputPath).writeAsStringSync(dartContent);
  print('Generated $outputPath with ${entries.length} entries');
}

String _escapeDartString(String s) {
  return s
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t')
      .replaceAll(r'$', r'\$');
}