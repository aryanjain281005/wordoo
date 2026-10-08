/// Plain-Dart story text helpers (no Flutter), shared by the app and tool/export_books.dart.

List<String> splitSentences(String text) {
  final out = <String>[];
  final re = RegExp(r'[^.!?]+[.!?]+[”"’]?\s*');
  for (final m in re.allMatches(text)) {
    final s = m.group(0)!.trim();
    if (s.isNotEmpty) out.add(s);
  }
  final rest = text.replaceAll(re, '').trim();
  if (rest.isNotEmpty) out.add(rest);
  return out.isEmpty ? [text] : out;
}

String _safe(String storyId) => storyId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

/// Narration line for sentence [n] of an authored story (Dadi's voice), e.g. `book_s_hat_0`.
String bookLineId(String storyId, int n) => 'book_${_safe(storyId)}_$n';

/// Kitabu asking question [qi] of an authored story.
String questionLineId(String storyId, int qi) => 'bookq_${_safe(storyId)}_$qi';

/// Story id from a comprehension item id `st:<storyId>:<question>`.
String storyIdOfItem(String itemId) {
  if (!itemId.startsWith('st:')) return '';
  final rest = itemId.substring(3);
  final k = rest.lastIndexOf(':');
  return k < 0 ? rest : rest.substring(0, k);
}

bool isAuthoredStory(String storyId) => storyId.startsWith('s-');
