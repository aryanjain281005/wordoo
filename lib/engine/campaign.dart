import '../core/config.dart';
import '../models/models.dart';
import 'levels.dart';
import 'skill_model.dart';

/// The seven islands. Six belong to one literacy skill each; the Star Observatory mixes all six.
enum IslandId { forest, valley, ocean, village, treasure, castle, observatory }

const islandSkill = {
  IslandId.forest: Skill.phonological,
  IslandId.valley: Skill.gpc,
  IslandId.ocean: Skill.decoding,
  IslandId.village: Skill.wordRecognition,
  IslandId.treasure: Skill.spelling,
  IslandId.castle: Skill.comprehension,
};

IslandId islandOf(Skill s) => islandSkill.entries.firstWhere((e) => e.value == s).key;

const islandGame = {
  IslandId.forest: GameId.soundOrchestra,
  IslandId.valley: GameId.letterArcher,
  IslandId.ocean: GameId.wordRocket,
  IslandId.village: GameId.wordDetective,
  IslandId.treasure: GameId.spellingHive,
  IslandId.castle: GameId.storyQuest,
  IslandId.observatory: GameId.starObservatory,
};

/// The second game of each island. It unlocks after [unlockSecondAfter] levels of the island's main game.
const islandGame2 = {
  IslandId.forest: GameId.soundNinja,
  IslandId.valley: GameId.soundPortal,
  IslandId.ocean: GameId.wordBuilder,
  IslandId.village: GameId.wordFlash,
  IslandId.treasure: GameId.magicWriter,
};

/// The games on an island, main game first.
List<GameId> islandGames(IslandId i) => [islandGame[i]!, ?islandGame2[i]];

const seasonNames = ['The Lost Words', 'The Whispering Winds', 'The Starlight Library', 'The Rainbow Tides', 'The Clockwork Carnival', 'The Moonlit Kingdom'];
String seasonName(int season) => season <= seasonNames.length ? seasonNames[season - 1] : 'Season $season';

const tierNames = ['Restore', 'Grow', 'Flourish', 'Shine', 'Legend'];
String tierName(int t) => t <= tierNames.length ? tierNames[t - 1] : 'Legend ${t - tierNames.length + 1}';

/// Story beats (chapter quest titles) per island. Later seasons reuse them in new story order with new framing.
const questTitles = {
  IslandId.forest: ['Wake up Tinku’s tabla', 'Koyal’s lost song', 'Gajju’s sleepy drum', 'The echo cave', 'Firefly rhythm', 'Rhyme river crossing', 'The beat bridge', 'Bamboo whispers', 'The midnight rehearsal', 'BOSS: The Grand Jungle Concert'],
  IslandId.valley: ['The first lantern', 'Garud’s tricky wind', 'Twin letters', 'Lanterns on the river', 'The festival gate', 'Bolt’s crossed wires', 'The mountain echo', 'Sky lantern parade', 'The golden lantern', 'BOSS: The Festival of Lights'],
  IslandId.ocean: ['Fuel for the Bubble Rocket', 'The sunlight reef', 'Coral’s broken bridge', 'Twilight-zone signals', 'The giant clam', 'Jellyfish lights', 'Deep-sea sonar', 'The sunken ship', 'Alien trench names', 'BOSS: The Pearl of Sounds'],
  IslandId.village: ['The mixed-up menu', 'Who switched the school sign?', 'The bakery mystery', 'Jugnu’s night bazaar', 'The missing mangoes', 'Letters at the post office', 'The library riddle', 'The market map', 'The talking signboards', 'BOSS: The Big Village Mystery'],
  IslandId.treasure: ['The empty honeycomb', 'Baby bee nursery', 'Captain Kalam’s first rune', 'The pirate map', 'Honey for the Queen', 'The locked chest', 'Spelling beach', 'The parrot’s poem', 'The treasure cave', 'BOSS: The Golden Hive'],
  IslandId.castle: ['Kitabu forgot his beginning', 'The lost middle', 'The runaway ending', 'The dragon’s diary', 'The princess’s riddle', 'The tower library', 'The talking portraits', 'The secret staircase', 'The midnight story', 'BOSS: The Great Story Restore'],
  IslandId.observatory: ['Star map of sounds', 'Star map of letters', 'Star map of words', 'Star map of spelling', 'Star map of stories', 'The Star Bridge gate'],
};

enum QuestKind { probe, support, standard, challenge, boss, observatory, bonus, echo }

class Quest {
  final IslandId island;
  final QuestKind kind;
  final String title;
  final List<Skill> skills;
  final int items;
  final GameId game;
  final int node; // level index 0–3 of [game] that this quest plays
  const Quest(this.island, this.kind, this.title, this.skills, this.items, this.game, this.node);
  int get level => node + 1; // 1–4
  String get id => '${island.name}:${game.name}:${kind.name}:$node';
  bool get mixed => skills.length > 1;
}

String questKindLabel(QuestKind k) => switch (k) {
      QuestKind.probe => 'Explore',
      QuestKind.support => 'Gentle',
      QuestKind.standard => 'Adventure',
      QuestKind.challenge => 'Challenge',
      QuestKind.boss => 'Boss',
      QuestKind.observatory => 'Star map',
      QuestKind.bonus => 'Bonus',
      QuestKind.echo => 'Echo',
    };

class IslandState {
  int tier;
  double tierStartTheta;
  final Map<GameId, Set<int>> cleared; // levels (1–4) cleared this season, per game
  final Map<GameId, Set<int>> skipped; // levels the screening showed the child already knows (open them early; keys still to win)
  final Map<GameId, Map<int, int>> keys; // v3: best keys won per level (only ever grows)
  bool rescued; // v3: this island's Story Keeper has been freed (all keys)
  IslandState({this.tier = 1, this.tierStartTheta = 0, Map<GameId, Set<int>>? cleared, Map<GameId, Set<int>>? skipped, Map<GameId, Map<int, int>>? keys, this.rescued = false})
      : cleared = cleared ?? {},
        skipped = skipped ?? {},
        keys = keys ?? {};

  int keysOf(GameId g, int level) => keys[g]?[level] ?? 0;
  int gameKeys(GameId g) => keys[g]?.values.fold<int>(0, (a, b) => a + b) ?? 0;

  Set<int> done(GameId g) => {...?cleared[g], ...?skipped[g]};
  int count(GameId g) => done(g).length;
  int get nodes => cleared.keys.followedBy(skipped.keys).toSet().fold(0, (a, g) => a + count(g));
  void reset() {
    cleared.clear();
    skipped.clear();
    keys.clear();
    rescued = false;
  }

  static Map<String, dynamic> _enc(Map<GameId, Set<int>> m) => {for (final e in m.entries) e.key.name: e.value.toList()};
  static Map<GameId, Set<int>> _dec(Object? j) => {
        for (final e in (j as Map? ?? const {}).entries)
          if (GameId.values.any((g) => g.name == e.key)) GameId.values.byName(e.key as String): Set<int>.from(e.value as List),
      };
  Map<String, dynamic> toJson() => {
        'tier': tier,
        'start': tierStartTheta,
        'cleared': _enc(cleared),
        'skipped': _enc(skipped),
        'keys': {for (final e in keys.entries) e.key.name: {for (final k in e.value.entries) '${k.key}': k.value}},
        'rescued': rescued,
      };
  factory IslandState.fromJson(Map<String, dynamic> j) {
    final st = IslandState(tier: j['tier'] as int, tierStartTheta: (j['start'] as num).toDouble(), cleared: _dec(j['cleared']), skipped: _dec(j['skipped']), rescued: j['rescued'] as bool? ?? false);
    final k = j['keys'] as Map?;
    if (k == null) {
      // saves from before keys: every cleared level starts with 1 key (replays win more)
      for (final e in st.cleared.entries) {
        st.keys[e.key] = {for (final l in e.value) l: 1};
      }
    } else {
      for (final e in k.entries) {
        if (!GameId.values.any((g) => g.name == e.key)) continue;
        st.keys[GameId.values.byName(e.key as String)] = {for (final l in (e.value as Map).entries) int.parse(l.key as String): l.value as int};
      }
    }
    return st;
  }
}

class RetestStatus {
  final bool ready;
  final List<String> missing;
  const RetestStatus(this.ready, this.missing);
}

/// Long-term progression: seasons → seven islands → chapters → quests. Never time-based.
class Campaign {
  int season;
  Map<IslandId, IslandState> islands;
  Campaign({this.season = 1, Map<IslandId, IslandState>? islands})
      : islands = islands ?? {for (final i in IslandId.values) i: IslandState()};

  int nodesNeeded(IslandId i) => islandGames(i).length * levelsPerGame;
  bool gameDone(IslandId i, GameId g) => islands[i]!.count(g) >= levelsPerGame;
  /// v3: an island is done when its Story Keeper is free (every key won); the 7th island when the Storm Trial is passed.
  bool chapterDone(IslandId i) => i == IslandId.observatory ? trialPassed : islandKeys(i) >= maxIslandKeys(i);
  int islandKeys(IslandId i) => islandGames(i).fold(0, (a, g) => a + islands[i]!.gameKeys(g));
  int maxIslandKeys(IslandId i) => islandGames(i).length * keysPerGame;
  int get keepersFreed => islandSkill.keys.where(chapterDone).length;

  // ---- Storm Trial (7th island) ----
  int trialBest = 0;
  int trialTries = 0;
  bool trialPassed = false;

  /// Records a finished Storm Trial; returns true when this attempt passed.
  bool recordTrial(int right) {
    trialTries++;
    trialBest = right > trialBest ? right : trialBest;
    final pass = right >= trialPassMark;
    if (pass) trialPassed = true;
    return pass;
  }
  bool get skillChaptersDone => islandSkill.keys.every(chapterDone);
  bool get observatoryUnlocked => skillChaptersDone;
  bool get observatoryDone => chapterDone(IslandId.observatory);

  /// The main game is always open; the second game opens after [unlockSecondAfter] levels of the main game.
  bool gameUnlocked(IslandId i, GameId g) => g == islandGame[i] || islands[i]!.count(islandGame[i]!) >= unlockSecondAfter;

  /// Levels are played in order: a level is open when every level before it is done.
  bool levelOpen(IslandId i, GameId g, int level) {
    if (!gameUnlocked(i, g) || (i == IslandId.observatory && !observatoryUnlocked)) return false;
    final d = islands[i]!.done(g);
    return [for (var l = 1; l < level; l++) l].every(d.contains);
  }

  /// The next level to play (lowest not yet done), or null when all 4 are done.
  int? nextLevel(IslandId i, GameId g) {
    final d = islands[i]!.done(g);
    for (var l = 1; l <= levelsPerGame; l++) {
      if (!d.contains(l)) return l;
    }
    return null;
  }

  /// Island restoration for the map: 70 % levels cleared + 30 % real skill growth this tier.
  double restoration(IslandId i, Map<Skill, SkillModel> m) {
    final st = islands[i]!;
    if (i == IslandId.observatory) return trialPassed ? 100 : (trialBest / trialQuestions * 100).roundToDouble();
    final chapter = (islandKeys(i) / maxIslandKeys(i)).clamp(0.0, 1.0);
    final growth = ((m[islandSkill[i]!]!.theta - st.tierStartTheta) / 1.5).clamp(0.0, 1.0);
    return (chapter * 70 + growth * 30).roundToDouble();
  }

  /// Retest prerequisite: all seven islands played through + enough stable evidence per skill.
  RetestStatus retest(Map<Skill, SkillModel> m) {
    final missing = <String>[];
    for (final i in islandSkill.keys) {
      if (!chapterDone(i)) missing.add('${_islandName[i]}: ${islandKeys(i)}/${maxIslandKeys(i)} keys');
    }
    if (!observatoryDone) missing.add('Storm Trial: not passed yet (best ${trialBest}/$trialQuestions, needs $trialPassMark)');
    for (final s in Skill.values) {
      final mm = m[s]!;
      if (mm.cycleItems < Cfg.retestMinItemsPerSkill) missing.add('${_skillName[s]}: ${mm.cycleItems}/${Cfg.retestMinItemsPerSkill} answers');
      if (!mm.stable) missing.add('${_skillName[s]}: level still settling');
    }
    return RetestStatus(missing.isEmpty, missing);
  }

  /// Start of a season: remember where each skill starts, and let the screening skip levels the child
  /// clearly knows already (at most 2 per game, so every game is always played).
  void startTiers(Map<Skill, SkillModel> m) {
    for (final e in islandSkill.entries) {
      final st = islands[e.key]!;
      st.tierStartTheta = m[e.value]!.theta;
      for (final g in islandGames(e.key)) {
        final step = m[e.value]!.step;
        final bump = st.tier - 1;
        final skip = <int>{for (var l = 1; l <= 2; l++) if (levelStep(g, l, bump: bump) <= step - 2) l};
        // only a run from level 1 counts (so the levels stay in order)
        final run = <int>{};
        for (var l = 1; skip.contains(l); l++) {
          run.add(l);
        }
        st.skipped[g] = run;
      }
    }
  }

  /// After a retest: next season, every island grows a tier, all levels restart a little harder.
  void nextSeason(Map<Skill, SkillModel> m) {
    season++;
    trialBest = 0;
    trialTries = 0;
    trialPassed = false;
    for (final st in islands.values) {
      st.tier++;
      st.reset();
    }
    startTiers(m);
  }

  /// Clears every level on an island (tests and the developer panel).
  void clearIsland(IslandId i) {
    if (i == IslandId.observatory) {
      trialPassed = true;
      trialBest = trialQuestions;
      return;
    }
    for (final g in islandGames(i)) {
      islands[i]!.cleared[g] = {for (var l = 1; l <= levelsPerGame; l++) l};
      islands[i]!.keys[g] = {for (var l = 1; l <= levelsPerGame; l++) l: maxKeysFor(l)};
    }
  }

  /// Saves the keys of one play (the best result per level counts). Returns the keys this play won.
  int recordKeys(Quest q, int right, int total) {
    final won = keysFor(q.level, right, total);
    final m = islands[q.island]!.keys.putIfAbsent(q.game, () => {});
    if (won > (m[q.level] ?? 0)) m[q.level] = won;
    return won;
  }

  /// v3: the lowest open level of [g] that still has keys to win (null when every key is won).
  int? keyLevel(IslandId i, GameId g) {
    for (var l = 1; l <= levelsPerGame; l++) {
      if (levelOpen(i, g, l) && islands[i]!.keysOf(g, l) < maxKeysFor(l)) return l;
    }
    return null;
  }

  /// Marks the quest's level cleared. Returns true if this cleared a level that was not cleared before.
  bool clearLevel(Quest q) {
    final st = islands[q.island]!;
    if (st.done(q.game).contains(q.level)) return false;
    st.cleared.putIfAbsent(q.game, () => {}).add(q.level);
    return true;
  }

  // ---------------- quest generation ----------------
  static double need(SkillModel m) {
    final errs = m.errors.values.fold<double>(0, (a, b) => a + b);
    return .55 * (10 - m.step) / 9 + .25 * (errs / 6).clamp(0, 1) + (m.status == SkillStatus.struggling ? .2 : 0);
  }

  /// Quest title for a game level: the main game uses chapter beats 1–3 and the boss (10), the second game
  /// beats 4–7, so every level has its own story beat.
  static int titleIndex(IslandId i, GameId g, int level) {
    if (i == IslandId.observatory) return level == 4 ? 5 : level - 1;
    if (g == islandGame[i]) return level == 4 ? 9 : level - 1;
    return 2 + level;
  }

  /// A quest that plays [level] of [game] on island [i].
  Quest questFor(IslandId i, Map<Skill, SkillModel> m, {GameId? game, int? level, QuestKind? force}) {
    final g = game ?? islandGame[i]!;
    final st = islands[i]!;
    final lv = (level ?? nextLevel(i, g) ?? levelsPerGame).clamp(1, levelsPerGame);
    final titles = questTitles[i]!;
    final base = titles[titleIndex(i, g, lv).clamp(0, titles.length - 1)];
    if (i == IslandId.observatory) {
      return Quest(i, force ?? QuestKind.observatory, base, Skill.values.toList(), Cfg.itemsMixed, GameId.starObservatory, lv - 1);
    }
    final mm = m[islandSkill[i]!]!;
    final replay = st.done(g).contains(lv);
    final kind = force ??
        (replay
            ? QuestKind.bonus
            : (lv == levelsPerGame ? (g == islandGame[i] ? QuestKind.boss : QuestKind.challenge) : (mm.status == SkillStatus.struggling ? QuestKind.support : QuestKind.standard)));
    final items = switch (kind) {
      QuestKind.support => Cfg.itemsSupport,
      QuestKind.challenge => Cfg.itemsChallenge,
      QuestKind.boss => Cfg.itemsBoss,
      _ => Cfg.itemsStandard,
    };
    final title = switch (kind) {
      QuestKind.echo => 'Echo: $base',
      QuestKind.bonus => 'Replay: $base',
      _ => season > 1 ? '$base · Part $season' : base,
    };
    return Quest(i, kind, title, [islandSkill[i]!], items, g, lv - 1);
  }

  /// Always-on quest board (no daily limit): the next level of each open game, weakest skill first.
  List<Quest> board(Map<Skill, SkillModel> m) {
    final out = <Quest>[];
    if (observatoryUnlocked && !observatoryDone) out.add(questFor(IslandId.observatory, m));
    final islandsByNeed = islandSkill.keys.toList()..sort((a, b) => need(m[islandSkill[b]!]!).compareTo(need(m[islandSkill[a]!]!)));
    // islands that still have a level to play, weakest skill first
    Quest? nextOn(IslandId i, {bool second = false}) {
      final games = islandGames(i);
      for (final g in second ? games.skip(1) : games.take(1)) {
        final lv = nextLevel(i, g) ?? keyLevel(i, g); // a new level first, then a level with keys still to win
        if (lv != null && levelOpen(i, g, lv)) return questFor(i, m, game: g, level: lv);
      }
      return null;
    }

    final open = [for (final i in islandsByNeed) if (nextOn(i) != null || nextOn(i, second: true) != null) i];
    // weakest need, a middle skill, and a stretch for a strong skill (strong and weak skills grow together)
    final picks = <IslandId>[if (open.isNotEmpty) open.first, if (open.length >= 3) open[open.length ~/ 2], if (open.length >= 2) open.last, ...open];
    for (final second in [false, true]) {
      for (final i in picks) {
        if (out.length >= Cfg.boardSize) break;
        if (!second && out.any((q) => q.island == i)) continue;
        final q = nextOn(i, second: second);
        if (q != null && !out.any((o) => o.id == q.id)) out.add(q);
      }
    }
    // everything cleared: practice where evidence is still thin, then spaced review (echo)
    if (out.length < Cfg.boardSize) {
      final thin = Skill.values.where((s) => m[s]!.cycleItems < Cfg.retestMinItemsPerSkill || !m[s]!.stable).toList()
        ..sort((a, b) => m[a]!.cycleItems.compareTo(m[b]!.cycleItems));
      for (final s in thin) {
        if (out.length >= Cfg.boardSize) break;
        final i = islandOf(s);
        if (!out.any((q) => q.island == i)) out.add(questFor(i, m, level: levelsPerGame, force: QuestKind.bonus));
      }
    }
    for (final i in islandsByNeed) {
      if (out.length >= Cfg.boardSize) break;
      if (!out.any((q) => q.island == i)) out.add(questFor(i, m, level: 3, force: QuestKind.echo));
    }
    return out.take(Cfg.boardSize).toList();
  }

  Map<String, dynamic> toJson() => {
        'season': season,
        'islands': islands.map((k, v) => MapEntry(k.name, v.toJson())),
        'trial': {'best': trialBest, 'tries': trialTries, 'passed': trialPassed},
      };
  factory Campaign.fromJson(Map<String, dynamic> j) => _withTrial(j, Campaign(
        season: j['season'] as int,
        islands: {
          for (final i in IslandId.values)
            i: (j['islands'] as Map)[i.name] == null ? IslandState() : IslandState.fromJson(Map<String, dynamic>.from((j['islands'] as Map)[i.name] as Map)),
        },
      ));

  static Campaign _withTrial(Map<String, dynamic> j, Campaign c) {
    final t = j['trial'] as Map?;
    if (t != null) {
      c.trialBest = t['best'] as int? ?? 0;
      c.trialTries = t['tries'] as int? ?? 0;
      c.trialPassed = t['passed'] as bool? ?? false;
    }
    return c;
  }

  static const _islandName = {
    IslandId.forest: 'Sound Forest',
    IslandId.valley: 'Symbol Valley',
    IslandId.ocean: 'Word Ocean',
    IslandId.village: 'Word Village',
    IslandId.treasure: 'Treasure Island',
    IslandId.castle: 'Story Castle',
    IslandId.observatory: 'Storm Citadel',
  };
  static String islandName(IslandId i) => _islandName[i]!;
  static const _skillName = {
    Skill.phonological: 'Sounds',
    Skill.gpc: 'Letters & sounds',
    Skill.decoding: 'Decoding',
    Skill.wordRecognition: 'Word reading',
    Skill.spelling: 'Spelling',
    Skill.comprehension: 'Comprehension',
  };
}
