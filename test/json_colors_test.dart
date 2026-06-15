import 'dart:io';
import 'package:test/test.dart';
import 'package:textmate_highlight/textmate_highlight.dart';

// Reproduce the color map from highlight_service.dart for testing.
Map<String, String> _colorMap = {
  'keyword': 'highlightKeyword',
  'keyword.operator': 'syntaxOperator',
  'operator': 'syntaxOperator',
  'storage': 'highlightStorage',
  'entity.name.function': 'highlightFunction',
  'entity.name.type': 'highlightType',
  'entity.name.class': 'highlightType',
  'support': 'highlightAttribute',
  'support.type': 'highlightAttribute',
  'support.function': 'highlightFunction',
  'support.class': 'highlightType',
  'string': 'highlightString',
  'string.quoted': 'highlightString',
  'string.template': 'highlightString',
  'comment': 'highlightComment',
  'constant': 'highlightConstant',
  'constant.numeric': 'highlightNumeric',
  'constant.language.boolean': 'highlightConstant',
  'constant.language.null': 'highlightKeyword',
  'variable': 'highlightVariable',
  'variable.parameter': 'highlightVariable',
  'tag': 'highlightTag',
  'attribute.name': 'highlightAttribute',
  'punctuation': 'highlightPunctuation',
  'punctuation.definition': 'highlightPunctuation',
  'heading': 'highlightType',
  'emphasis': 'highlightFunction',
  'strong': 'highlightFunction',
};

List<String> _scopeFallbacks(String scope) {
  final fallbacks = <String>[];
  final parts = scope.split('.');
  for (var i = 0; i < parts.length; i++) {
    fallbacks.add(parts.sublist(0, i + 1).join('.'));
  }
  return fallbacks.reversed.toList();
}

/// Mirrors the production colorForScopes lookup. First match wins.
String? colorForToken(List<String> scopes) {
  for (final scope in scopes) {
    for (final fallback in _scopeFallbacks(scope)) {
      if (_colorMap.containsKey(fallback)) {
        return _colorMap[fallback];
      }
    }
  }
  return null; // highlightDefault
}

void main() {
  setUpAll(() {
    final grammarJson = File('lib/grammars/json.json').readAsStringSync();
    if (!Highlighter.isLanguageLoaded('json')) {
      Highlighter.addLanguage('json', grammarJson);
    }
  });

  test('keys are colored as attribute (not bland default)', () {
    final code = '{"name": "x"}';
    final h = Highlighter(language: 'json');
    final tokens = h.highlight(code);
    // Find the token "name" (between two quote chars)
    final nameToken = tokens.firstWhere(
        (t) => t.text(code) == 'name',
        orElse: () => throw StateError('name token not found'));
    final color = colorForToken(nameToken.scopes);
    expect(color, 'highlightAttribute',
        reason: 'keys should be highlightAttribute, got $color. '
            'Scopes: ${nameToken.scopes}');
  });

  test('strings are colored as string', () {
    final code = '{"k": "hello"}';
    final h = Highlighter(language: 'json');
    final tokens = h.highlight(code);
    final helloToken = tokens.firstWhere(
        (t) => t.text(code) == 'hello',
        orElse: () => throw StateError('hello token not found'));
    final color = colorForToken(helloToken.scopes);
    expect(color, 'highlightString',
        reason: 'strings should be highlightString, got $color. '
            'Scopes: ${helloToken.scopes}');
  });

  test('integers are colored as numeric', () {
    final code = '{"k": 42}';
    final h = Highlighter(language: 'json');
    final tokens = h.highlight(code);
    final numToken = tokens.firstWhere(
        (t) => t.text(code) == '42',
        orElse: () => throw StateError('42 token not found'));
    final color = colorForToken(numToken.scopes);
    expect(color, 'highlightNumeric',
        reason: 'numbers should be highlightNumeric, got $color. '
            'Scopes: ${numToken.scopes}');
  });

  test('floats and exponents are colored as numeric', () {
    final code = '{"a": 3.14, "b": 1.5e-10, "c": -2}';
    final h = Highlighter(language: 'json');
    final tokens = h.highlight(code);
    for (final expected in ['3.14', '1.5e-10', '-2']) {
      final tok = tokens.firstWhere(
          (t) => t.text(code) == expected,
          orElse: () => throw StateError('$expected not found'));
      final color = colorForToken(tok.scopes);
      expect(color, 'highlightNumeric',
          reason: '$expected should be highlightNumeric, got $color');
    }
  });

  test('booleans are colored as constant', () {
    final code = '{"a": true, "b": false}';
    final h = Highlighter(language: 'json');
    final tokens = h.highlight(code);
    for (final expected in ['true', 'false']) {
      final tok = tokens.firstWhere(
          (t) => t.text(code) == expected,
          orElse: () => throw StateError('$expected not found'));
      final color = colorForToken(tok.scopes);
      expect(color, 'highlightConstant',
          reason: '$expected should be highlightConstant, got $color. '
              'Scopes: ${tok.scopes}');
    }
  });

  test('null is distinct from booleans (keyword vs constant)', () {
    final code = '{"a": null, "b": true, "c": false}';
    final h = Highlighter(language: 'json');
    final tokens = h.highlight(code);
    final nullTok = tokens.firstWhere(
        (t) => t.text(code) == 'null',
        orElse: () => throw StateError('null not found'));
    final trueTok = tokens.firstWhere(
        (t) => t.text(code) == 'true',
        orElse: () => throw StateError('true not found'));
    final nullColor = colorForToken(nullTok.scopes);
    final trueColor = colorForToken(trueTok.scopes);
    expect(nullColor, 'highlightKeyword',
        reason: 'null should be highlightKeyword, got $nullColor');
    expect(trueColor, 'highlightConstant',
        reason: 'true should be highlightConstant, got $trueColor');
    expect(nullColor, isNot(equals(trueColor)),
        reason: 'null and true should be visually distinct');
  });

  test('brackets and commas are colored as punctuation', () {
    final code = '{"a": 1, "b": 2}';
    final h = Highlighter(language: 'json');
    final tokens = h.highlight(code);
    for (final expected in ['{', '}', ',']) {
      final tok = tokens.firstWhere(
          (t) => t.text(code) == expected,
          orElse: () => throw StateError('$expected not found'));
      final color = colorForToken(tok.scopes);
      expect(color, 'highlightPunctuation',
          reason: '$expected should be highlightPunctuation, got $color. '
              'Scopes: ${tok.scopes}');
    }
  });

  test('keys, strings, numbers, booleans, null are ALL distinct colors', () {
    final code = '{"k": "v", "n": 1, "b": true, "nl": null}';
    final h = Highlighter(language: 'json');
    final tokens = h.highlight(code);
    final colors = <String, String>{};
    for (final tok in tokens) {
      final text = tok.text(code);
      String? label;
      if (text == 'k' || text == 'n' || text == 'b' || text == 'nl') {
        label = 'key';
      } else if (text == 'v') {
        label = 'string';
      } else if (text == '1') {
        label = 'number';
      } else if (text == 'true') {
        label = 'boolean';
      } else if (text == 'null') {
        label = 'null';
      }
      if (label != null) {
        colors[label] = colorForToken(tok.scopes) ?? 'default';
      }
    }
    // Every value type must get a unique color.
    final unique = colors.values.toSet();
    expect(unique.length, colors.length,
        reason: 'All value types should get distinct colors, got: $colors');
  });
}
