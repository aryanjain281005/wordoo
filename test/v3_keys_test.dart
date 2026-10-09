import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/engine/campaign.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/engine/levels.dart';
import 'package:wordoo/engine/skill_model.dart';
import 'package:wordoo/models/models.dart';
import 'package:wordoo/state/app_state.dart';

Map<Skill, SkillModel> models() => {for (final s in Skill.values) s: SkillModel(theta: 4.27, calibrationLeft: 0)};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keys per level follow GAME_DESIGN_V3 §3.1', () {
    expect([for (var r = 0; r <= 6; r++) keysFor(1, r, 6)], [0, 0, 0, 1, 1, 2, 3]);
    expect([for (var r = 0; r <= 8; r++) keysFor(4, r, 8)], [0, 0, 0, 0, 1, 1, 3, 3, 5]);
    expect([1, 2, 3, 4].map(maxKeysFor).toList(), [3, 3, 3, 5]);
    expect(keysPerGame, 14);
  });

  test('island maximum: 28 with two games, 14 on Story Castle; best result per level counts', () {
    final c = Campaign()..startTiers(models());
    expect(c.maxIslandKeys(IslandId.forest), 28);
    expect(c.maxIslandKeys(IslandId.castle), 14);
    final q = c.questFor(IslandId.forest, models(), game: GameId.soundOrchestra, level: 1);
    expect(c.recordKeys(q, 5, 6), 2);
    expect(c.recordKeys(q, 3, 6), 1);
    expect(c.islands[IslandId.forest]!.keysOf(GameId.soundOrchestra, 1), 2, reason: 'a worse replay never lowers keys');
    expect(c.recordKeys(q, 6, 6), 3);
    expect(c.islandKeys(IslandId.forest), 3);
  });

  test('a Keeper is freed only with every key on the island', () {
    final st = AppState()..loadDemoProfile(0);
    final c = st.campaign;
    const i = IslandId.castle; // one game, 14 keys
    for (var l = 1; l <= 4; l++) {
      c.islands[i]!.cleared.putIfAbsent(GameId.storyQuest, () => {}).add(l);
      c.islands[i]!.keys.putIfAbsent(GameId.storyQuest, () => {})[l] = maxKeysFor(l);
    }
    c.islands[i]!.keys[GameId.storyQuest]![4] = 3; // one short on the boss
    expect(c.chapterDone(i), isFalse);
    expect(c.islandKeys(i), 12);
    // a perfect boss replay frees Pari
    final q = c.questFor(i, st.models, game: GameId.storyQuest, level: 4);
    final gen = ItemGen(st.content, rng: Random(1));
    final res = <ItemResult>[];
    for (var k = 0; k < q.items; k++) {
      final it = gen.forLevel(GameId.storyQuest, 4);
      final r = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: true, ms: 2000);
      res.add(r);
      st.recordItem(it, r);
    }
    final o = st.completeQuest(q, res, 60, {Skill.comprehension: 5});
    expect(o.keysWon, 5);
    expect(o.rescued, i);
    expect(c.chapterDone(i), isTrue);
    expect(c.islands[i]!.rescued, isTrue);
  });

  test('Storm Trial: opens after six rescues; 21 of 30 passes; the result is saved', () async {
    final st = AppState()..loadDemoProfile(1);
    final c = st.campaign;
    expect(c.observatoryUnlocked, isFalse);
    for (final i in islandSkill.keys) {
      c.clearIsland(i);
    }
    expect(c.keepersFreed, 6);
    expect(c.observatoryUnlocked, isTrue);
    final gen = ItemGen(st.content, rng: Random(2));
    final items = [for (final s in Skill.values) for (var k = 0; k < trialPerSkill; k++) gen.make(s, 5)];
    expect(items.length, trialQuestions);
    List<ItemResult> answers(int right) => [for (var k = 0; k < items.length; k++) ItemResult(itemId: items[k].id, skill: items[k].skill, level: 5, correct: k < right, ms: 2000)];
    expect(st.completeTrial(items, answers(20), 600), isFalse);
    expect(c.trialPassed, isFalse);
    expect(c.trialBest, 20);
    expect(st.completeTrial(items, answers(21), 600), isTrue);
    expect(c.trialPassed, isTrue);
    expect(c.chapterDone(IslandId.observatory), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final again = AppState();
    await again.load();
    expect(again.campaign.trialPassed, isTrue);
    expect(again.campaign.trialBest, 21);
    expect(again.campaign.islandKeys(IslandId.forest), 28);
  });

  test('saves from before keys: every cleared level starts with 1 key', () {
    final s = IslandState.fromJson({'tier': 1, 'start': 0.0, 'cleared': {'soundOrchestra': [1, 2]}, 'skipped': {}});
    expect(s.keysOf(GameId.soundOrchestra, 1), 1);
    expect(s.keysOf(GameId.soundOrchestra, 2), 1);
    expect(s.keysOf(GameId.soundOrchestra, 3), 0);
  });

  test('when every level is cleared, the board offers levels with keys still to win', () {
    final c = Campaign()..startTiers(models());
    for (final g in islandGames(IslandId.forest)) {
      c.islands[IslandId.forest]!.cleared[g] = {1, 2, 3, 4};
      c.islands[IslandId.forest]!.keys[g] = {1: 3, 2: 3, 3: 2, 4: 5};
    }
    expect(c.keyLevel(IslandId.forest, GameId.soundOrchestra), 3);
    final b = c.board(models());
    expect(b.any((q) => q.island == IslandId.forest && q.level == 3), isTrue);
  });
}
