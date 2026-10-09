// Collects every phrase the games can speak (words, sounds, instructions, story sentences, questions, answers)
// by running the real item generator many times, and writes assets/story/say_en.json for tool/gen_voices.py.
//   dart run tool/export_speech.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../lib/content/en/en_pack.dart';
import '../lib/content/en/en_stories.dart';
import '../lib/core/speech_key.dart';
import '../lib/data/strings.dart';
import '../lib/engine/item_gen.dart';
import '../lib/engine/levels.dart';
import '../lib/models/models.dart';
import '../lib/story/book_text.dart';

void main() {
  final c = EnglishGameContent();
  final texts = <String>{};
  void add(String? t) {
    if (t == null) return;
    final s = t.trim();
    if (s.isEmpty || !RegExp(r'[A-Za-z]').hasMatch(s)) return; // nothing speakable (dots, digits)
    if (splitSentences(s).length > 1) return; // whole stories: read sentence by sentence instead
    if (s.contains(',  ')) return; // "c,  a,  t" sound sequences: played as one clip per sound
    texts.add(s);
  }

  void addItem(Item it) {
    add(it.say);
    add(it.prompt);
    add(it.replaySay);
    if ((it.replaySay ?? '').contains(',  ')) {
      for (final part in it.replaySay!.split(',')) {
        add(part);
      }
    }
    add(it.stimulus?.contains(' · ') == true ? null : it.stimulus);
    for (final o in it.options) {
      add(o.say ?? o.label);
    }
    for (final x in [...it.answer, ...it.tiles]) {
      add(x);
    }
    if (it.passage != null) {
      for (final s in splitSentences(it.passage!)) {
        add(s);
      }
    }
  }

  for (final g in gameLevels.keys) {
    for (var l = 1; l <= levelsPerGame; l++) {
      for (var b = 0; b <= 2; b++) {
        final gen = ItemGen(c, rng: Random(g.index * 100 + l * 10 + b));
        for (var k = 0; k < 500; k++) {
          addItem(gen.forLevel(g, l, bump: b));
        }
      }
    }
  }
  for (final s in Skill.values) {
    for (var step = 1; step <= 10; step++) {
      final gen = ItemGen(c, rng: Random(step * 7 + s.index));
      for (var k = 0; k < 300; k++) {
        addItem(gen.make(s, step));
      }
    }
  }
  for (final w in c.words) {
    add(w.text);
  }
  for (final e in c.graphemes) {
    add(e.say);
    add(e.text);
  }
  for (final ch in 'abcdefghijklmnopqrstuvwxyz'.split('')) {
    add(ch);
    add(c.sayUnit(ch));
  }
  for (var step = 1; step <= 10; step++) {
    for (var seed = 0; seed < EnglishGameContent.nonwordBank; seed++) {
      for (final n in c.nonwords(step, 1, seed)) {
        add(n.text);
      }
    }
  }
  for (final st in enStories) {
    for (final q in st.questions) {
      for (final o in q.options) {
        add(o.$1);
      }
    }
  }
  for (final k in Str.keys) {
    add(Str.t('en', k));
  }

  final out = <String, Map<String, String>>{};
  final seen = <String>{};
  for (final t in texts.toList()..sort()) {
    final key = speechKey(t);
    if (!seen.add(key)) continue;
    out[speechId(key)] = {'who': 'say', 'text': t};
  }
  File('assets/story/say_en.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(out));
  stdout.writeln('${out.length} phrases');
}
