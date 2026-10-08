import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/content/en/en_stories.dart';
import 'package:wordoo/data/lang.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/games/game_module.dart';
import 'package:wordoo/games/story_quest/story_quest.dart';
import 'package:wordoo/models/models.dart';
import 'package:wordoo/state/app_state.dart';
import 'package:wordoo/story/book_text.dart';

void main() {
  final pack = LangRegistry.byCode('en');

  Item storyItem(int step, int seed) {
    final gen = ItemGen(GameContent.of('en'), rng: Random(seed));
    Item it;
    do {
      it = gen.make(Skill.comprehension, step);
    } while (!isAuthoredStory(storyIdOfItem(it.id)));
    return it;
  }

  Future<void> pumpItem(WidgetTester tester, Item it, {bool demo = false, List<ItemResult>? out, List<String>? msgs}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 760,
          child: StoryQuestItem(ctx: GameCtx(item: it, scaffold: false, pack: pack, demo: demo, feedback: (m, _) => msgs?.add(m), done: (r) => out?.add(r))),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> flipToEnd(WidgetTester tester, Item it) async {
    final n = splitSentences(it.passage!).length;
    for (var i = 1; i < n; i++) {
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  test('stories split into panels; quotes stay with their sentence', () {
    expect(splitSentences('Milo lost his red hat in the park. Then it began to rain, so Milo felt cold. A kind duck found the hat and gave it back.').length, 3);
    final island = enStories.firstWhere((s) => s.id == 's-island');
    expect(splitSentences(island.text).any((p) => p.endsWith('sea.”')), isTrue);
    expect(storyIdOfItem('st:s-hat:2'), 's-hat');
    expect(storyIdOfItem('st:tpl:3:99:0'), 'tpl:3:99');
  });

  test('every authored story page and question has Dadi / Kitabu narration', () {
    final lines = jsonDecode(File('assets/story/books_en.json').readAsStringSync()) as Map<String, dynamic>;
    for (final s in enStories) {
      final pages = splitSentences(s.text);
      for (var i = 0; i < pages.length; i++) {
        expect((lines[bookLineId(s.id, i)] as Map?)?['text'], pages[i], reason: 'run dart run tool/export_books.dart');
        expect(File('assets/vo/en/${bookLineId(s.id, i)}.ogg').existsSync(), isTrue, reason: 'run tool/gen_voices.py');
      }
      for (var q = 0; q < s.questions.length; q++) {
        expect(File('assets/vo/en/${questionLineId(s.id, q)}.ogg').existsSync(), isTrue);
      }
    }
  });

  test('Story Quest is the registered module for its game', () => expect(GameModules.hasDedicated(GameId.storyQuest), isTrue));

  testWidgets('reading to the last panel brings the question; the right answer restores the story', (tester) async {
    final it = storyItem(8, 4);
    final out = <ItemResult>[];
    await pumpItem(tester, it, out: out);
    expect(find.text(it.stimulus!), findsNothing, reason: 'question waits until the story is read');
    await flipToEnd(tester, it);
    expect(find.text(it.stimulus!), findsOneWidget);
    await tester.pump(const Duration(seconds: 6)); // Kitabu asks
    await tester.ensureVisible(find.text(it.options[it.correct].label));
    await tester.tap(find.text(it.options[it.correct].label));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Story restored'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(out.single.correct, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('a wrong answer looks back in the story, then counts as helped', (tester) async {
    final it = storyItem(8, 9);
    final out = <ItemResult>[];
    final msgs = <String>[];
    await pumpItem(tester, it, out: out, msgs: msgs);
    await flipToEnd(tester, it);
    await tester.pump(const Duration(seconds: 6));
    final wrong = List.generate(it.options.length, (i) => i).firstWhere((i) => i != it.correct);
    await tester.ensureVisible(find.text(it.options[wrong].label));
    await tester.tap(find.text(it.options[wrong].label));
    await tester.pump(const Duration(milliseconds: 300));
    expect(msgs.last, contains('look back'));
    await tester.pump(const Duration(seconds: 12)); // turns to the answer panel and reads it
    await tester.ensureVisible(find.text(it.options[it.correct].label));
    await tester.tap(find.text(it.options[it.correct].label));
    await tester.pump(const Duration(seconds: 3));
    expect(out.single.correct, isFalse);
    expect(out.single.tags, isNotEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('demo turns the pages itself and never reports', (tester) async {
    final it = storyItem(5, 2);
    final out = <ItemResult>[];
    await pumpItem(tester, it, demo: true, out: out);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text(it.stimulus!), findsOneWidget);
    expect(out, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  test('understood stories join the Library', () async {
    SharedPreferences.setMockInitialValues({});
    final st = AppState();
    final it = storyItem(6, 1);
    st.recordItem(it, ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: true, ms: 1000));
    expect(st.libraryBooks, {storyIdOfItem(it.id)});
  });
}
