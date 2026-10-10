import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/core/audio.dart';
import 'package:wordoo/core/loc.dart';
import 'package:wordoo/data/hi_text.dart';
import 'package:wordoo/engine/campaign.dart';
import 'package:wordoo/state/app_state.dart';
import 'package:wordoo/widgets/reward_modal.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/content/hi/hi_pack.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/engine/levels.dart';
import 'package:wordoo/models/models.dart';

/// The Hindi demo (Sound Forest) must produce sound Hindi items, and must leave English completely alone.
void main() {
  final hi = HindiGameContent();
  final phono = hi.phono;
  final dev = RegExp(r'[ऀ-ॿ]');

  test('every rhyme family has at least two picture words', () {
    final fam = <String, List<String>>{};
    for (final w in phono.words.where((w) => w.emoji != null && w.rime != null)) {
      fam.putIfAbsent(w.rime!, () => []).add(w.text);
    }
    for (final e in fam.entries) {
      expect(e.value.length, greaterThanOrEqualTo(2), reason: 'family ${e.key}');
    }
  });

  test('Sound Orchestra (Hindi): the right answer rhymes, the others do not, all text is Hindi', () {
    for (var level = 1; level <= levelsPerGame; level++) {
      for (var seed = 0; seed < 150; seed++) {
        final gen = ItemGen(hi, rng: Random(seed * 7 + level));
        final it = gen.forLevel(GameId.soundOrchestra, level);
        expect(it.options.length, 3);
        expect(it.options.map((o) => o.label).toSet().length, 3, reason: 'distinct options');
        expect(dev.hasMatch(it.prompt), true, reason: it.prompt);
        expect(dev.hasMatch(it.hint), true, reason: it.hint);
        final fam = phono.rhymeFamily;
        final right = it.options[it.correct].label;
        final wrong = [for (var i = 0; i < 3; i++) if (i != it.correct) it.options[i].label];
        final targetWord = it.prompt.split(' ').first; // '{word} से किसकी तुक मिलती है?'
        expect(fam[right], isNotNull);
        expect(fam[right], fam[targetWord], reason: '$right should rhyme with $targetWord');
        for (final w in wrong) {
          expect(fam[w] == fam[targetWord] && fam[w] != null, false, reason: '$w must not rhyme with $targetWord');
        }
      }
    }
  });

  test('Sound Ninja (Hindi): the beat count is right for every level', () {
    for (var level = 1; level <= levelsPerGame; level++) {
      for (var seed = 0; seed < 150; seed++) {
        final gen = ItemGen(hi, rng: Random(seed * 3 + level));
        final it = gen.forLevel(GameId.soundNinja, level);
        final word = phono.words.firstWhere((w) => w.text == it.stimulus);
        final want = level == 4 ? word.units.length : word.syllables;
        expect(it.options[it.correct].label, '$want', reason: '${word.text} level $level');
        expect(dev.hasMatch(it.prompt), true);
      }
    }
  });

  test('English is untouched: same content, same prompts, no Hindi anywhere', () {
    final en = GameContent.of('en');
    expect(identical(en.phono, en), true);
    for (var seed = 0; seed < 100; seed++) {
      for (final g in [GameId.soundOrchestra, GameId.soundNinja]) {
        for (var l = 1; l <= levelsPerGame; l++) {
          final it = ItemGen(en, rng: Random(seed + l)).forLevel(g, l);
          expect(dev.hasMatch(it.prompt + it.hint + it.options.map((o) => o.label).join()), false);
        }
      }
    }
    // the English prompts and hints are exactly the original strings
    final it = ItemGen(en, rng: Random(1)).forLevel(GameId.soundNinja, 1);
    expect(it.prompt, startsWith('Slice “'));
    expect(it.hint, 'Say it slowly and cut at every beat.');
  });

  test('a child who chose Hindi still gets English content for every other island', () {
    expect(GameContent.of('hi').code, 'en');
  });

  Future<void> openReward(WidgetTester t, IslandId island) async {
    AudioManager.instance.enabled = false;
    final q = Quest(island, QuestKind.standard, 'Easy rhymes', const [], 6, GameId.soundOrchestra, 0);
    final out = SessionOutcome(3, 30, 1.0, const [], const [], const [], islandKeys: 3, islandKeysMax: 28, keysWon: 3, keysBest: 3, keysMax: 3, levelNew: true, restorationBefore: 0, restorationAfter: 10);
    await t.pumpWidget(MaterialApp(
      home: Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => showRewardModal(c, outcome: out, game: GameId.soundOrchestra, companion: 0, level: 1, quest: q), child: const Text('go')))),
    ));
    await t.tap(find.text('go'));
    await t.pump(const Duration(seconds: 3));
  }

  testWidgets('reward screen: Hindi on Sound Forest when Hindi is chosen', (t) async {
    Loc.code = 'hi';
    await openReward(t, IslandId.forest);
    expect(find.text('शाबाश!'), findsWidgets);
    expect(find.text('आगे बढ़ो'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    Loc.code = 'en';
  });

  testWidgets('reward screen: another island stays English even when Hindi is chosen', (t) async {
    Loc.code = 'hi';
    await openReward(t, IslandId.valley);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('आगे बढ़ो'), findsNothing);
    Loc.code = 'en';
  });

  testWidgets('reward screen: English is unchanged', (t) async {
    Loc.code = 'en';
    await openReward(t, IslandId.forest);
    expect(find.text('You Did It!'), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Level 1 cleared! ⭐'), findsOneWidget);
  });

  test('Hindi interface text has no leftover English placeholders', () {
    for (final e in HiText.ui.entries) {
      final ph = RegExp(r'\{(\w+)\}');
      final enKeys = ph.allMatches(e.key).map((m) => m.group(1)).toSet();
      final hiKeys = ph.allMatches(e.value).map((m) => m.group(1)).toSet();
      expect(hiKeys, enKeys, reason: e.key);
      expect(RegExp(r'[\u0900-\u097F]').hasMatch(e.value), true, reason: e.key);
    }
  });
}
