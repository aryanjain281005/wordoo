import '../core/config.dart';
import '../models/models.dart';
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

/// The second game of each island (Phase 4). Quests alternate between the island's two games so both get
/// played; the chapter boss (node 10) is always the island's main game.
const islandGame2 = {
  IslandId.forest: GameId.soundNinja,
  IslandId.valley: GameId.soundPortal,
  IslandId.ocean: GameId.wordBuilder,
  IslandId.village: GameId.wordFlash,
  IslandId.treasure: GameId.magicWriter,
};

GameId gameFor(IslandId i, int node, {int salt = 0}) {
  final second = islandGame2[i];
  if (second == null) return islandGame[i]!;
  if (node == Cfg.chapterNodes - 1) return islandGame[i]!; // boss
  final k = node >= 0 ? node : salt;
  return k.isOdd ? second : islandGame[i]!;
}

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
  final int node; // chapter node this quest completes (−1 = no node)
  const Quest(this.island, this.kind, this.title, this.skills, this.items, this.game, this.node);
  String get id => '${island.name}:${kind.name}:$node';
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
  int nodes; // chapter nodes completed in this cycle
  double tierStartTheta;
  IslandState({this.tier = 1, this.nodes = 0, this.tierStartTheta = 0});
  Map<String, dynamic> toJson() => {'tier': tier, 'nodes': nodes, 'start': tierStartTheta};
  factory IslandState.fromJson(Map<String, dynamic> j) => IslandState(tier: j['tier'] as int, nodes: j['nodes'] as int, tierStartTheta: (j['start'] as num).toDouble());
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

  int nodesNeeded(IslandId i) => i == IslandId.observatory ? Cfg.observatoryNodes : Cfg.chapterNodes;
  bool chapterDone(IslandId i) => islands[i]!.nodes >= nodesNeeded(i);
  bool get skillChaptersDone => islandSkill.keys.every(chapterDone);
  bool get observatoryUnlocked => skillChaptersDone;
  bool get observatoryDone => chapterDone(IslandId.observatory);

  /// Island restoration for the map: 70 % chapter progress + 30 % real skill growth this tier.
  double restoration(IslandId i, Map<Skill, SkillModel> m) {
    final st = islands[i]!;
    final chapter = (st.nodes / nodesNeeded(i)).clamp(0.0, 1.0);
    if (i == IslandId.observatory) return chapter * 100;
    final growth = ((m[islandSkill[i]!]!.theta - st.tierStartTheta) / 1.5).clamp(0.0, 1.0);
    return (chapter * 70 + growth * 30).roundToDouble();
  }

  /// Retest prerequisite: all seven islands played through + enough stable evidence per skill.
  RetestStatus retest(Map<Skill, SkillModel> m) {
    final missing = <String>[];
    for (final i in islandSkill.keys) {
      if (!chapterDone(i)) missing.add('${_islandName[i]}: ${islands[i]!.nodes}/${Cfg.chapterNodes} quests');
    }
    if (!observatoryDone) missing.add('Star Observatory: ${islands[IslandId.observatory]!.nodes}/${Cfg.observatoryNodes} star maps');
    for (final s in Skill.values) {
      final mm = m[s]!;
      if (mm.cycleItems < Cfg.retestMinItemsPerSkill) missing.add('${_skillName[s]}: ${mm.cycleItems}/${Cfg.retestMinItemsPerSkill} answers');
      if (!mm.stable) missing.add('${_skillName[s]}: level still settling');
    }
    return RetestStatus(missing.isEmpty, missing);
  }

  void startTiers(Map<Skill, SkillModel> m) {
    for (final e in islandSkill.entries) {
      islands[e.key]!.tierStartTheta = m[e.value]!.theta;
    }
  }

  /// After a retest: next season, every island grows a tier, chapters restart at the new levels.
  void nextSeason(Map<Skill, SkillModel> m) {
    season++;
    for (final st in islands.values) {
      st.tier++;
      st.nodes = 0;
    }
    startTiers(m);
  }

  void completeNode(Quest q) {
    if (q.node < 0) return;
    final st = islands[q.island]!;
    if (st.nodes == q.node) st.nodes++;
  }

  // ---------------- quest generation ----------------
  static double need(SkillModel m) {
    final errs = m.errors.values.fold<double>(0, (a, b) => a + b);
    return .55 * (10 - m.step) / 9 + .25 * (errs / 6).clamp(0, 1) + (m.status == SkillStatus.struggling ? .2 : 0);
  }

  Quest questFor(IslandId i, Map<Skill, SkillModel> m, {QuestKind? force}) {
    final st = islands[i]!;
    final titles = questTitles[i]!;
    if (i == IslandId.observatory) {
      final node = st.nodes.clamp(0, Cfg.observatoryNodes - 1);
      return Quest(i, force ?? QuestKind.observatory, titles[node % titles.length], Skill.values.toList(), Cfg.itemsMixed, GameId.starObservatory, chapterDone(i) ? -1 : node);
    }
    final skill = islandSkill[i]!;
    final mm = m[skill]!;
    final done = chapterDone(i);
    final node = done ? -1 : st.nodes;
    QuestKind kind;
    if (force != null) {
      kind = force;
    } else if (!done && node == Cfg.chapterNodes - 1) {
      kind = QuestKind.boss;
    } else if (mm.calibrationLeft > 0) {
      kind = QuestKind.probe;
    } else {
      kind = switch (mm.status) {
        SkillStatus.struggling => QuestKind.support,
        SkillStatus.ready => QuestKind.challenge,
        _ => QuestKind.standard,
      };
    }
    final items = switch (kind) {
      QuestKind.probe => Cfg.itemsProbe,
      QuestKind.support => Cfg.itemsSupport,
      QuestKind.challenge => Cfg.itemsChallenge,
      QuestKind.boss => Cfg.itemsBoss,
      _ => Cfg.itemsStandard,
    };
    final base = done ? titles[(st.tier * 3) % (titles.length - 1)] : titles[node.clamp(0, titles.length - 1)];
    final title = switch (kind) {
      QuestKind.echo => 'Echo: $base',
      QuestKind.bonus => 'Bonus: $base',
      _ => season > 1 ? '$base · Part $season' : base,
    };
    return Quest(i, kind, title, [skill], items, gameFor(i, node, salt: st.tier + title.length), node);
  }

  /// Always-on quest board (no daily limit): weakest need first, a middle skill, then a stretch for a strong skill.
  List<Quest> board(Map<Skill, SkillModel> m) {
    final out = <Quest>[];
    if (observatoryUnlocked && !observatoryDone) out.add(questFor(IslandId.observatory, m));
    final open = islandSkill.keys.where((i) => !chapterDone(i)).toList()
      ..sort((a, b) => need(m[islandSkill[b]!]!).compareTo(need(m[islandSkill[a]!]!)));
    if (open.isNotEmpty) {
      final picks = <IslandId>[open.first];
      if (open.length >= 3) picks.add(open[open.length ~/ 2]);
      if (open.length >= 2) picks.add(open.last);
      for (final i in picks) {
        if (out.length < Cfg.boardSize && !out.any((q) => q.island == i)) out.add(questFor(i, m));
      }
      for (final i in open) {
        if (out.length >= Cfg.boardSize) break;
        if (!out.any((q) => q.island == i)) out.add(questFor(i, m));
      }
    }
    // after the chapters: bonus quests where evidence is still thin, then echo (spaced review) quests
    if (out.length < Cfg.boardSize) {
      final thin = Skill.values.where((s) => m[s]!.cycleItems < Cfg.retestMinItemsPerSkill || !m[s]!.stable).toList()
        ..sort((a, b) => m[a]!.cycleItems.compareTo(m[b]!.cycleItems));
      for (final s in thin) {
        if (out.length >= Cfg.boardSize) break;
        final i = islandOf(s);
        if (!out.any((q) => q.island == i)) out.add(questFor(i, m, force: QuestKind.bonus));
      }
    }
    if (out.length < Cfg.boardSize) {
      final echo = islandSkill.keys.toList()..sort((a, b) => need(m[islandSkill[b]!]!).compareTo(need(m[islandSkill[a]!]!)));
      for (final i in echo) {
        if (out.length >= Cfg.boardSize) break;
        if (!out.any((q) => q.island == i)) out.add(questFor(i, m, force: QuestKind.echo));
      }
    }
    return out.take(Cfg.boardSize).toList();
  }

  Map<String, dynamic> toJson() => {'season': season, 'islands': islands.map((k, v) => MapEntry(k.name, v.toJson()))};
  factory Campaign.fromJson(Map<String, dynamic> j) => Campaign(
        season: j['season'] as int,
        islands: {
          for (final i in IslandId.values)
            i: (j['islands'] as Map)[i.name] == null ? IslandState() : IslandState.fromJson(Map<String, dynamic>.from((j['islands'] as Map)[i.name] as Map)),
        },
      );

  static const _islandName = {
    IslandId.forest: 'Sound Forest',
    IslandId.valley: 'Symbol Valley',
    IslandId.ocean: 'Word Ocean',
    IslandId.village: 'Word Village',
    IslandId.treasure: 'Treasure Island',
    IslandId.castle: 'Story Castle',
    IslandId.observatory: 'Star Observatory',
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
