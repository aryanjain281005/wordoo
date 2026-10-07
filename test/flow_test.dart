import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/data/lang.dart';
import 'package:wordoo/data/skills.dart';
import 'package:wordoo/engine/item_factory.dart';
import 'package:wordoo/engine/personalizer.dart';
import 'package:wordoo/engine/report.dart';
import 'package:wordoo/main.dart';
import 'package:wordoo/models/models.dart';
import 'package:wordoo/state/app_state.dart';
import 'package:wordoo/widgets/item_views.dart';

List<ItemResult> _results(Skill s, List<bool> ok) => [for (var i = 0; i < ok.length; i++) ItemResult(itemId: '$i', skill: s, level: 2, correct: ok[i], ms: 900)];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('profiles A and B produce different missions, levels and plans', () {
    final a = AppState()..loadDemoProfile(0);
    final b = AppState()..loadDemoProfile(1);
    expect(a.skills[Skill.spelling]!.level, 1);
    expect(a.skills[Skill.wordRecognition]!.level, 3);
    expect(b.skills[Skill.spelling]!.level, 3);
    expect(b.skills[Skill.decoding]!.level, 1);
    expect(a.missions.map((m) => m.game).toList(), isNot(b.missions.map((m) => m.game).toList()));
    expect(a.missions.first.skill, Skill.spelling);
    expect(b.missions.first.skill, Skill.decoding);
  });

  test('difficulty rises on success and falls (with scaffold) on repeated errors', () {
    final st = AppState()..loadDemoProfile(0);
    // Word recognition: strong, starts at level 3 → perfect rounds push it up
    st.recordGame(GameId.wordDetective, _results(Skill.wordRecognition, [true, true, true, true, true]), 120);
    expect(st.skills[Skill.wordRecognition]!.level, 4);
    // Spelling: needs support, level 1 stays at floor but scaffold turns on
    final out = st.recordGame(GameId.spellingHive, _results(Skill.spelling, [false, false, true, false, false]), 150);
    expect(st.skills[Skill.spelling]!.level, 1);
    expect(st.skills[Skill.spelling]!.scaffold, true);
    expect(out.stars, greaterThanOrEqualTo(1)); // never zero: effort is rewarded
    // Decoding developing at 2: mixed → stays; then perfect → up
    st.recordGame(GameId.wordRocket, _results(Skill.decoding, [true, true, true, true, true]), 100);
    expect(st.skills[Skill.decoding]!.level, 3);
  });

  test('live level-down inside a round is kept', () {
    final st = AppState()..loadDemoProfile(0);
    final before = st.skills[Skill.decoding]!.level; // 2
    st.recordGame(GameId.wordRocket, _results(Skill.decoding, [false, false, true, true, true]), 100, endLevel: before - 1);
    expect(st.skills[Skill.decoding]!.level, before - 1);
    expect(st.skills[Skill.decoding]!.scaffold, true);
  });

  test('missions complete, rewards unlock, day completes', () {
    final st = AppState()..loadDemoProfile(0);
    SessionOutcome? last;
    for (final m in List.of(st.missions)) {
      last = st.recordGame(m.game, _results(m.skill, [true, true, true, true, false]), 130);
    }
    expect(st.dayDone, true);
    expect(last!.dayComplete, true);
    expect(st.practiceDays, contains(1));
    expect(st.stars, greaterThanOrEqualTo(5));
    expect(st.unlocked, isNotEmpty);
  });

  test('week cycle: end of week → reassessment → report → next plan', () {
    final st = AppState()..loadDemoProfile(0);
    for (final m in List.of(st.missions)) {
      st.recordGame(m.game, _results(m.skill, [true, true, false, true, true]), 130);
    }
    st.jumpToEndOfWeek();
    expect(st.weekReady, true);
    final planBefore = Personalizer.weekFocus(st.skills);
    st.simulateWeekOne();
    expect(st.history.length, 2);
    expect(st.screen, AppScreen.weeklyReport);
    expect(Report.overall(st), greaterThan(0));
    expect(Report.observations(st), isNotEmpty);
    expect(st.assessForm, Pool.a); // week 2 would reuse the A form only after B was used
    st.startNextWeek();
    expect(st.day, 1);
    expect(st.practiceDays, isEmpty);
    expect(st.missions.length, 3);
    expect(planBefore.length, 3);
  });

  test('assessment results → baseline with independent levels', () {
    final st = AppState();
    final results = <ItemResult>[
      for (final s in Skill.values) ...[
        for (var lv = 1; lv <= 3; lv++) ItemResult(itemId: '$s$lv', skill: s, level: lv, correct: s == Skill.gpc || s == Skill.wordRecognition || (s == Skill.decoding && lv < 3), ms: 800, tags: const [])
      ]
    ];
    st.completeBaseline(results);
    expect(st.bandOf(Skill.gpc), Band.strong);
    expect(st.bandOf(Skill.spelling), Band.needsSupport);
    expect(st.skills[Skill.gpc]!.level, greaterThan(st.skills[Skill.spelling]!.level));
    expect(st.screen, AppScreen.skillMap);
  });

  testWidgets('choice item: wrong answer is gentle, correct is rewarded', (tester) async {
    final pack = LangRegistry.byCode('en');
    final item = ItemFactory(pack).make(Skill.wordRecognition, 1, {Pool.p});
    ItemResult? got;
    String? feedback;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ItemView(item: item, skin: GameSkin.detective, pack: pack, autoSpeak: false, onDone: (r) => got = r, onFeedback: (m, g) => feedback = m),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    final wrong = item.options.firstWhere((o) => o != item.options[item.correct]).label;
    await tester.tap(find.text(wrong));
    await tester.pump(const Duration(milliseconds: 100));
    expect(feedback, contains('Almost'));
    expect(feedback!.toLowerCase(), isNot(contains('wrong')));
    await tester.tap(find.text(item.options[item.correct].label));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(got, isNotNull);
    expect(got!.correct, false); // first attempt wasn't right
    expect(got!.tags, isNotEmpty);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('spelling item can be built and checked', (tester) async {
    final pack = LangRegistry.byCode('hi');
    final item = ItemFactory(pack).make(Skill.spelling, 2, {Pool.p});
    ItemResult? got;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ItemView(item: item, skin: GameSkin.hive, pack: pack, autoSpeak: false, onDone: (r) => got = r)),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    for (final u in item.answer) {
      // tap the first still-visible tile with that text
      await tester.tap(find.text(u).last);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.text('जाँचो'));
    await tester.pump(const Duration(milliseconds: 2000));
    expect(got?.correct, true);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('app boots to the landing screen', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => AppState()..load(), child: const ReadleApp()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Start Your Adventure'), findsOneWidget);
    expect(find.textContaining('Parent'), findsOneWidget);
  });
}
