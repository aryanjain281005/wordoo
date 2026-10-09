import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/data/lang.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/games/game_module.dart';
import 'package:wordoo/games/word_rocket/word_rocket.dart';
import 'package:wordoo/models/models.dart';

void main() {
  final pack = LangRegistry.byCode('en');
  Item dec(int step, int seed, {bool pictures = false}) {
    final gen = ItemGen(GameContent.of('en'), rng: Random(seed));
    for (var i = 0; i < 200; i++) {
      final it = gen.make(Skill.decoding, step);
      if (!pictures || it.options.every((o) => o.emoji != null)) return it;
    }
    throw StateError('no item');
  }

  Future<void> pumpItem(WidgetTester tester, Item it, {bool demo = false, List<ItemResult>? out, List<String>? msgs}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, height: 760, child: WordRocketItem(ctx: GameCtx(item: it, scaffold: false, pack: pack, demo: demo, feedback: (m, _) => msgs?.add(m), done: (r) => out?.add(r))))),
    ));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> blend(WidgetTester tester) async {
    await tester.drag(find.textContaining('Swipe up'), const Offset(0, -120));
    for (var k = 0; k < 30; k++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(WidgetTester tester, int ms) async {
    for (var k = 0; k < ms ~/ 100; k++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  test('zones follow the step; Kachhua lines are voiced', () {
    expect([1, 3, 4, 5, 6, 7, 8, 10].map(rocketZone).toList(), [1, 1, 2, 2, 3, 3, 4, 4]);
    final lines = jsonDecode(File('assets/story/lines_en.json').readAsStringSync()) as Map<String, dynamic>;
    for (final id in ['rocket_boost', 'rocket_sputter', 'rocket_pearl', 'rocket_zone_1', 'rocket_zone_4']) {
      expect(lines.containsKey(id), isTrue);
      expect(File('assets/vo/en/$id.ogg').existsSync(), isTrue);
    }
  });

  test('Word Rocket is the registered module for its game', () => expect(GameModules.hasDedicated(GameId.wordRocket), isTrue));

  testWidgets('answers wait for the blend; swipe up zips the cells; right picture → BOOST', (tester) async {
    RocketDive.reset();
    final it = dec(2, 3, pictures: true);
    final out = <ItemResult>[];
    await pumpItem(tester, it, out: out);
    await tester.tap(find.text(it.options[it.correct].emoji!));
    await tester.pump(const Duration(milliseconds: 300));
    expect(out, isEmpty, reason: 'cannot answer before blending');
    await blend(tester);
    expect(find.text(it.stimulus!.split(' · ').join()), findsOneWidget, reason: 'cells merged into one word');
    await tester.tap(find.text(it.options[it.correct].emoji!));
    await pump(tester, 2500);
    expect(out.single.correct, isTrue);
    expect(RocketDive.depth, 1);
    await tester.pumpWidget(const SizedBox());
    await pump(tester, 5000);
  });

  testWidgets('wrong word: the engine sputters, the cells are read again, a second chance', (tester) async {
    RocketDive.reset();
    RocketDive.zoneIntro = 1;
    final it = dec(2, 9, pictures: true);
    final out = <ItemResult>[];
    final msgs = <String>[];
    await pumpItem(tester, it, out: out, msgs: msgs);
    await blend(tester);
    final wrong = [for (var i = 0; i < 3; i++) if (i != it.correct) i].first;
    await tester.tap(find.text(it.options[wrong].emoji!));
    await tester.pump(const Duration(milliseconds: 300));
    expect(msgs.last, it.hint);
    await pump(tester, 6000);
    await tester.tap(find.text(it.options[it.correct].emoji!));
    await pump(tester, 2500);
    expect(out.single.correct, isFalse);
    expect(out.single.tags, ['Incorrect blend']);
    expect(RocketDive.depth, 0, reason: 'only first-try answers dive deeper');
    await tester.pumpWidget(const SizedBox());
    await pump(tester, 5000);
  });

  testWidgets('Alien Trench: heard options — tap to listen, ✓ to choose; the 5th boost finds the Pearl', (tester) async {
    RocketDive.reset();
    RocketDive.zoneIntro = 4;
    RocketDive.depth = RocketDive.pearlDepth - 1;
    final it = dec(9, 4);
    expect(it.id.startsWith('dn:'), isTrue);
    final out = <ItemResult>[];
    await pumpItem(tester, it, out: out);
    await blend(tester);
    await tester.tap(find.text('${it.correct + 1}'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(out, isEmpty);
    await tester.tap(find.text('✓'));
    await pump(tester, 1500);
    expect(find.text('The Pearl of Sounds!'), findsOneWidget);
    await pump(tester, 4000);
    expect(out.single.correct, isTrue);
    await tester.pumpWidget(const SizedBox());
    await pump(tester, 5000);
  });

  testWidgets('demo blends by itself and never reports', (tester) async {
    final it = dec(4, 2);
    final out = <ItemResult>[];
    await pumpItem(tester, it, demo: true, out: out);
    await pump(tester, 6000);
    expect(find.text(it.stimulus!.split(' · ').join()), findsOneWidget);
    expect(out, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
