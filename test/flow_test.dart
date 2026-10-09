import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/core/config.dart';
import 'package:wordoo/data/lang.dart';
import 'package:wordoo/engine/campaign.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/main.dart';
import 'package:wordoo/models/models.dart';
import 'package:wordoo/screening/battery.dart';
import 'package:wordoo/screening/models.dart' as scr;
import 'package:wordoo/screening/scorer.dart';
import 'package:wordoo/state/app_state.dart';
import 'package:wordoo/widgets/item_views.dart';

/// Plays one quest with a simulated child who answers correctly with probability [p].
SessionOutcome playQuest(AppState st, Quest q, Random rng, {double p = .8}) {
  final gen = ItemGen(st.content, rng: rng, seen: st.itemSeen);
  final start = {for (final s in q.skills.toSet()) s: st.model(s).step};
  final results = <ItemResult>[];
  for (var i = 0; i < q.items; i++) {
    final s = q.skills[i % q.skills.length];
    final it = gen.make(s, st.model(s).step);
    final ok = rng.nextDouble() < p;
    final r = ItemResult(itemId: it.id, skill: s, level: it.level, correct: ok, ms: 2500, tags: ok ? const [] : const ['Wrong vowel']);
    results.add(r);
    st.recordItem(it, r);
  }
  return st.completeQuest(q, results, 90, start);
}

Map<String, List<scr.ItemResponse>> screeningAll(double score) => {
      for (final d in battery)
        d.id: [scr.ItemResponse(itemId: d.id, subtest: d.id, score: score, ms: 1000, rate: d.normJunior.rateMean == null ? null : d.normJunior.rateMean! * (score >= .9 ? 1.3 : .5))],
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('uneven profiles: each skill starts at its own step, no global level', () {
    final a = AppState()..loadDemoProfile(0);
    final b = AppState()..loadDemoProfile(1);
    expect(a.model(Skill.spelling).step, lessThan(a.model(Skill.wordRecognition).step));
    expect(b.model(Skill.spelling).step, greaterThan(b.model(Skill.decoding).step));
    expect(a.board.first.island, isNot(b.board.first.island));
    expect(Skill.values.map((s) => a.model(s).step).toSet().length, greaterThan(2));
  });

  test('screening drives the start; strong never starts at level 1, weak never too high', () {
    final st = AppState()..grade = 'Class 1';
    final resp = screeningAll(1);
    resp['spelling'] = [const scr.ItemResponse(itemId: 's1', subtest: 'spelling', score: 0, ms: 900, tag: 'Wrong vowel')];
    final r = Scorer.build(responses: resp, band: scr.GradeBand.junior, lang: 'en', pool: 'A', bg: scr.Background(schoolMedium: 'English'), speechAvailable: true, minutes: 15);
    st.completeScreening(r, resp);
    expect(st.model(Skill.spelling).step, lessThanOrEqualTo(2));
    expect(st.model(Skill.gpc).step, greaterThanOrEqualTo(5));
    expect(st.model(Skill.spelling).errors.containsKey('Wrong vowel'), isTrue); // screening error seeds practice
    expect(st.screen, AppScreen.skillMap);
  });

  test('no daily cap: quests keep coming after any number of rounds', () {
    final st = AppState()..loadDemoProfile(0);
    final rng = Random(5);
    for (var i = 0; i < 25; i++) {
      final b = st.board;
      expect(b.length, Cfg.boardSize);
      playQuest(st, b[i % b.length], rng);
    }
    expect(st.sessions.isNotEmpty, isTrue);
    expect(st.cycleRounds, 25);
  });

  test('gameplay keeps adapting each skill separately', () {
    final st = AppState()..loadDemoProfile(0);
    final rng = Random(6);
    final strongStart = st.model(Skill.wordRecognition).step;
    final weakStart = st.model(Skill.spelling).step;
    for (var i = 0; i < 4; i++) {
      playQuest(st, st.campaign.questFor(IslandId.village, st.models), rng, p: 1);
      playQuest(st, st.campaign.questFor(IslandId.treasure, st.models), rng, p: .2);
    }
    expect(st.model(Skill.wordRecognition).step, greaterThan(strongStart));
    expect(st.model(Skill.spelling).step, lessThanOrEqualTo(weakStart));
    expect(st.model(Skill.spelling).needsScaffold, isTrue);
  });

  test('full long-term loop: 7 islands → retest unlocks → check-in → new season', () {
    final st = AppState()..loadDemoProfile(1);
    final rng = Random(7);
    var guard = 0;
    var observatorySeen = false;
    while (!st.retestReady && guard++ < 3000) {
      final q = st.board.first;
      if (q.island == IslandId.observatory) {
        // v3: the Storm Trial — a well-practised child passes it
        observatorySeen = true;
        final gen = ItemGen(st.content, rng: rng, seen: st.itemSeen);
        final items = [for (final s in Skill.values) for (var k = 0; k < 5; k++) gen.make(s, st.model(s).step)];
        final res = [for (final it in items) ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: rng.nextDouble() < .9, ms: 2500)];
        st.completeTrial(items, res, 600);
        continue;
      }
      playQuest(st, q, rng, p: .97); // v3 needs every key: a near-perfect child, replaying levels until all keys are won
    }
    expect(st.retestReady, isTrue, reason: st.retest.missing.join('; '));
    expect(observatorySeen, isTrue);
    for (final i in IslandId.values) {
      expect(st.campaign.chapterDone(i), isTrue);
    }
    for (final s in Skill.values) {
      expect(st.model(s).cycleItems, greaterThanOrEqualTo(Cfg.retestMinItemsPerSkill));
    }
    // the check-in itself
    final resp = screeningAll(.9);
    final r = Scorer.build(responses: resp, band: scr.GradeBand.junior, lang: 'en', pool: 'B', bg: scr.Background(schoolMedium: 'English'), speechAvailable: true, minutes: 15);
    st.completeScreening(r, resp);
    expect(st.screen, AppScreen.weeklyReport);
    expect(st.history.length, 2);
    st.startNextCycle();
    expect(st.campaign.season, 2);
    expect(st.campaign.islands.values.every((i) => i.tier == 2 && i.cleared.isEmpty), isTrue);
    expect(st.retestReady, isFalse);
    expect(st.board.length, Cfg.boardSize);
  });

  test('state survives an app restart', () async {
    final st = AppState()..loadDemoProfile(0);
    playQuest(st, st.board.first, Random(8));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final again = AppState();
    await again.load();
    expect(again.explorerName, 'Aarav');
    expect(again.campaign.islands.values.fold<int>(0, (a, i) => a + i.nodes), st.campaign.islands.values.fold<int>(0, (a, i) => a + i.nodes));
    expect(again.campaign.islands.values.fold<int>(0, (a, i) => a + i.cleared.values.fold(0, (x, y) => x + y.length)), lessThanOrEqualTo(1));
    expect(again.model(Skill.spelling).items, st.model(Skill.spelling).items);
    expect(again.langCode, 'en');
  });

  testWidgets('heard options: first tap listens, second tap chooses', (tester) async {
    final pack = LangRegistry.byCode('en');
    final gen = ItemGen(GameContent.of('en'), rng: Random(9));
    late Item it;
    do {
      it = gen.make(Skill.phonological, 8);
    } while (!it.audioOptions);
    ItemResult? got;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ItemView(item: it, skin: GameSkin.orchestra, pack: pack, autoSpeak: false, onDone: (r) => got = r))));
    await tester.pump(const Duration(milliseconds: 300));
    final card = find.text('${it.correct + 1}');
    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 100));
    expect(got, isNull);
    await tester.tap(find.byIcon(Icons.check_circle_rounded));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(got?.correct, isTrue);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('app boots to the landing screen', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => AppState()..load(), child: const ReadleApp()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Let’s Start'), findsOneWidget);
  });
}
