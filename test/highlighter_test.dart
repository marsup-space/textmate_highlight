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

    // Regression: the parser's `_skipLine` regex used to require a trailing
    // `\n`, so a `begin`/`while` rule (e.g. Dart's `///` doc comments) would
    // silently drop everything after the `while` match on the very last line
    // of input if that line had no trailing newline. The renderer was
    // originally masked around this by highlighting whole code blocks at
    // once, but the underlying parser bug also broke any caller that fed the
    // highlighter single-line inputs.
    group('while-pattern rules on the last line', () {
      const commentScope = 'comment.block.documentation.dart';

      List<String> docCommentTexts(String code) {
        final h = Highlighter(language: 'dart');
        return [
          for (final t in h.highlight(code))
            if (t.scopes.contains(commentScope)) t.text(code),
        ];
      }

      test('captures content after /// on a single line with no trailing \\n',
          () {
        expect(docCommentTexts('/// doc one'), ['/// doc one']);
      });

      test('captures content after /// on a line ending with \\n', () {
        // Sanity check that the newline-terminated case still works.
        expect(docCommentTexts('/// doc one\n'), ['/// doc one\n']);
      });

      test('captures content on the final /// line when it has no trailing \\n',
          () {
        expect(
          docCommentTexts('/// first\n/// second'),
          ['/// first\n/// second'],
        );
      });

      test('captures content on the final /// line when it has a trailing \\n',
          () {
        expect(
          docCommentTexts('/// first\n/// second\n'),
          ['/// first\n/// second\n'],
        );
      });

      test('empty /// line is still a doc comment', () {
        // `///` alone has no extra content, but must still emit a token.
        expect(docCommentTexts('///'), ['///']);
      });
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
