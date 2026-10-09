import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/content/content_pack.dart';
import 'package:wordoo/engine/campaign.dart';
import 'package:wordoo/engine/item_gen.dart';
import 'package:wordoo/engine/levels.dart';
import 'package:wordoo/engine/skill_model.dart';
import 'package:wordoo/models/models.dart';
import 'package:wordoo/state/app_state.dart';
import 'flow_test.dart' show playQuest;

Map<Skill, SkillModel> models(int step) => {for (final s in Skill.values) s: SkillModel(theta: step + 1.27, calibrationLeft: 0)};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every game has exactly 4 levels, and all 4 use the same kind of task', () {
    final gen = ItemGen(GameContent.of('en'), rng: Random(1));
    String kind(Item it) => '${it.id.split(':').first}${it.kind}${it.audioOptions && it.skill == Skill.phonological ? '' : ''}';
    for (final g in gameLevels.keys.where((g) => g != GameId.starObservatory)) {
      expect(levelsOf(g).names.length, levelsPerGame);
      expect(levelsOf(g).steps.length, levelsPerGame);
      final kinds = <String>{};
      for (var l = 1; l <= 4; l++) {
        for (var k = 0; k < 15; k++) {
          final it = gen.forLevel(g, l);
          kinds.add(kind(it));
        }
      }
      // decoding level 4 uses made-up words ("alien names") — the same blending task
      kinds.removeWhere((k) => k.startsWith('dn'));
      expect(kinds.length, 1, reason: '$g mixes task kinds: $kinds');
    }
  });

  test('difficulty rises from level 1 to level 4', () {
    final gen = ItemGen(GameContent.of('en'), rng: Random(2));
    for (final g in gameLevels.keys.where((g) => g != GameId.starObservatory)) {
      double avg(int l) => [for (var k = 0; k < 20; k++) gen.forLevel(g, l).diff].reduce((a, b) => a + b) / 20;
      expect(avg(4), greaterThan(avg(1)), reason: '$g');
    }
  });

  test('levels open in order; the second game opens after 2 levels of the main game', () {
    final m = models(1);
    final c = Campaign()..startTiers(m);
    const i = IslandId.forest;
    expect(c.levelOpen(i, GameId.soundOrchestra, 1), isTrue);
    expect(c.levelOpen(i, GameId.soundOrchestra, 2), isFalse);
    expect(c.gameUnlocked(i, GameId.soundNinja), isFalse);
    expect(c.levelOpen(i, GameId.soundNinja, 1), isFalse);
    c.clearLevel(c.questFor(i, m, game: GameId.soundOrchestra, level: 1));
    expect(c.levelOpen(i, GameId.soundOrchestra, 2), isTrue);
    expect(c.gameUnlocked(i, GameId.soundNinja), isFalse, reason: 'needs 2 levels');
    c.clearLevel(c.questFor(i, m, game: GameId.soundOrchestra, level: 2));
    expect(c.gameUnlocked(i, GameId.soundNinja), isTrue);
    expect(c.nextLevel(i, GameId.soundOrchestra), 3);
    expect(c.questFor(i, m, game: GameId.soundOrchestra, level: 4).kind, QuestKind.boss);
    expect(c.nodesNeeded(i), 8);
    expect(c.nodesNeeded(IslandId.castle), 4);
  });

  test('a quest never switches game: the board keeps each game on its own levels', () {
    final st = AppState()..loadDemoProfile(0);
    final rng = Random(4);
    for (var k = 0; k < 30; k++) {
      final q = st.board.first;
      final nextBefore = st.campaign.nextLevel(q.island, q.game);
      final o = playQuest(st, q, rng, p: .9);
      expect(o.level, q.level);
      if (o.levelNew) expect(st.campaign.nextLevel(q.island, q.game), isNot(nextBefore));
    }
  });

  test('a level with fewer than half right is not cleared and can be played again', () {
    final st = AppState()..loadDemoProfile(1);
    final q = st.campaign.questFor(IslandId.castle, st.models, game: GameId.storyQuest, level: st.campaign.nextLevel(IslandId.castle, GameId.storyQuest));
    final o = playQuest(st, q, Random(1), p: 0);
    expect(o.levelPassed, isFalse);
    expect(st.campaign.islands[IslandId.castle]!.cleared[GameId.storyQuest] ?? {}, isEmpty);
    expect(st.campaign.nextLevel(IslandId.castle, GameId.storyQuest), q.level);
  });

  test('screening: a strong reader skips at most 2 known levels per game; a beginner skips none', () {
    final strong = Campaign()..startTiers(models(10));
    final weak = Campaign()..startTiers(models(1));
    for (final i in islandSkill.keys) {
      for (final g in islandGames(i)) {
        expect(strong.islands[i]!.skipped[g]!.length, lessThanOrEqualTo(2));
        expect(weak.islands[i]!.skipped[g], isEmpty);
      }
    }
    expect(strong.islands[IslandId.ocean]!.skipped[GameId.wordRocket], {1, 2});
  });
}
