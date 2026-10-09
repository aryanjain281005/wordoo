import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/data/lang.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/games/game_module.dart';
import 'package:wordoo/games/letter_archer/archery_world.dart';
import 'package:wordoo/games/letter_archer/letter_archer.dart';
import 'package:wordoo/models/models.dart';

void main() {
  final pack = LangRegistry.byCode('en');

  ArcheryWorld make({double drift = 0, List<int>? hits, int n = 3}) {
    final w = ArcheryWorld(lanterns: n, drift: drift, onHit: (i) => hits?.add(i));
    w.size = const Size(380, 520);
    return w;
  }

  void run(ArcheryWorld w, double seconds) {
    for (var t = 0.0; t < seconds; t += 1 / 60) {
      w.update(1 / 60);
    }
  }

  test('tapping a lantern fires an auto-aimed arrow that hits it, even while it drifts', () {
    for (final drift in [0.0, 1.0, 2.0]) {
      for (var i = 0; i < 3; i++) {
        final hits = <int>[];
        final w = make(drift: drift, hits: hits);
        run(w, .7 + i * .3); // let the lanterns move first
        expect(w.autoFire(i), isTrue);
        run(w, 1.0);
        expect(hits, [i], reason: 'drift $drift lantern $i');
      }
    }
  });

  test('pulling the string back and letting go shoots the opposite way', () {
    final hits = <int>[];
    final w = make(hits: hits);
    final target = w.lanternAt(1);
    final dir = (target - w.bow) / (target - w.bow).distance;
    w.startAim();
    for (var k = 0; k < 10; k++) {
      w.dragAim(-dir * 9);
    }
    expect(w.guide(), isNotEmpty);
    expect(w.release(), isTrue);
    run(w, 1);
    expect(hits, [1]);
  });

  test('a tiny pull does not shoot; a shot into the sky is a miss, not an answer', () {
    var misses = 0;
    final hits = <int>[];
    final w = ArcheryWorld(lanterns: 3, onHit: hits.add, onMiss: () => misses++)..size = const Size(380, 520);
    w.startAim();
    w.dragAim(const Offset(0, 5));
    expect(w.release(), isFalse);
    w.fire(const Offset(-1, -.05) / const Offset(-1, -.05).distance); // nearly sideways, under all lanterns
    run(w, 1);
    expect(hits, isEmpty);
    expect(misses, 1);
    expect(w.arrow, isNull, reason: 'a new arrow is ready');
  });

  test('Letter Archer is the registered module for its game', () => expect(GameModules.hasDedicated(GameId.letterArcher), isTrue));

  Item letter(int step, int seed) => ItemGen(GameContent.of('en'), rng: Random(seed)).make(Skill.gpc, step);

  Future<void> pumpItem(WidgetTester tester, Item it, {bool demo = false, List<ItemResult>? out, List<String>? msgs}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, height: 700, child: LetterArcherItem(ctx: GameCtx(item: it, scaffold: false, pack: pack, demo: demo, feedback: (m, _) => msgs?.add(m), done: (r) => out?.add(r)), explorerName: 'Asha'))),
    ));
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Where lantern [i] sits on screen right now.
  Offset lanternOnScreen(WidgetTester tester, int i, int n) {
    final box = tester.getRect(find.byType(GestureDetector).last);
    final w = ArcheryWorld(lanterns: n, onHit: (_) {})..size = box.size;
    return box.topLeft + w.home(i);
  }

  testWidgets('tap the right lantern: it lights and the answer is reported', (tester) async {
    ArcheryStreak.reset();
    final it = letter(2, 3); // step 2: still lanterns
    final out = <ItemResult>[];
    await pumpItem(tester, it, out: out);
    await tester.tapAt(lanternOnScreen(tester, it.correct, it.options.length));
    for (var k = 0; k < 40; k++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(out.single.correct, isTrue);
    expect(ArcheryStreak.hits, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a wrong lantern dims with a hint; the second chance still counts as helped', (tester) async {
    ArcheryStreak.hits = 2;
    final it = letter(1, 7);
    final out = <ItemResult>[];
    final msgs = <String>[];
    await pumpItem(tester, it, out: out, msgs: msgs);
    final wrong = [for (var i = 0; i < it.options.length; i++) if (i != it.correct) i].first;
    await tester.tapAt(lanternOnScreen(tester, wrong, it.options.length));
    for (var k = 0; k < 20; k++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(msgs.last, it.hint);
    expect(ArcheryStreak.hits, 0, reason: 'a miss breaks the golden streak');
    await tester.tapAt(lanternOnScreen(tester, it.correct, it.options.length));
    for (var k = 0; k < 40; k++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(out.single.correct, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('three first-try hits light the Golden Lantern', (tester) async {
    ArcheryStreak.hits = 2;
    final it = letter(2, 11);
    final msgs = <String>[];
    final out = <ItemResult>[];
    await pumpItem(tester, it, out: out, msgs: msgs);
    await tester.tapAt(lanternOnScreen(tester, it.correct, it.options.length));
    for (var k = 0; k < 80; k++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(msgs.last, contains('Golden Lantern'));
    expect(out.single.correct, isTrue);
    expect(ArcheryStreak.hits, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('demo shoots by itself and never reports', (tester) async {
    final it = letter(4, 2);
    final out = <ItemResult>[];
    await pumpItem(tester, it, demo: true, out: out);
    for (var k = 0; k < 60; k++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(out, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
