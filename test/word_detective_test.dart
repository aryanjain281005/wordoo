import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/data/lang.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/games/game_module.dart';
import 'package:wordoo/games/word_detective/word_detective.dart';
import 'package:wordoo/models/models.dart';

void main() {
  final pack = LangRegistry.byCode('en');
  Item word(int step, int seed) => ItemGen(GameContent.of('en'), rng: Random(seed)).make(Skill.wordRecognition, step);

  Future<void> pumpItem(WidgetTester tester, Item it, {bool demo = false, bool scaffold = false, List<ItemResult>? out, List<String>? msgs}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, height: 760, child: WordDetectiveItem(ctx: GameCtx(item: it, scaffold: scaffold, pack: pack, demo: demo, feedback: (m, _) => msgs?.add(m), done: (r) => out?.add(r))))),
    ));
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Tap a sign: the first tap on a foggy sign moves the magnifier, the next tap chooses it.
  Future<void> pick(WidgetTester tester, String label) async {
    await tester.tap(find.text(label), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text(label), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
  }

  test('every case has 3 clues, 3 suspects and one culprit among them, plus voiced intro and reveal', () {
    final lines = jsonDecode(File('assets/story/lines_en.json').readAsStringSync()) as Map<String, dynamic>;
    for (var i = 0; i < detectiveCases.length; i++) {
      final c = detectiveCases[i];
      expect(c.clues.length, 3);
      expect(c.suspects.where((s) => s.$1 == c.culprit).length, 1);
      for (final id in ['det_intro_$i', 'det_reveal_$i']) {
        expect(lines.containsKey(id), isTrue);
        expect(File('assets/vo/en/$id.ogg').existsSync(), isTrue);
      }
    }
    expect(detectiveRank(0), 'Rookie Detective');
    expect(detectiveRank(30), 'Chief Inspector');
  });

  test('Word Detective is the registered module for its game', () => expect(GameModules.hasDedicated(GameId.wordDetective), isTrue));

  testWidgets('the right sign gives a clue and a success', (tester) async {
    CaseBoard.reset();
    final it = word(4, 3);
    final out = <ItemResult>[];
    await pumpItem(tester, it, out: out);
    await tester.pump(const Duration(seconds: 8)); // Ullu opens the case
    await pick(tester, it.options[it.correct].label);
    await tester.pump(const Duration(seconds: 3));
    expect(out.single.correct, isTrue);
    expect(CaseBoard.clues, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a look-alike sign shakes and the word is said again; second miss shows the answer', (tester) async {
    CaseBoard.reset();
    CaseBoard.introduced = true;
    final it = word(6, 8);
    final out = <ItemResult>[];
    final msgs = <String>[];
    await pumpItem(tester, it, out: out, msgs: msgs);
    final wrong = [for (var i = 0; i < it.options.length; i++) if (i != it.correct) i];
    await pick(tester, it.options[wrong[0]].label);
    expect(msgs.last, contains(it.options[wrong[0]].label));
    await tester.pump(const Duration(seconds: 2));
    await pick(tester, it.options[wrong[1]].label);
    await tester.pump(const Duration(seconds: 3));
    expect(out.single.correct, isFalse);
    expect(out.single.tags.length, 2);
    expect(CaseBoard.clues, 0, reason: 'no clue without the right word');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('third clue opens the line-up; naming the culprit closes the case', (tester) async {
    CaseBoard.reset();
    CaseBoard.introduced = true;
    CaseBoard.clues = 2;
    final kase = CaseBoard.current;
    final it = word(3, 5);
    final out = <ItemResult>[];
    await pumpItem(tester, it, out: out);
    await pick(tester, it.options[it.correct].label);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Who did it?'), findsOneWidget);
    expect(out, isEmpty, reason: 'the item finishes after the accusation');
    final wrong = kase.suspects.firstWhere((s) => s.$1 != kase.culprit);
    await tester.tap(find.text(wrong.$3));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Who did it?'), findsOneWidget);
    await tester.tap(find.text(kase.suspects.firstWhere((s) => s.$1 == kase.culprit).$3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Case closed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(out.single.correct, isTrue);
    expect(CaseBoard.clues, 0, reason: 'a new case begins');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('demo sweeps the magnifier and never reports', (tester) async {
    final it = word(3, 2);
    final out = <ItemResult>[];
    await pumpItem(tester, it, demo: true, out: out);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(out, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
