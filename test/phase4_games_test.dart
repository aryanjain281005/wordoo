import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/data/lang.dart';
import 'package:wordoo/engine/campaign.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/games/game_module.dart';
import 'package:wordoo/games/magic_writer/magic_writer.dart';
import 'package:wordoo/games/magic_writer/recognizer.dart';
import 'package:wordoo/games/sound_ninja/sound_ninja.dart';
import 'package:wordoo/games/sound_portal/sound_portal.dart';
import 'package:wordoo/games/word_builder/word_builder.dart';
import 'package:wordoo/games/word_flash/word_flash.dart';
import 'package:wordoo/models/models.dart';

final pack = LangRegistry.byCode('en');

Item make(Skill s, int step, int seed, [bool Function(Item)? ok]) {
  final gen = ItemGen(GameContent.of('en'), rng: Random(seed));
  for (var i = 0; i < 2000; i++) {
    final it = gen.make(s, step);
    if (ok == null || ok(it)) return it;
  }
  throw StateError('no item');
}

GameCtx ctx(Item it, List<ItemResult> out, {bool demo = false, List<String>? msgs}) =>
    GameCtx(item: it, scaffold: false, pack: pack, demo: demo, feedback: (m, _) => msgs?.add(m), done: out.add);

Future<void> host(WidgetTester t, Widget w) async {
  await t.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 400, height: 760, child: w))));
  await t.pump(const Duration(milliseconds: 100));
}

Future<void> wait(WidgetTester t, int ms) async {
  for (var k = 0; k < ms ~/ 100; k++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

List<Offset> arc(Offset c, double r, double a0, double a1, {double ry = -1}) => [for (var k = 0; k <= 30; k++) c + Offset(cos(a0 + (a1 - a0) * k / 30) * r, sin(a0 + (a1 - a0) * k / 30) * (ry < 0 ? r : ry))];
List<Offset> line(Offset a, Offset b) => [for (var k = 0; k <= 20; k++) Offset.lerp(a, b, k / 20)!];

void main() {
  test('every island alternates between its two games; bosses stay on the main game', () {
    for (final e in islandGame2.entries) {
      final games = {for (var n = 0; n < 9; n++) gameFor(e.key, n)};
      expect(games, {islandGame[e.key], e.value});
      expect(gameFor(e.key, 9), islandGame[e.key], reason: 'boss');
    }
    expect(gameFor(IslandId.castle, 3), GameId.storyQuest);
    for (final g in [GameId.soundNinja, GameId.soundPortal, GameId.wordBuilder, GameId.wordFlash, GameId.magicWriter]) {
      expect(GameModules.hasDedicated(g), isTrue, reason: '$g');
    }
    expect(ninjaBelt(0), 'White Belt');
    expect(ninjaBelt(200), 'Black Belt');
    expect([1, 3, 5, 9].map(flashMs).toList(), [2000, 1500, 1000, 600]);
  });

  testWidgets('Word Flash: jars wait for the flash; the same word is a catch', (t) async {
    final it = make(Skill.wordRecognition, 3, 2);
    final out = <ItemResult>[];
    await host(t, WordFlashItem(ctx: ctx(it, out)));
    await t.tap(find.text(it.options[it.correct].label).last, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 100));
    expect(out, isEmpty, reason: 'cannot answer before the word has flashed');
    await wait(t, 3000);
    await t.tap(find.text(it.options[it.correct].label).last);
    await wait(t, 2000);
    expect(out.single.correct, isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Word Flash: a look-alike re-flashes the word, second chance counts as helped', (t) async {
    final it = make(Skill.wordRecognition, 6, 5);
    final out = <ItemResult>[];
    await host(t, WordFlashItem(ctx: ctx(it, out)));
    await wait(t, 2500);
    final wrong = [for (var i = 0; i < 3; i++) if (i != it.correct) i].first;
    await t.tap(find.text(it.options[wrong].label).last);
    await wait(t, 2500);
    await t.tap(find.text(it.options[it.correct].label).last);
    await wait(t, 2000);
    expect(out.single.correct, isFalse);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Sound Portal: tapping the right portal links it; wrong ones zap and fade', (t) async {
    final it = make(Skill.gpc, 3, 4);
    final out = <ItemResult>[];
    final msgs = <String>[];
    await host(t, SoundPortalItem(ctx: ctx(it, out, msgs: msgs)));
    final wrong = [for (var i = 0; i < 3; i++) if (i != it.correct) i].first;
    await t.tap(find.text(it.options[wrong].label));
    await t.pump(const Duration(milliseconds: 200));
    expect(msgs.last, contains('Crossed'));
    await wait(t, 1000);
    await t.tap(find.text(it.options[it.correct].label));
    await wait(t, 2000);
    expect(out.single.correct, isFalse);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Sound Portal: dragging the beam from the orb onto the right portal', (t) async {
    final it = make(Skill.gpc, 2, 9);
    final out = <ItemResult>[];
    await host(t, SoundPortalItem(ctx: ctx(it, out)));
    final orb = t.getCenter(find.byIcon(Icons.graphic_eq_rounded));
    final target = t.getCenter(find.text(it.options[it.correct].label));
    final g = await t.startGesture(orb);
    for (var k = 1; k <= 10; k++) {
      await g.moveTo(Offset.lerp(orb, target, k / 10)!);
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await wait(t, 2000);
    expect(out.single.correct, isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Word Builder: blocks in the right order hatch a creature', (t) async {
    final it = make(Skill.decoding, 2, 3, (i) => i.id.startsWith('d:'));
    final units = it.stimulus!.split(' · ');
    final out = <ItemResult>[];
    await host(t, WordBuilderItem(ctx: ctx(it, out)));
    for (final u in units) {
      await t.tap(find.text(u).last);
      await t.pump(const Duration(milliseconds: 200));
    }
    await wait(t, 3000);
    expect(out.single.correct, isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Word Builder: wrong order keeps the right blocks and says the sounds', (t) async {
    final it = make(Skill.decoding, 3, 7, (i) => i.id.startsWith('d:') && i.stimulus!.split(' · ').toSet().length >= 3);
    final units = it.stimulus!.split(' · ');
    final out = <ItemResult>[];
    final msgs = <String>[];
    await host(t, WordBuilderItem(ctx: ctx(it, out, msgs: msgs)));
    for (final u in [units[1], units[0], ...units.skip(2)]) {
      await t.tap(find.text(u).last);
      await t.pump(const Duration(milliseconds: 200));
    }
    await wait(t, 800);
    expect(msgs.last, contains('Say it slowly'));
    for (final u in [units[0], units[1]]) {
      await t.tap(find.text(u).last);
      await t.pump(const Duration(milliseconds: 200));
    }
    await wait(t, 3000);
    expect(out.single.correct, isFalse);
    expect(out.single.tags, ['Incorrect blend']);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Sound Ninja: tap listens, swiping through the right fruit slices it', (t) async {
    NinjaCombo.reset();
    final it = make(Skill.phonological, 3, 2, (i) => i.id.startsWith('pr:'));
    final out = <ItemResult>[];
    await host(t, SoundNinjaItem(ctx: ctx(it, out)));
    final fruit = t.getCenter(find.text(it.options[it.correct].emoji!));
    await t.tapAt(fruit);
    await t.pump(const Duration(milliseconds: 200));
    expect(out, isEmpty);
    await t.dragFrom(fruit - const Offset(70, 30), const Offset(140, 60));
    await wait(t, 2000);
    expect(out.single.correct, isTrue);
    expect(NinjaCombo.value, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Sound Ninja syllable round: cut the fruit into its beats', (t) async {
    final it = make(Skill.phonological, 2, 6, (i) => i.id.startsWith('pc:') && i.options[i.correct].label != '1');
    final beats = int.parse(it.options[it.correct].label);
    final out = <ItemResult>[];
    await host(t, SoundNinjaItem(ctx: ctx(it, out)));
    final area = t.getRect(find.byType(GestureDetector).at(1));
    final c = Offset(area.center.dx, area.top + area.height * .45);
    for (var k = 1; k < beats; k++) {
      await t.dragFrom(c + const Offset(-10, -120), const Offset(20, 240));
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('$beats pieces'), findsNothing); // drawn on canvas — check the result instead
    await t.tap(find.text('✓'));
    await wait(t, 2000);
    expect(out.single.correct, isTrue);
    await t.pumpWidget(const SizedBox());
  });

  group('Magic Writer', () {
    late LetterRecognizer rec;
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('handwritten strokes: b and d are told apart; scribbles are not accepted', (t) async {
      await t.runAsync(() async {
        await (FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
        rec = await LetterRecognizer.build();
      });
      final b = [line(const Offset(25, 0), const Offset(25, 100)), arc(const Offset(50, 72), 25, pi, 3 * pi)];
      final d = [line(const Offset(75, 0), const Offset(75, 100)), arc(const Offset(50, 72), 25, 0, 2 * pi)];
      final o = [arc(const Offset(50, 60), 30, 0, 2 * pi, ry: 34)];
      expect(rec.accepts(b, 'b'), isTrue);
      expect(rec.accepts(d, 'd'), isTrue);
      expect(rec.accepts(d, 'b'), isFalse, reason: 'mirror letters must not pass');
      expect(rec.accepts(o, 'o'), isTrue);
      expect(rec.accepts(o, 'x'), isFalse);
      expect(rec.accepts([const [Offset(1, 1), Offset(2, 2)]], 'a'), isFalse);
      expect([2, 4, 8].map(writerGuide).toList(), [WriterGuide.trace, WriterGuide.tiles, WriterGuide.none]);
    });

    testWidgets('writing every rune right opens the chest', (t) async {
      final it = make(Skill.spelling, 1, 3, (i) => i.answer.length == 3);
      final out = <ItemResult>[];
      final msgs = <String>[];
      await t.runAsync(() async {
        await (FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
        rec = await LetterRecognizer.build();
      });
      await host(t, MagicWriterItem(ctx: ctx(it, out, msgs: msgs), recognizer: () async => rec));
      await wait(t, 300);
      // write each letter with the template shape (a perfect child) into its box
      for (var i = 0; i < it.answer.length; i++) {
        // a "perfect child": one continuous stroke through the letter's own shape
        final cloud = rec.sample(it.answer[i], scale: 50).map((s) => s.first).toList();
        final pts = <Offset>[cloud.removeAt(0)];
        while (cloud.isNotEmpty) {
          cloud.sort((a, b) => (a - pts.last).distanceSquared.compareTo((b - pts.last).distanceSquared));
          pts.add(cloud.removeAt(0));
        }
        final box = t.getRect(find.byKey(ValueKey('rune$i')));
        final g = await t.startGesture(box.center + pts.first);
        for (final p in pts.skip(1)) {
          await g.moveTo(box.center + p);
        }
        await g.up();
        await t.pump();
      }
      await t.tap(find.textContaining('Open the chest'));
      await wait(t, 2500);
      expect(out.length, 1, reason: '$msgs');
      expect(out.single.correct, isTrue);
      await t.pumpWidget(const SizedBox());
    });
  });
}
