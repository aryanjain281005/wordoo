// Writes assets/story/books_en.json: the narration lines of every authored story (one per sentence, read by
// Dadi Kahani) and Kitabu's questions, so tool/gen_voices.py can turn them into voice files.
//   dart run tool/export_books.dart
import 'dart:convert';
import 'dart:io';
import '../lib/content/en/en_stories.dart';
import '../lib/story/book_text.dart';

void main() {
  final out = <String, Map<String, String>>{};
  for (final s in enStories) {
    final sentences = splitSentences(s.text);
    for (var i = 0; i < sentences.length; i++) {
      out[bookLineId(s.id, i)] = {'who': 'dadi', 'text': sentences[i]};
    }
    for (var q = 0; q < s.questions.length; q++) {
      out[questionLineId(s.id, q)] = {'who': 'kitabu', 'text': s.questions[q].q};
    }
  }
  File('assets/story/books_en.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(out));
  stdout.writeln('${out.length} lines');
}
