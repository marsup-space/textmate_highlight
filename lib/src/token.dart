/// A single highlighted token from the parser.
///
/// Contains the text segment and its TextMate scope stack,
/// which can be mapped to any styling system.
class HighlightedToken {
  /// The start position of this token in the source string.
  final int start;

  /// The end position of this token in the source string.
  final int end;

  /// The TextMate scope stack for this token, from most specific to least.
  ///
  /// For example: `['meta.function-call.dart', 'entity.name.function.dart', 'entity.name.function', 'entity.name', 'entity']`
  final List<String> scopes;

  const HighlightedToken({
    required this.start,
    required this.end,
    required this.scopes,
  });

  /// The text of this token from the given [source].
  String text(String source) => source.substring(start, end);

  @override
  String toString() => 'HighlightedToken($start-$end, $scopes)';
}
