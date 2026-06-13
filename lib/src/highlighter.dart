import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:textmate_highlight/src/grammars.dart';
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

  /// Highlights incrementally, reusing a previous [checkpoint] when
  /// content has been appended.
  ///
  /// When streaming code, new content is always appended to the end.
  /// Instead of re-parsing the entire document, this method resumes
  /// from the checkpoint's position, parsing only the new content.
  /// This reduces parsing time from O(total_content) to O(new_content).
  ///
  /// The [fullCode] must start with the same text that was used to
  /// create the checkpoint.
  ///
  /// Returns an [IncrementalHighlightResult] containing the tokens
  /// and a new checkpoint for the next incremental update.
  IncrementalHighlightResult highlightIncremental(
    String fullCode,
    ParseCheckpoint? checkpoint,
  ) {
    final result = SpanParser.parseIncremental(_grammar, fullCode, checkpoint);
    return IncrementalHighlightResult(
      tokens: [
        for (final span in result.spans)
          HighlightedToken(
            start: span.start,
            end: span.end,
            scopes: span.scopes,
          ),
      ],
      checkpoint: result.checkpoint,
    );
  }

  static Future<String> _loadGrammar(String language) async {
    if (embeddedGrammars.containsKey(language)) {
      return embeddedGrammars[language]!;
    }

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

/// Result of an incremental highlight operation.
///
/// Contains the full list of highlighted tokens and a checkpoint
/// that can be used for the next incremental update when more
/// content is appended.
class IncrementalHighlightResult {
  IncrementalHighlightResult({
    required this.tokens,
    required this.checkpoint,
  });

  /// The complete list of highlighted tokens for the full source.
  final List<HighlightedToken> tokens;

  /// A checkpoint that captures the parser state, allowing the next
  /// incremental highlight to resume from this position.
  final ParseCheckpoint checkpoint;
}
