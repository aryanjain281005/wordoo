// Hindi demo: collects every phrase the two Sound Forest games can speak in Hindi (words, sounds, instructions)
// by running the real item generator many times, and writes assets/story/say_hi.json for tool/gen_voices.py (VOLANG=hi).
//   dart run tool/export_speech_hi.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../lib/content/hi/hi_pack.dart';
import '../lib/core/speech_key.dart';
import '../lib/engine/item_gen.dart';
import '../lib/engine/levels.dart';
import '../lib/models/models.dart';

void main() {
  final c = HindiGameContent();
  final p = c.phono;
  final texts = <String>{};
  void add(String? t) {
    if (t == null) return;
    final s = t.trim();
    if (s.isEmpty || !RegExp(r'[ऀ-ॿ]').hasMatch(s)) return; // only Hindi text gets a Hindi clip
    if (s.contains(',  ')) return; // "ह,  आ,  थ" sound sequences: one clip per sound
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
    add(it.stimulus);
    for (final o in it.options) {
      add(o.say ?? o.label);
    }
  }

  for (final g in [GameId.soundOrchestra, GameId.soundNinja]) {
    for (var l = 1; l <= levelsPerGame; l++) {
      for (var b = 0; b <= 2; b++) {
        final gen = ItemGen(c, rng: Random(g.index * 100 + l * 10 + b));
        for (var k = 0; k < 600; k++) {
          addItem(gen.forLevel(g, l, bump: b));
        }
      }
    }
  }
  // every word and every sound, so nothing falls back to the phone's voice
  for (final w in p.words) {
    add(w.text);
    for (final u in w.units) {
      add(p.sayUnit(u));
    }
    add(p.p('rhyme', w: w.text));
    add(p.p('sliceBeats', w: w.text));
    if (w.syllables == 1) add(p.p('sliceSounds', w: w.text));
  }

  final out = <String, Map<String, String>>{};
  for (final t in texts.toList()..sort()) {
    out[speechId(speechKey(t))] = {'who': 'say', 'text': t};
  }
  File('assets/story/say_hi.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(out));
  stdout.writeln('${out.length} Hindi phrases, ${texts.fold<int>(0, (a, t) => a + t.length)} characters');
}
