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

  // Vendored full TextMate grammars from shikijs/textmate-grammars-themes.
  // csharp and bash are zero non-local-include grammars and work as-is.
  // cpp uses $self and runs against the recursion-bound _IncludeMatcher.
  // (c, php, ruby were vendored too but their include graphs hang the
  // SpanParser on trivial inputs; drop them until we can either trim
  // the grammars or grow the parser.)
  group('Vendored grammars (shikijs)', () {
    setUp(() async {
      await Highlighter.initialize(['csharp', 'cpp', 'bash']);
    });

    void smoke(String language, String code) {
      final tokens = Highlighter(language: language).highlight(code);
      expect(tokens, isNotEmpty, reason: '$language produced no tokens');
      for (final token in tokens) {
        expect(token.start, lessThanOrEqualTo(token.end),
            reason: '$language token has start > end: $token');
        expect(token.scopes, isNotEmpty,
            reason: '$language token has empty scopes: $token');
      }
    }

    test('csharp', () {
      smoke(
        'csharp',
        '// hello\n'
            'class Foo : IBar {\n'
            '  int x = 42;\n'
            r'  string Greet(string name) => $"hi {name}";'
            '\n'
            '}\n',
      );
    });

    test('cpp', () {
      smoke(
        'cpp',
        '// hello\n'
            '#include <vector>\n'
            'auto main() -> int { std::vector<int> v{1, 2, 3}; return 0; }\n',
      );
    });

    test('bash', () {
      smoke(
        'bash',
        '# hello\n'
            r'echo "hi $NAME" | grep hi'
            '\n',
      );
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
