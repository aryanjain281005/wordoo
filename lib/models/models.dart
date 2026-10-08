enum Skill { phonological, gpc, decoding, wordRecognition, spelling, comprehension }

enum Band { needsSupport, developing, strong }

enum ItemKind { choice, build }

enum GameId {
  soundOrchestra,
  soundNinja,
  letterArcher,
  soundPortal,
  wordRocket,
  wordBuilder,
  wordDetective,
  wordFlash,
  spellingHive,
  magicWriter,
  storyQuest,
  starObservatory, // mixed review of all six skills (7th island)
}

/// One answer option in a choice item.
class Opt {
  final String label;
  final String? emoji;
  final String? say;
  final String? tag; // error tag when this wrong option is picked
  const Opt(this.label, {this.emoji, this.say, this.tag});
}

/// A single playable / assessable question, produced by the ItemFactory.
class Item {
  final String id;
  final Skill skill;
  final int level;
  final ItemKind kind;
  final String prompt; // short visible prompt
  final String say; // spoken instruction
  final String? stimulus; // big visible stimulus (word, units)
  final String? emoji; // illustration
  final String? passage; // story text
  final List<Opt> options;
  final int correct;
  final List<String> answer; // build items
  final List<String> tiles; // build items (shuffled)
  final String hint;
  final String? replaySay; // what the speaker button replays
  final bool timed;
  final double diff; // difficulty on the 1–10 step scale (for the learner model)
  final bool audioOptions; // options are heard, not read (tap to listen, tap again to choose)

  const Item({
    required this.id,
    required this.skill,
    required this.level,
    required this.kind,
    required this.prompt,
    required this.say,
    this.stimulus,
    this.emoji,
    this.passage,
    this.options = const [],
    this.correct = 0,
    this.answer = const [],
    this.tiles = const [],
    this.hint = '',
    this.replaySay,
    this.timed = false,
    double? diff,
    this.audioOptions = false,
  }) : diff = diff ?? (level + .0);
}

class ItemResult {
  final String itemId;
  final Skill skill;
  final int level;
  final bool correct; // first attempt
  final int ms;
  final List<String> tags;
  const ItemResult({
    required this.itemId,
    required this.skill,
    required this.level,
    required this.correct,
    required this.ms,
    this.tags = const [],
  });
}

class SkillState {
  double baseline; // score of first assessment (0..100)
  double score; // latest assessment score
  int level; // 1..4 current difficulty
  List<int> recent; // 1 / 0 first-attempt outcomes
  Map<String, int> errors;
  int sessions;
  bool scaffold;

  SkillState({
    this.baseline = 0,
    this.score = 0,
    this.level = 1,
    List<int>? recent,
    Map<String, int>? errors,
    this.sessions = 0,
    this.scaffold = false,
  })  : recent = recent ?? [],
        errors = errors ?? {};

  Map<String, dynamic> toJson() => {
        'baseline': baseline,
        'score': score,
        'level': level,
        'recent': recent,
        'errors': errors,
        'sessions': sessions,
        'scaffold': scaffold,
      };

  factory SkillState.fromJson(Map<String, dynamic> j) => SkillState(
        baseline: (j['baseline'] as num).toDouble(),
        score: (j['score'] as num).toDouble(),
        level: j['level'] as int,
        recent: List<int>.from(j['recent'] as List),
        errors: Map<String, int>.from(j['errors'] as Map),
        sessions: j['sessions'] as int,
        scaffold: j['scaffold'] as bool,
      );
}

class Mission {
  final Skill skill;
  final GameId game;
  bool done;
  Mission(this.skill, this.game, {this.done = false});

  Map<String, dynamic> toJson() => {'skill': skill.index, 'game': game.index, 'done': done};
  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
        Skill.values[j['skill'] as int],
        GameId.values[j['game'] as int],
        done: j['done'] as bool,
      );
}

/// Snapshot of one assessment (baseline or weekly).
class AssessmentRecord {
  final int week; // 0 = baseline
  final Map<Skill, double> scores;
  final bool simulated;
  AssessmentRecord(this.week, this.scores, {this.simulated = false});

  Map<String, dynamic> toJson() => {
        'week': week,
        'scores': scores.map((k, v) => MapEntry(k.index.toString(), v)),
        'simulated': simulated,
      };
  factory AssessmentRecord.fromJson(Map<String, dynamic> j) => AssessmentRecord(
        j['week'] as int,
        (j['scores'] as Map).map((k, v) => MapEntry(Skill.values[int.parse(k as String)], (v as num).toDouble())),
        simulated: j['simulated'] as bool? ?? false,
      );
}

class AdaptEvent {
  final Skill skill;
  final int from;
  final int to;
  const AdaptEvent(this.skill, this.from, this.to);
  bool get up => to > from;
  bool get down => to < from;
}

class Avatar {
  int hair;
  int outfit;
  int companion; // 0 fox, 1 panda, 2 dragon
  int hat; // -1 none, else collectible index
  Avatar({this.hair = 0, this.outfit = 0, this.companion = 0, this.hat = -1});
  Map<String, dynamic> toJson() => {'hair': hair, 'outfit': outfit, 'companion': companion, 'hat': hat};
  factory Avatar.fromJson(Map<String, dynamic> j) => Avatar(
        hair: j['hair'] as int,
        outfit: j['outfit'] as int,
        companion: j['companion'] as int,
        hat: j['hat'] as int? ?? -1,
      );
}
