import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

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
    // Resolve via package URI - grammars are under lib/ so they're accessible
    try {
      final uri = await Isolate.resolvePackageUri(
          Uri.parse('package:textmate_highlight/grammars/$language.json'));
      if (uri != null) {
        final file = File.fromUri(uri);
        if (file.existsSync()) {
          return file.readAsString();
        }
      }
    } catch (_) {}

    throw StateError('Could not find grammar file for "$language". '
        'Ensure the textmate_highlight package is properly installed.');
  }
}
