import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/data/lang.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/games/game_module.dart';
import 'package:wordoo/games/spelling_hive/spelling_hive.dart';
import 'package:wordoo/models/models.dart';

void main() {
  final pack = LangRegistry.byCode('en');

  Item spellItem(int step, int seed) => ItemGen(GameContent.of('en'), rng: Random(seed)).make(Skill.spelling, step);

  Future<void> play(WidgetTester tester, Item it, List<String> taps, {bool scaffold = false, bool demo = false, List<String>? msgs, List<ItemResult>? out}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 700,
          child: SpellingHiveItem(ctx: GameCtx(item: it, scaffold: scaffold, pack: pack, demo: demo, feedback: (m, _) => msgs?.add(m), done: (r) => out?.add(r))),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    for (final l in taps) {
      await tester.tap(find.text(l).last);
      await tester.pump(const Duration(milliseconds: 350));
    }
  }

  Future<void> check(WidgetTester tester) async {
    await tester.tap(find.textContaining('🍯'));
    await tester.pump(const Duration(milliseconds: 100));
  }

  test('Spelling Hive is the registered module for its game', () {
    expect(GameModules.hasDedicated(GameId.spellingHive), isTrue);
  });

  testWidgets('spelling the word right hatches a bee and reports a first-try success', (tester) async {
    final it = spellItem(2, 3);
    final out = <ItemResult>[];
    await play(tester, it, it.answer, out: out);
    await check(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('+1 baby bee!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(out.single.correct, isTrue);
    expect(out.single.skill, Skill.spelling);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a wrong letter keeps the right cells and gives a sound hint', (tester) async {
    final it = spellItem(4, 7);
    final wrongTile = it.tiles.firstWhere((t) => !it.answer.contains(t));
    final taps = [wrongTile, ...it.answer.skip(1)];
    final msgs = <String>[];
    final out = <ItemResult>[];
    await play(tester, it, taps, msgs: msgs, out: out);
    await check(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(msgs.last, contains('listen'));
    // only the first cell is open again: fill it correctly and finish
    await tester.tap(find.text(it.answer.first).last);
    await tester.pump(const Duration(milliseconds: 350));
    await check(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('+1 baby bee!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(out.single.correct, isFalse, reason: 'second try counts as help, not a first-try success');
    expect(out.single.tags, isNotEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('scaffold pre-places the first letter and removes extra distractors', (tester) async {
    final it = spellItem(6, 11);
    await play(tester, it, const [], scaffold: true);
    expect(it.tiles.length - it.answer.length, greaterThan(1));
    // every answer letter + exactly one distractor stays; the first letter already sits in its cell
    expect(find.byType(Draggable<int>), findsNWidgets(it.answer.length + 1));
    expect(find.text(it.answer.first), findsAtLeastNWidgets(2), reason: 'shown in the first cell');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5)); // let the spoken word finish
  });

  testWidgets('demo plays itself and never reports a result', (tester) async {
    final it = spellItem(1, 5);
    ItemResult? got;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, height: 700, child: SpellingHiveItem(ctx: GameCtx(item: it, scaffold: false, pack: pack, demo: true, feedback: (_, _) {}, done: (r) => got = r))),
      ),
    ));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byType(SpellingHiveItem), findsOneWidget);
    expect(got, isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
