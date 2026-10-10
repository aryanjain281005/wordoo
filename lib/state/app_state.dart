import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../story/book_text.dart';
import '../engine/meta.dart';
import '../engine/levels.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../content/content_pack.dart';
import '../core/audio.dart';
import '../core/loc.dart';
import '../story/story_lines.dart';
import '../core/config.dart';
import '../core/tts.dart';
import '../data/lang.dart';
import '../data/skills.dart';
import '../engine/campaign.dart';
import '../engine/personalizer.dart';
import '../engine/skill_model.dart';
import '../models/models.dart';
import '../screening/models.dart' as scr;

enum AppScreen { landing, parent, avatar, intro, assessment, skillMap, home, dashboard, weeklyReport, nextAdventure, loop }

class SessionOutcome {
  final int stars, points;
  final double accuracy;
  final List<AdaptEvent> adapt;
  final List<Collectible> newCollectibles;
  final List<BadgeDef> newBadges;
  final bool chapterComplete;
  final bool retestUnlocked;
  final double restorationBefore, restorationAfter;
  final IslandId? gem; // Story Gem earned (chapter finished)
  final (String, String)? gift; // effort gift from Milo
  final List<(CollectionDef, CollectItem)> newItems; // collection items unlocked by this quest
  final String? teaser; // "Next time…" line of the next quest's guardian
  final int level; // the game level this quest played (1–4)
  final bool levelPassed; // enough right answers to clear the level
  final bool levelNew; // the level was cleared for the first time
  final GameId? unlockedGame; // the island's second game just unlocked
  final int keysWon, keysBest, keysMax; // v3 keys of this level: won now, best ever, maximum
  final int islandKeys, islandKeysMax; // v3 island key meter after this play
  final IslandId? rescued; // v3: this play freed the island's Story Keeper
  final bool trialUnlocked; // v3: all six Keepers free → the Storm Trial opens
  SessionOutcome(this.stars, this.points, this.accuracy, this.adapt, this.newCollectibles, this.newBadges,
      {this.chapterComplete = false, this.retestUnlocked = false, this.restorationBefore = 0, this.restorationAfter = 0, this.gem, this.gift, this.newItems = const [], this.teaser, this.level = 1, this.levelPassed = true, this.levelNew = false, this.unlockedGame, this.keysWon = 0, this.keysBest = 0, this.keysMax = 3, this.islandKeys = 0, this.islandKeysMax = 0, this.rescued, this.trialUnlocked = false});
}

/// One play session, kept only for reports (it never limits play).
class SessionEntry {
  final String date; // yyyy-mm-dd
  double minutes;
  int rounds;
  SessionEntry(this.date, this.minutes, this.rounds);
  Map<String, dynamic> toJson() => {'d': date, 'm': minutes, 'r': rounds};
  factory SessionEntry.fromJson(Map<String, dynamic> j) => SessionEntry(j['d'] as String, (j['m'] as num).toDouble(), j['r'] as int);
}

class AppState extends ChangeNotifier {
  static const _key = 'wordoo_state_v1';

  AppScreen screen = AppScreen.landing;
  bool loaded = false;

  // profile
  String childName = '';
  String explorerName = '';
  int age = 6;
  String grade = 'Class 1';
  String _langCode = 'en';
  String get langCode => _langCode;
  set langCode(String v) {
    _langCode = v;
    Loc.code = v; // the Hindi demo switches (interface text, story lines, recorded voices) all follow this one value
    AudioManager.instance.lang = v;
    StoryLines.instance.lang = v;
  }

  /// Hindi is a demo: only the prologue, the map, Sound Forest and the screening are Hindi. Everything else stays English.
  bool get hindi => _langCode == 'hi';
  bool hindiIsland(IslandId i) => hindi && i == IslandId.forest;
  bool consent = false;
  Avatar avatar = Avatar();

  // screening
  scr.Background background = scr.Background();
  List<scr.ScreeningReport> screenings = [];
  scr.ScreeningReport? get lastScreening => screenings.isEmpty ? null : screenings.last;
  Map<String, int> screeningSeen = {}; // screening item id → times used (fresh items on every retest)

  // learning data
  Map<Skill, SkillState> skills = {for (final s in Skill.values) s: SkillState()}; // screening scores + lifetime error counts
  Map<Skill, SkillModel> models = {for (final s in Skill.values) s: SkillModel()}; // live per-skill difficulty
  Campaign campaign = Campaign();
  Map<String, int> itemSeen = {}; // practice item exposure (spacing, no repetition)
  List<AssessmentRecord> history = []; // one record per screening (cycle 0 = baseline)
  Map<String, int> lastCycleErrors = {}; // "skill|tag" → count for the finished cycle
  Map<Skill, int> cycleStartStep = {};
  List<SessionEntry> sessions = [];
  int cycleSessionStart = 0;

  // story
  Set<String> seenScenes = {};
  double get gumsumLightness => ((campaign.season - 1) * .25).clamp(0.0, 1.0);
  void markSeen(String id) {
    if (seenScenes.add(id)) changed();
  }

  // rewards
  int stars = 0;
  Set<String> libraryBooks = {}; // Story Quest: authored stories understood → re-readable Library + restored castle towers
  int hiveBees = 0;
  int detectiveClues = 0;
  int lanternsLit = 0;
  int seaLog = 0;
  int bandStickers = 0; // Sound Orchestra: sounds heard right
  Set<String> playDays = {}; // yyyy-mm-dd, for the cosy streak (only ever grows)
  Set<String> gems = {}; // Story Gems: 's<season>:<island>'
  List<String> gifts = []; // effort gifts, by name
  int effort = 0; // effort points toward the next gift
  Map<String, int>? _questStart;
  bool _levelMigration = false; // collection counts when the current quest began

  int collectionCount(String id) => switch (id) {
        'band' => bandStickers,
        'lanterns' => lanternsLit,
        'sea' => seaLog,
        'cases' => detectiveClues,
        'hive' => hiveBees,
        'library' => libraryBooks.length,
        _ => 0,
      };
  CozyStreak get streak => CozyStreak.from(playDays); // Word Rocket: words blended right → sea creatures met in the Sea Log // Letter Archer: every right letter lights a lantern that stays in the valley sky // Word Detective: right words found → clues → detective rank // Spelling Hive: one baby bee hatches for every word spelt correctly, forever
  Set<String> badges = {};

  // settings
  int textSize = 0;
  bool extraSpacing = false;
  bool voiceOn = true;
  bool highContrast = false;
  bool sfxOn = true;
  bool musicOn = true;

  LangPack get pack => LangRegistry.byCode(langCode);
  GameContentPack get content => GameContent.of(langCode);
  GameContentPack contentFor(IslandId i) => hindiIsland(i) ? GameContent.forHindiDemo('hi') : content;
  LangPack packFor(IslandId i) => hindiIsland(i) ? pack : LangRegistry.byCode('en');

  bool get hasBaseline => history.isNotEmpty;
  int get cycle => max(0, history.length - 1); // number of completed check-ins
  RetestStatus get retest => campaign.retest(models);
  bool get retestReady => hasBaseline && retest.ready;
  List<Quest> get board => campaign.board(models);
  List<Collectible> get unlocked => Collectibles.all.where((c) => stars >= c.stars).toList();

  Band bandOf(Skill s) => Personalizer.classify(skills[s]!.score);
  SkillModel model(Skill s) => models[s]!;

  double get cycleMinutes => sessions.skip(cycleSessionStart).fold(0.0, (a, s) => a + s.minutes);
  int get cycleRounds => sessions.skip(cycleSessionStart).fold(0, (a, s) => a + s.rounds);
  int get cycleDays => sessions.skip(cycleSessionStart).map((s) => s.date).toSet().length;

  // ---------------- persistence ----------------
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (_levelMigration) {
        final th = {for (final e in campaign.islands.entries) e.key: e.value.tierStartTheta};
        campaign.startTiers(models);
        for (final e in campaign.islands.entries) {
          e.value.tierStartTheta = th[e.key]!;
        }
        _levelMigration = false;
      }
    } catch (e) {
      debugPrint('load failed: $e');
    }
    langCode = GameContent.enabledLanguages.contains(_langCode) ? _langCode : 'en'; // also re-applies the saved language to the voices and texts
    Speaker.instance.enabled = voiceOn;
    AudioManager.instance.sfxOn = sfxOn;
    AudioManager.instance.musicOn = musicOn;
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(_toJson()));
    } catch (e) {
      debugPrint('save failed: $e');
    }
  }

  void changed() {
    _sync();
    notifyListeners();
    _save();
  }

  /// Keeps the simple UI fields (power pips, scaffold flag) in line with the learner model.
  void _sync() {
    for (final s in Skill.values) {
      skills[s]!.level = models[s]!.band;
      skills[s]!.scaffold = models[s]!.needsScaffold;
    }
  }

  Map<String, dynamic> _toJson() => {
        'screen': screen.index,
        'childName': childName,
        'explorerName': explorerName,
        'age': age,
        'grade': grade,
        'lang': langCode,
        'consent': consent,
        'avatar': avatar.toJson(),
        'skills': skills.map((k, v) => MapEntry(k.index.toString(), v.toJson())),
        'models': models.map((k, v) => MapEntry(k.index.toString(), v.toJson())),
        'campaign': campaign.toJson(),
        'itemSeen': itemSeen,
        'screeningSeen': screeningSeen,
        'history': history.map((h) => h.toJson()).toList(),
        'lastCycleErrors': lastCycleErrors,
        'cycleStartStep': cycleStartStep.map((k, v) => MapEntry(k.index.toString(), v)),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'cycleSessionStart': cycleSessionStart,
        'stars': stars,
        'hiveBees': hiveBees,
        'detectiveClues': detectiveClues,
        'lanternsLit': lanternsLit,
        'seaLog': seaLog,
        'bandStickers': bandStickers,
        'playDays': playDays.toList(),
        'gems': gems.toList(),
        'gifts': gifts,
        'effort': effort,
        'libraryBooks': libraryBooks.toList(),
        'badges': badges.toList(),
        'seenScenes': seenScenes.toList(),
        'textSize': textSize,
        'extraSpacing': extraSpacing,
        'voiceOn': voiceOn,
        'highContrast': highContrast,
        'sfxOn': sfxOn,
        'musicOn': musicOn,
        'background': background.toJson(),
        'screenings': screenings.map((r) => r.toJson()).toList(),
      };

  void _fromJson(Map<String, dynamic> j) {
    screen = AppScreen.values[j['screen'] as int];
    if (screen == AppScreen.assessment || screen == AppScreen.weeklyReport) screen = AppScreen.home;
    childName = j['childName'] as String;
    explorerName = j['explorerName'] as String;
    age = j['age'] as int;
    grade = j['grade'] as String;
    langCode = j['lang'] as String;
    consent = j['consent'] as bool;
    avatar = Avatar.fromJson(Map<String, dynamic>.from(j['avatar'] as Map));
    skills = (j['skills'] as Map).map((k, v) => MapEntry(Skill.values[int.parse(k as String)], SkillState.fromJson(Map<String, dynamic>.from(v as Map))));
    for (final s in Skill.values) {
      skills.putIfAbsent(s, () => SkillState());
    }
    if (j['models'] != null) {
      models = (j['models'] as Map).map((k, v) => MapEntry(Skill.values[int.parse(k as String)], SkillModel.fromJson(Map<String, dynamic>.from(v as Map))));
    } else {
      // older saves: derive the learner model from the stored screening scores
      models = {for (final s in Skill.values) s: SkillModel.fromScreening(skills[s]!.score)};
    }
    for (final s in Skill.values) {
      models.putIfAbsent(s, () => SkillModel());
    }
    if (j['campaign'] != null) {
      final cj = Map<String, dynamic>.from(j['campaign'] as Map);
      campaign = Campaign.fromJson(cj);
      // saves from before levels existed: give the screening skips once
      final first = (cj['islands'] as Map?)?.values.firstOrNull;
      if (first is Map && !first.containsKey('cleared')) _levelMigration = true;
    }
    itemSeen = Map<String, int>.from(j['itemSeen'] as Map? ?? const {});
    screeningSeen = Map<String, int>.from(j['screeningSeen'] as Map? ?? const {});
    history = (j['history'] as List).map((e) => AssessmentRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    lastCycleErrors = Map<String, int>.from(j['lastCycleErrors'] as Map? ?? j['lastWeekErrors'] as Map? ?? const {});
    cycleStartStep = (j['cycleStartStep'] as Map? ?? const {}).map((k, v) => MapEntry(Skill.values[int.parse(k as String)], v as int));
    sessions = [for (final e in (j['sessions'] as List? ?? const [])) SessionEntry.fromJson(Map<String, dynamic>.from(e as Map))];
    cycleSessionStart = j['cycleSessionStart'] as int? ?? 0;
    stars = j['stars'] as int;
    hiveBees = j['hiveBees'] as int? ?? 0;
    detectiveClues = j['detectiveClues'] as int? ?? 0;
    lanternsLit = j['lanternsLit'] as int? ?? 0;
    seaLog = j['seaLog'] as int? ?? 0;
    bandStickers = j['bandStickers'] as int? ?? 0;
    playDays = Set<String>.from(j['playDays'] as List? ?? const []);
    playDays.addAll(sessions.map((e) => e.date)); // days played before the streak existed count too
    gems = Set<String>.from(j['gems'] as List? ?? const []);
    gifts = List<String>.from(j['gifts'] as List? ?? const []);
    effort = j['effort'] as int? ?? 0;
    libraryBooks = Set<String>.from(j['libraryBooks'] as List? ?? const []);
    badges = Set<String>.from(j['badges'] as List);
    seenScenes = Set<String>.from(j['seenScenes'] as List? ?? const []);
    textSize = j['textSize'] as int;
    extraSpacing = j['extraSpacing'] as bool;
    voiceOn = j['voiceOn'] as bool;
    highContrast = j['highContrast'] as bool? ?? false;
    sfxOn = j['sfxOn'] as bool? ?? true;
    musicOn = j['musicOn'] as bool? ?? true;
    if (j['background'] != null) background = scr.Background.fromJson(Map<String, dynamic>.from(j['background'] as Map));
    screenings = [for (final e in (j['screenings'] as List? ?? const [])) scr.ScreeningReport.fromJson(Map<String, dynamic>.from(e as Map))];
    if (screen == AppScreen.home && history.isEmpty) screen = AppScreen.landing;
    _sync();
  }

  // ---------------- navigation & setup ----------------
  void go(AppScreen s) {
    screen = s;
    changed();
  }

  Future<void> resetAll() async {
    final keepText = textSize, keepSpacing = extraSpacing, keepVoice = voiceOn;
    childName = explorerName = '';
    age = 6;
    grade = 'Class 1';
    langCode = 'en';
    consent = false;
    avatar = Avatar();
    background = scr.Background();
    _resetLearning();
    textSize = keepText;
    extraSpacing = keepSpacing;
    voiceOn = keepVoice;
    screen = AppScreen.landing;
    changed();
  }

  void _resetLearning() {
    skills = {for (final s in Skill.values) s: SkillState()};
    models = {for (final s in Skill.values) s: SkillModel()};
    campaign = Campaign();
    itemSeen = {};
    screeningSeen = {};
    history = [];
    screenings = [];
    lastCycleErrors = {};
    cycleStartStep = {};
    sessions = [];
    cycleSessionStart = 0;
    stars = 0;
    hiveBees = 0;
    detectiveClues = 0;
    lanternsLit = 0;
    seaLog = 0;
    bandStickers = 0;
    playDays = {};
    gems = {};
    gifts = [];
    effort = 0;
    libraryBooks = {};
    badges = {};
    seenScenes = {};
  }

  void saveParentSetup({required String name, required int age, required String grade, required String lang, required bool consent}) {
    childName = name.trim();
    explorerName = explorerName.isEmpty ? childName : explorerName;
    this.age = age;
    this.grade = grade;
    langCode = GameContent.enabledLanguages.contains(lang) ? lang : 'en';
    this.consent = consent;
    changed();
  }

  void saveAvatar(Avatar a, String name) {
    avatar = a;
    if (name.trim().isNotEmpty) explorerName = name.trim();
    changed();
  }

  void setLang(String code) {
    if (!GameContent.enabledLanguages.contains(code)) return;
    langCode = code;
    changed();
  }

  void setSettings({int? textSize, bool? extraSpacing, bool? voiceOn, bool? highContrast, bool? sfxOn, bool? musicOn}) {
    if (sfxOn != null) AudioManager.instance.sfxOn = this.sfxOn = sfxOn;
    if (musicOn != null) {
      AudioManager.instance.setMusicOn(this.musicOn = musicOn);
    }
    if (textSize != null) this.textSize = textSize;
    if (extraSpacing != null) this.extraSpacing = extraSpacing;
    if (voiceOn != null) {
      this.voiceOn = voiceOn;
      Speaker.instance.enabled = voiceOn;
    }
    if (highContrast != null) this.highContrast = highContrast;
    changed();
  }

  void saveBackground(scr.Background b) {
    background = b;
    changed();
  }

  // ---------------- demo profiles (instant uneven profiles for presenting) ----------------
  static const _demoScores = <int, Map<Skill, double>>{
    0: {Skill.phonological: 9, Skill.gpc: 78, Skill.decoding: 30, Skill.wordRecognition: 82, Skill.spelling: 7, Skill.comprehension: 35},
    1: {Skill.phonological: 80, Skill.gpc: 34, Skill.decoding: 8, Skill.wordRecognition: 30, Skill.spelling: 75, Skill.comprehension: 72},
  };

  void loadDemoProfile(int which) {
    _resetLearning();
    childName = which == 0 ? 'Aarav' : 'Meera';
    explorerName = childName;
    age = which == 0 ? 6 : 7;
    grade = which == 0 ? 'Class 1' : 'Class 2';
    langCode = 'en';
    consent = true;
    avatar = Avatar(hair: which == 0 ? 1 : 2, outfit: which == 0 ? 0 : 3, companion: 0);
    _startFromScores(_demoScores[which]!);
    if (which == 0) {
      skills[Skill.phonological]!.errors = {'Wrong first sound': 3, 'Failed blend': 2};
      skills[Skill.spelling]!.errors = {'Wrong vowel': 3, 'Missing unit': 2};
      models[Skill.spelling]!.errors['Wrong vowel'] = 2.5;
      models[Skill.phonological]!.errors['Wrong first sound'] = 2.2;
    }
    badges.add(Badges.first.id);
    screen = AppScreen.skillMap;
    changed();
  }

  // ---------------- screening → personalised start ----------------
  static const _constructSkill = {
    scr.Construct.phonological: Skill.phonological,
    scr.Construct.gpc: Skill.gpc,
    scr.Construct.decoding: Skill.decoding,
    scr.Construct.wordRecognition: Skill.wordRecognition,
    scr.Construct.spelling: Skill.spelling,
    scr.Construct.comprehension: Skill.comprehension,
  };

  static const _subtestConstruct = {
    'rhyme': scr.Construct.phonological,
    'firstSound': scr.Construct.phonological,
    'phonemeManip': scr.Construct.phonological,
    'letterSound': scr.Construct.gpc,
    'nonwordReading': scr.Construct.decoding,
    'wordReading': scr.Construct.wordRecognition,
    'spelling': scr.Construct.spelling,
    'readingComp': scr.Construct.comprehension,
    'oralReading': scr.Construct.comprehension,
  };

  /// Maps screening tags onto the tags the games use as practice targets.
  static const _tagMap = {
    'Wrong first sound': 'Wrong first sound',
    'Rhyme confusion': 'Rhyme confusion',
    'Sound deletion / replacement error': 'Sound deletion / replacement error',
    'Similar letter / matra confusion': 'Similar-letter confusion',
    'Incorrect blend': 'Incorrect blend',
    'Misread word': 'Visual confusion',
    'Wrong vowel': 'Wrong vowel',
    'Wrong letter': 'Wrong letter',
    'Missing unit': 'Missing unit',
  };

  void _startFromScores(Map<Skill, double> scores, {Set<Skill> unmeasured = const {}}) {
    for (final s in Skill.values) {
      final st = skills[s]!;
      st.baseline = scores[s]!;
      st.score = scores[s]!;
      models[s] = SkillModel.fromScreening(scores[s]!, measured: !unmeasured.contains(s));
      cycleStartStep[s] = models[s]!.step;
    }
    history = [AssessmentRecord(0, Map.of(scores))];
    campaign = Campaign();
    campaign.startTiers(models);
    cycleSessionStart = sessions.length;
  }

  ({Map<Skill, double> scores, Set<Skill> unmeasured}) _scoresFrom(scr.ScreeningReport report) {
    final measured = [for (final c in report.constructs) if (c.band != scr.ScreenBand.notMeasured) c.percentile];
    final fallback = measured.isEmpty ? 30.0 : measured.reduce((a, b) => a + b) / measured.length;
    final un = <Skill>{};
    final scores = <Skill, double>{};
    for (final e in _constructSkill.entries) {
      final r = report.of(e.key);
      if (r == null || r.band == scr.ScreenBand.notMeasured) {
        un.add(e.value);
        scores[e.value] = fallback.roundToDouble();
      } else {
        scores[e.value] = r.percentile;
      }
    }
    return (scores: scores, unmeasured: un);
  }

  /// Screening finished. First time → every skill starts at its own step from the screening.
  /// Later (check-in) → blend the fresh screening with what gameplay already knows.
  void completeScreening(scr.ScreeningReport report, Map<String, List<scr.ItemResponse>> responses) {
    for (final list in responses.values) {
      for (final r in list) {
        screeningSeen[r.itemId.split('.').first] = (screeningSeen[r.itemId.split('.').first] ?? 0) + 1;
      }
    }
    final (:scores, :unmeasured) = _scoresFrom(report);
    final first = !hasBaseline;
    screenings = [...screenings, report];
    if (first) {
      _startFromScores(scores, unmeasured: unmeasured);
      badges.add(Badges.first.id);
    } else {
      _applyCheckIn(scores, unmeasured);
    }
    for (final list in responses.values) {
      for (final r in list) {
        if (r.tag == null || r.tag == 'discontinued' || !r.measured) continue;
        final c = _subtestConstruct[r.subtest];
        final skill = c == null ? null : _constructSkill[c];
        if (skill == null) continue;
        skills[skill]!.errors[r.tag!] = (skills[skill]!.errors[r.tag!] ?? 0) + 1;
        final mapped = _tagMap[r.tag];
        if (mapped != null) models[skill]!.errors[mapped] = (models[skill]!.errors[mapped] ?? 0) + 1;
      }
    }
    stars += 5;
    screen = first ? AppScreen.skillMap : AppScreen.weeklyReport;
    changed();
  }

  void _applyCheckIn(Map<Skill, double> scores, Set<Skill> unmeasured) {
    lastCycleErrors = {};
    for (final s in Skill.values) {
      models[s]!.errors.forEach((tag, n) => lastCycleErrors['${s.index}|$tag'] = n.round());
    }
    for (final s in Skill.values) {
      final st = skills[s]!;
      st.score = scores[s]!;
      if (!unmeasured.contains(s)) {
        final screenTheta = SkillModel.fromScreening(scores[s]!).theta;
        final m = models[s]!;
        m.theta = .6 * screenTheta + .4 * m.theta; // fresh, controlled measure weighs more
        m.calibrationLeft = 1;
      }
    }
    history = [...history, AssessmentRecord(history.length, Map.of(scores))];
    badges.add(Badges.week.id);
  }

  /// After the check-in report and plan: a new season starts, islands grow a tier.
  void startNextCycle() {
    campaign.nextSeason(models);
    for (final s in Skill.values) {
      models[s]!.cycleItems = 0;
      cycleStartStep[s] = models[s]!.step;
    }
    cycleSessionStart = sessions.length;
    screen = AppScreen.home;
    changed();
  }

  // ---------------- gameplay ----------------
  /// Every single answer updates that skill's model immediately (live adaptation).
  void recordItem(Item item, ItemResult r) {
    final m = models[item.skill]!;
    final tag = r.tags.isEmpty ? null : r.tags.first;
    _questStart ??= {for (final c in collections) c.id: collectionCount(c.id)};
    m.update(r.correct ? 1 : 0, item.diff, ms: r.ms, tag: tag);
    if (item.skill == Skill.phonological && r.correct) bandStickers++;
    if (item.skill == Skill.spelling && r.correct) hiveBees++;
    if (item.skill == Skill.wordRecognition && r.correct) detectiveClues++;
    if (item.skill == Skill.gpc && r.correct) lanternsLit++;
    if (item.skill == Skill.decoding && r.correct) seaLog++;
    if (item.skill == Skill.comprehension && r.correct) {
      final id = storyIdOfItem(item.id);
      if (isAuthoredStory(id)) libraryBooks.add(id);
    }
    for (final t in r.tags) {
      skills[item.skill]!.errors[t] = (skills[item.skill]!.errors[t] ?? 0) + 1;
    }
    _sync();
  }

  /// Story v3: a finished Storm Trial. Every answer still teaches the learner model. Returns true if passed.
  bool completeTrial(List<Item> items, List<ItemResult> results, double seconds) {
    for (var k = 0; k < results.length && k < items.length; k++) {
      recordItem(items[k], results[k]);
    }
    final passed = campaign.recordTrial(results.where((r) => r.correct).length);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (sessions.isEmpty || sessions.last.date != today) sessions.add(SessionEntry(today, 0, 0));
    sessions.last.minutes += seconds / 60;
    sessions.last.rounds++;
    playDays.add(today);
    if (passed) badges.add('trial-s${campaign.season}');
    _questStart = null;
    changed();
    return passed;
  }

    SessionOutcome completeQuest(Quest q, List<ItemResult> results, double seconds, Map<Skill, int> startSteps) {
    final before = campaign.restoration(q.island, models);
    final wasReady = retestReady;
    for (final s in q.skills.toSet()) {
      models[s]!.endRound();
      skills[s]!.sessions++;
    }
    final adapt = <AdaptEvent>[
      for (final s in q.skills.toSet())
        if (models[s]!.step != (startSteps[s] ?? models[s]!.step)) AdaptEvent(s, startSteps[s] ?? models[s]!.step, models[s]!.step),
    ];
    final acc = results.isEmpty ? 1.0 : results.where((r) => r.correct).length / results.length;
    final hadChapter = campaign.chapterDone(q.island);
    final second = islandGame2[q.island];
    final secondWasLocked = second != null && !campaign.gameUnlocked(q.island, second);
    final passed = acc >= levelPassAccuracy;
    // Story v3: keys for this play (best per level counts); a Keeper is freed when the island has every key
    final wasRescued = q.island != IslandId.observatory && campaign.chapterDone(q.island);
    final keysBefore = campaign.islands[q.island]!.keysOf(q.game, q.level);
    final keysWon = q.island == IslandId.observatory ? 0 : campaign.recordKeys(q, results.where((r) => r.correct).length, results.length);
    final newlyCleared = passed && campaign.clearLevel(q);
    IslandId? rescuedNow;
    if (!wasRescued && q.island != IslandId.observatory && campaign.chapterDone(q.island)) {
      campaign.islands[q.island]!.rescued = true;
      rescuedNow = q.island;
    }
    final chapterComplete = !hadChapter && campaign.chapterDone(q.island);
    final unlockedGame = secondWasLocked && campaign.gameUnlocked(q.island, second) ? second : null;

    var earned = acc >= .8 ? 3 : (acc >= .5 ? 2 : 1);
    if (q.kind == QuestKind.boss || q.kind == QuestKind.challenge) earned += 1;
    final prevUnlocked = unlocked.map((c) => c.id).toSet();
    final prevBadges = Set<String>.of(badges);
    stars += earned;
    if (chapterComplete) stars += 5;
    for (final s in q.skills) {
      badges.add(Badges.forSkill(s).id);
    }
    if (adapt.any((e) => e.up)) badges.add(Badges.levelUp.id);
    if (chapterComplete) badges.add(Badges.day.id);

    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (sessions.isEmpty || sessions.last.date != today) sessions.add(SessionEntry(today, 0, 0));
    sessions.last.minutes += seconds / 60;
    sessions.last.rounds++;

    final newC = unlocked.where((c) => !prevUnlocked.contains(c.id)).toList();
    final defs = <String, BadgeDef>{
      Badges.first.id: Badges.first,
      Badges.day.id: Badges.day,
      Badges.week.id: Badges.week,
      Badges.levelUp.id: Badges.levelUp,
      for (final s in Skill.values) Badges.forSkill(s).id: Badges.forSkill(s),
    };
    final newB = [for (final id in badges.difference(prevBadges)) if (defs[id] != null) defs[id]!];
    final after = campaign.restoration(q.island, models);

    // Phase 3 rewards: Story Gem, cosy streak day, effort gift, new collection items, "next time" teaser
    IslandId? gem;
    if (chapterComplete && gems.add(gemId(campaign.season, q.island))) gem = q.island;
    playDays.add(today);
    (String, String)? gift;
    effort += results.where((r) => !r.correct).length;
    if (effort >= giftEvery) {
      effort -= giftEvery;
      gift = effortGifts[gifts.length % effortGifts.length];
      gifts.add(gift.$2);
    }
    final start = _questStart ?? const <String, int>{};
    final newItems = <(CollectionDef, CollectItem)>[
      for (final c in collections)
        for (final i in c.items)
          if ((start[c.id] ?? collectionCount(c.id)) < i.at && collectionCount(c.id) >= i.at) (c, i),
    ];
    _questStart = null;
    final next = board;
    final teaser = next.isEmpty ? null : teaserLineId(next.first.island);
    changed();
    return SessionOutcome(earned, earned * Cfg.pointsPerStar, acc, adapt, newC, newB,
        chapterComplete: chapterComplete, retestUnlocked: !wasReady && retestReady, restorationBefore: before, restorationAfter: after, gem: gem, gift: gift, newItems: newItems, teaser: teaser,
        level: q.level, levelPassed: passed, levelNew: newlyCleared, unlockedGame: unlockedGame,
        keysWon: keysWon, keysBest: max(keysBefore, keysWon), keysMax: maxKeysFor(q.level),
        islandKeys: campaign.islandKeys(q.island), islandKeysMax: q.island == IslandId.observatory ? 0 : campaign.maxIslandKeys(q.island), rescued: rescuedNow,
        trialUnlocked: rescuedNow != null && campaign.observatoryUnlocked);
  }

  void equipHat(int idx) {
    avatar.hat = idx;
    changed();
  }
}
