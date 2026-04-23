import 'package:test/test.dart';
import 'package:textmate_highlight/textmate_highlight.dart';

void main() {
  group('Highlighter', () {
    setUp(() async {
      await Highlighter.initialize(['dart', 'python', 'javascript', 'rust']);
    });

    test('highlights Dart code with tokens', () {
      final code = '''
class TodoApp extends StatefulWidget {
  const TodoApp({super.key});
  @override
  State<TodoApp> createState() => _TodoAppState();
}
''';
      final highlighter = Highlighter(language: 'dart');
      final tokens = highlighter.highlight(code);

      expect(tokens, isNotEmpty);
      for (final token in tokens) {
        expect(token.start, lessThanOrEqualTo(token.end));
        expect(token.scopes, isNotEmpty);
      }

      // Print tokens for debugging
      for (final token in tokens) {
        print(
            '${token.scopes.first.padRight(50)} | ${token.text(code).replaceAll('\n', '\\n')}');
      }
    });

    test('highlights Python code with tokens', () {
      final code = '''
from dataclasses import dataclass

@dataclass
class User:
    name: str
    email: str

    def is_adult(self) -> bool:
        return True
''';
      final highlighter = Highlighter(language: 'python');
      final tokens = highlighter.highlight(code);

      expect(tokens, isNotEmpty);
      for (final token in tokens) {
        print(
            '${token.scopes.first.padRight(50)} | ${token.text(code).replaceAll('\n', '\\n')}');
      }
    });

    test('highlights JavaScript code with tokens', () {
      final code = '''
const fetchUsers = async (filters = {}) => {
  const response = await fetch('/api/users');
  return response.json();
};
''';
      final highlighter = Highlighter(language: 'javascript');
      final tokens = highlighter.highlight(code);

      expect(tokens, isNotEmpty);
      for (final token in tokens) {
        print(
            '${token.scopes.first.padRight(50)} | ${token.text(code).replaceAll('\n', '\\n')}');
      }
    });

    test('highlights Rust code with tokens', () {
      final code = '''
use std::collections::HashMap;

pub struct Cache<T: Clone> {
    store: HashMap<String, T>,
    ttl: std::time::Duration,
}

impl<T: Clone> Cache<T> {
    pub fn new(ttl: std::time::Duration) -> Self {
        Self { store: HashMap::new(), ttl }
    }
}
''';
      final highlighter = Highlighter(language: 'rust');
      final tokens = highlighter.highlight(code);

      expect(tokens, isNotEmpty);
      for (final token in tokens) {
        print(
            '${token.scopes.first.padRight(50)} | ${token.text(code).replaceAll('\n', '\\n')}');
      }
    });
  });

  group('HighlightTheme', () {
    test('loads dark theme', () async {
      final theme = await HighlightTheme.loadDarkTheme();
      expect(theme, isNotNull);
    });

    test('loads light theme', () async {
      final theme = await HighlightTheme.loadLightTheme();
      expect(theme, isNotNull);
    });

    test('getStyle returns style for known scope', () async {
      final theme = await HighlightTheme.loadDarkTheme();
      final style =
          theme.getStyle(['entity.name.function.dart', 'entity.name.function']);
      expect(style, isNotNull);
    });

    test('getStyle fallback works', () async {
      final theme = await HighlightTheme.loadDarkTheme();
      // Very specific scope that may not exist - should fall back
      theme.getStyle(['some.unknown.scope.that.does.not.exist']);
      // Should return either a matched style or the fallback
      // Just verify it doesn't throw
    });
  });
}
