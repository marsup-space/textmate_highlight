import 'dart:convert';
import 'dart:io';

import 'package:textmate_highlight/src/span_parser.dart';
import 'package:textmate_highlight/src/token.dart';

/// VSCode-quality syntax highlighting using TextMate grammars.
///
/// Pure Dart implementation - no Flutter dependency.
///
/// Usage:
/// ```dart
/// await Highlighter.initialize(['dart', 'python']);
/// final highlighter = Highlighter(language: 'dart');
/// final tokens = highlighter.highlight(code);
/// for (final token in tokens) {
///   final style = theme.getStyle(token.scopes);
///   // Apply style to token.text(source)
/// }
/// ```
class Highlighter {
  static final _cache = <String, Grammar>{};

  /// Initializes the [Highlighter] with the given list of [languages].
  ///
  /// Must be called before creating any [Highlighter]s.
  /// Supported languages: dart, python, javascript, typescript, rust, go,
  /// java, kotlin, swift, html, css, json, yaml, sql, and more.
  static Future<void> initialize(List<String> languages) async {
    for (final language in languages) {
      if (_cache.containsKey(language)) continue;
      final json = await _loadGrammar(language);
      _cache[language] = Grammar.fromJson(jsonDecode(json));
    }
  }

  /// Adds a custom language from a JSON grammar string.
  static void addLanguage(String name, String json) {
    _cache.putIfAbsent(name, () => Grammar.fromJson(jsonDecode(json)));
  }

  /// Check if a language has been loaded.
  static bool isLanguageLoaded(String language) => _cache.containsKey(language);

  /// The language of this highlighter.
  final String language;

  late final Grammar _grammar;

  /// Creates a [Highlighter] for the given [language].
  /// The language must have been loaded via [initialize] or [addLanguage].
  Highlighter({required this.language}) {
    _grammar = _cache[language]!;
  }

  /// Highlights the given [code] and returns a list of [HighlightedToken]s.
  ///
  /// Each token contains its position in the source string and its
  /// TextMate scope stack, which can be used to apply styling.
  List<HighlightedToken> highlight(String code) {
    final spans = SpanParser.parse(_grammar, code);
    return [
      for (final span in spans)
        HighlightedToken(
          start: span.start,
          end: span.end,
          scopes: span.scopes,
        ),
    ];
  }

  static Future<String> _loadGrammar(String language) async {
    // Try multiple paths to find the grammar file
    final paths = <String>[
      'grammars/$language.json',
      'package:textmate_highlight/grammars/$language.json',
    ];

    // Find package directory
    final packageDir = _findPackageDir();
    if (packageDir != null) {
      paths.insert(0, '$packageDir/grammars/$language.json');
    }

    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        return file.readAsString();
      }
    }

    throw StateError(
        'Could not find grammar file for "$language". Searched: $paths');
  }

  static String? _findPackageDir() {
    final scriptPath = Platform.script.toFilePath();
    var current = File(scriptPath).parent.path;
    while (current != '/') {
      if (File('$current/pubspec.yaml').existsSync()) {
        final name = _getPackageName(current);
        if (name == 'textmate_highlight') return current;
      }
      current = Directory(current).parent.path;
    }
    return null;
  }

  static String _getPackageName(String dir) {
    try {
      final content = File('$dir/pubspec.yaml').readAsStringSync();
      final match =
          RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
      return match?.group(1) ?? '';
    } catch (_) {
      return '';
    }
  }
}
