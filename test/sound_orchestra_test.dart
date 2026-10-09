import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/content/en/en_features.dart';
import 'package:wordoo/data/lang.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/games/game_module.dart';
import 'package:wordoo/games/sound_orchestra/sound_orchestra.dart';
import 'package:wordoo/models/models.dart';

void main() {
  final pack = LangRegistry.byCode('en');

  Item phon(int step, bool Function(Item) ok, {int seed = 1}) {
    final gen = ItemGen(GameContent.of('en'), rng: Random(seed));
    for (var i = 0; i < 400; i++) {
      final it = gen.make(Skill.phonological, step);
      if (ok(it)) return it;
    }
    throw StateError('no item');
  }

  Future<void> pumpItem(WidgetTester tester, Item it, {bool demo = false, List<ItemResult>? out, List<String>? msgs}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, height: 760, child: SoundOrchestraItem(ctx: GameCtx(item: it, scaffold: false, pack: pack, demo: demo, feedback: (m, _) => msgs?.add(m), done: (r) => out?.add(r)))),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder member(Item it, int i) => find.text(it.options[i].emoji!);

  test('syllable counts are right for tricky picture words', () {
    expect({for (final w in ['apple', 'whale', 'grapes', 'crocodile', 'boxes', 'castle', 'turtle', 'banana', 'watermelon', 'cat']) w: EnFeatures.syllables(w)},
        {'apple': 2, 'whale': 1, 'grapes': 1, 'crocodile': 3, 'boxes': 2, 'castle': 2, 'turtle': 2, 'banana': 3, 'watermelon': 4, 'cat': 1});
  });

  test('Sound Orchestra is the registered module for its game', () => expect(GameModules.hasDedicated(GameId.soundOrchestra), isTrue));

  test('low steps include Clap the Beat rounds', () {
    final gen = ItemGen(GameContent.of('en'), rng: Random(2));
    final ids = [for (var i = 0; i < 60; i++) gen.make(Skill.phonological, 1).id];
    expect(ids.where((id) => id.startsWith('pc:')), isNotEmpty);
    expect(ids.where((id) => id.startsWith('ps:')), isNotEmpty);
  });

  testWidgets('picture rounds: one tap answers; the band wakes up', (tester) async {
    OrchestraBand.reset();
    final it = phon(3, (i) => i.id.startsWith('pr:') && !i.audioOptions);
    final out = <ItemResult>[];
    await pumpItem(tester, it, out: out);
    await tester.tap(member(it, it.correct));
    await tester.pump(const Duration(seconds: 2));
    expect(out.single.correct, isTrue);
    expect(OrchestraBand.level, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('listen-only rounds hide the pictures: tap to hear, ✓ to choose', (tester) async {
    OrchestraBand.reset();
    final gen = ItemGen(GameContent.of('en'), rng: Random(4));
    final it = gen.forLevel(GameId.soundOrchestra, 3);
    expect(it.audioOptions, isTrue);
    final out = <ItemResult>[];
    await pumpItem(tester, it, out: out);
    expect(find.text(it.options[it.correct].emoji!), findsNothing, reason: 'no pictures at listen-only levels');
    await tester.tap(find.text('${it.correct + 1}'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(out, isEmpty, reason: 'first tap only listens');
    await tester.tap(find.text('✓'));
    await tester.pump(const Duration(seconds: 2));
    expect(out.single.correct, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a wrong picture gives the sound hint, then a second chance', (tester) async {
    OrchestraBand.level = 2;
    final it = phon(2, (i) => i.id.startsWith('ps:'), seed: 5);
    final out = <ItemResult>[];
    final msgs = <String>[];
    await pumpItem(tester, it, out: out, msgs: msgs);
    final wrong = List.generate(3, (i) => i).firstWhere((i) => i != it.correct);
    await tester.tap(member(it, wrong));
    await tester.pump(const Duration(milliseconds: 300));
    expect(msgs.last, it.hint);
    expect(OrchestraBand.level, 1);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(member(it, it.correct));
    await tester.pump(const Duration(seconds: 2));
    expect(out.single.correct, isFalse);
    expect(out.single.tags, ['Wrong first sound']);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Clap the Beat: one drum tap per syllable', (tester) async {
    final it = phon(2, (i) => i.id.startsWith('pc:'));
    final beats = int.parse(it.options[it.correct].label);
    final out = <ItemResult>[];
    await pumpItem(tester, it, out: out);
    for (var i = 0; i < beats; i++) {
      await tester.tap(find.byType(GestureDetector).at(1), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(find.text('✓'));
    await tester.pump(const Duration(seconds: 2));
    expect(out.single.correct, isTrue);
    expect(EnFeatures.syllables(it.stimulus!), beats);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('blend rounds show the chorus; demo never reports', (tester) async {
    final it = phon(5, (i) => i.id.startsWith('pb:'));
    final out = <ItemResult>[];
    await pumpItem(tester, it, demo: true, out: out);
    expect(find.text('♪'), findsWidgets);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(out, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
