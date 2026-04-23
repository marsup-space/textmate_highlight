import 'dart:convert';
import 'dart:io';

/// A text style with optional color and font attributes.
/// Platform-independent - map these to your UI framework's text style.
class TextStyle {
  /// Foreground color as 0xAARRGGBB int.
  final int? color;

  /// Whether the text is bold.
  final bool bold;

  /// Whether the text is italic.
  final bool italic;

  /// Whether the text is underlined.
  final bool underline;

  const TextStyle({
    this.color,
    this.bold = false,
    this.italic = false,
    this.underline = false,
  });

  static TextStyle? fromJson(Map? settings) {
    if (settings == null) return null;

    int? color;
    final foreground = settings['foreground'];
    if (foreground is String && foreground.startsWith('#')) {
      color = int.parse(foreground.substring(1), radix: 16) | 0xFF000000;
    }

    bool bold = false;
    bool italic = false;
    bool underline = false;

    final fontStyle = settings['fontStyle'];
    if (fontStyle is String) {
      final parts = fontStyle.split(' ');
      for (final part in parts) {
        switch (part) {
          case 'bold':
            bold = true;
          case 'italic':
            italic = true;
          case 'underline':
            underline = true;
          case 'strikethrough':
            break;
        }
      }
    }

    return TextStyle(
      color: color,
      bold: bold,
      italic: italic,
      underline: underline,
    );
  }

  @override
  String toString() =>
      'TextStyle(color: ${color != null ? '0x${color!.toRadixString(16)}' : null}, bold: $bold, italic: $italic, underline: $underline)';
}

/// A TextMate theme that maps scope names to text styles.
class HighlightTheme {
  TextStyle? _fallback;
  final _scopes = <String, TextStyle>{};

  HighlightTheme();

  /// Load a theme from a JSON string.
  factory HighlightTheme.fromJson(String json) {
    final theme = HighlightTheme();
    theme._parseTheme(json);
    return theme;
  }

  /// Load a theme from a list of JSON strings (merged in order).
  factory HighlightTheme.fromJsonList(List<String> jsonList) {
    final theme = HighlightTheme();
    for (final json in jsonList) {
      theme._parseTheme(json);
    }
    return theme;
  }

  /// Load a dark theme from the bundled theme files.
  static Future<HighlightTheme> loadDarkTheme() {
    return loadFromAssets([
      'themes/dark_vs.json',
      'themes/dark_plus.json',
    ]);
  }

  /// Load a light theme from the bundled theme files.
  static Future<HighlightTheme> loadLightTheme() {
    return loadFromAssets([
      'themes/light_vs.json',
      'themes/light_plus.json',
    ]);
  }

  /// Load themes from asset paths relative to the package directory.
  static Future<HighlightTheme> loadFromAssets(List<String> assetPaths) async {
    final theme = HighlightTheme();
    for (final path in assetPaths) {
      final file = File(path);
      if (file.existsSync()) {
        theme._parseTheme(await file.readAsString());
      } else {
        // Try resolving relative to package
        final scriptPath = Platform.script.toFilePath();
        final packageDir = _findPackageDir(scriptPath);
        if (packageDir != null) {
          final resolved = File('$packageDir/$path');
          if (resolved.existsSync()) {
            theme._parseTheme(await resolved.readAsString());
            continue;
          }
        }
        throw StateError('Could not find theme file: $path');
      }
    }
    return theme;
  }

  static String? _findPackageDir(String path) {
    var current = Directory(path).existsSync() ? path : File(path).parent.path;
    while (current != '/') {
      if (File('$current/pubspec.yaml').existsSync()) {
        return current;
      }
      current = Directory(current).parent.path;
    }
    return null;
  }

  void _parseTheme(String json) {
    final theme = jsonDecode(json);
    final List settings = theme['settings'];
    for (final setting in settings) {
      final style = TextStyle.fromJson(setting['settings'] as Map?);
      if (style == null) continue;

      final scopes = setting['scope'];
      if (scopes is String) {
        _addScope(scopes, style);
      } else if (scopes is List) {
        for (final scope in scopes) {
          if (scope is String) {
            _addScope(scope, style);
          }
        }
      } else if (scopes == null) {
        _fallback = style;
      }
    }
  }

  void _addScope(String scope, TextStyle style) {
    // Handle comma-separated scopes in a single string
    for (final s in scope.split(',')) {
      final trimmed = s.trim();
      if (trimmed.isNotEmpty) {
        _scopes[trimmed] = style;
      }
    }
  }

  /// Get the style for a given list of scopes (most specific first).
  TextStyle? getStyle(List<String> scopes) {
    for (final s in scopes) {
      for (final fallback in _fallbacks(s)) {
        final style = _scopes[fallback];
        if (style != null) return style;
      }
    }
    return _fallback;
  }

  /// Generate fallback scope names from most specific to least.
  /// e.g. "entity.name.function.dart" -> ["entity.name.function.dart", "entity.name.function", "entity.name", "entity"]
  List<String> _fallbacks(String scope) {
    final fallbacks = <String>[];
    final parts = scope.split('.');
    for (var i = 0; i < parts.length; i++) {
      fallbacks.add(parts.sublist(0, i + 1).join('.'));
    }
    return fallbacks.reversed.toList();
  }
}
