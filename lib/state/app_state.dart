import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';
import '../core/tts.dart';
import '../data/lang.dart';
import '../data/skills.dart';
import '../engine/personalizer.dart';
import '../models/models.dart';
import '../screening/models.dart' as scr;

enum AppScreen { landing, parent, avatar, intro, assessment, skillMap, home, dashboard, weeklyReport, nextAdventure, loop }

class SessionOutcome {
  final int stars, points;
  final double accuracy;
  final List<AdaptEvent> adapt;
  final List<Collectible> newCollectibles;
  final List<BadgeDef> newBadges;
  final bool dayComplete;
  SessionOutcome(this.stars, this.points, this.accuracy, this.adapt, this.newCollectibles, this.newBadges, this.dayComplete);
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
  String langCode = 'en';
  bool consent = false;
  Avatar avatar = Avatar();

  // screening
  scr.Background background = scr.Background();
  List<scr.ScreeningReport> screenings = [];
  scr.ScreeningReport? get lastScreening => screenings.isEmpty ? null : screenings.last;

  // learning data
  Map<Skill, SkillState> skills = {for (final s in Skill.values) s: SkillState()};
  List<AssessmentRecord> history = [];
  Map<String, int> lastWeekErrors = {}; // "skill|tag" -> count (previous week, for report)
  List<Mission> missions = [];
  int day = 1;
  Set<int> practiceDays = {};
  double minutes = 0;
  int sessionsThisWeek = 0;

  // rewards
  int stars = 0;
  Set<String> badges = {};

  // settings
  int textSize = 0; // 0 normal, 1 large, 2 extra large
  bool extraSpacing = false;
  bool voiceOn = true;
  bool highContrast = false;

  LangPack get pack => LangRegistry.byCode(langCode);

  bool get hasBaseline => history.isNotEmpty;
  bool get weekReady => day > Cfg.daysPerWeek;
  int get currentWeek => history.length; // week being practised (1 after baseline)
  bool get dayDone => missions.isNotEmpty && missions.every((m) => m.done);
  Pool get assessForm => history.length.isEven ? Pool.a : Pool.b;
  List<Collectible> get unlocked => Collectibles.all.where((c) => stars >= c.stars).toList();

  Band bandOf(Skill s) => Personalizer.classify(skills[s]!.score);

  // ---------------- persistence ----------------
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('load failed: $e');
    }
    Speaker.instance.enabled = voiceOn;
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
    notifyListeners();
    _save();
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
        'history': history.map((h) => h.toJson()).toList(),
        'lastWeekErrors': lastWeekErrors,
        'missions': missions.map((m) => m.toJson()).toList(),
        'day': day,
        'practiceDays': practiceDays.toList(),
        'minutes': minutes,
        'sessionsThisWeek': sessionsThisWeek,
        'stars': stars,
        'badges': badges.toList(),
        'textSize': textSize,
        'extraSpacing': extraSpacing,
        'voiceOn': voiceOn,
        'highContrast': highContrast,
        'background': background.toJson(),
        'screenings': screenings.map((r) => r.toJson()).toList(),
      };

  void _fromJson(Map<String, dynamic> j) {
    screen = AppScreen.values[j['screen'] as int];
    // never resume in the middle of a flow that has no stored progress
    if (screen == AppScreen.assessment || screen == AppScreen.weeklyReport) screen = AppScreen.home;
    childName = j['childName'] as String;
    explorerName = j['explorerName'] as String;
    age = j['age'] as int;
    grade = j['grade'] as String;
    langCode = j['lang'] as String;
    consent = j['consent'] as bool;
    avatar = Avatar.fromJson(Map<String, dynamic>.from(j['avatar'] as Map));
    skills = (j['skills'] as Map).map((k, v) =>
        MapEntry(Skill.values[int.parse(k as String)], SkillState.fromJson(Map<String, dynamic>.from(v as Map))));
    for (final s in Skill.values) {
      skills.putIfAbsent(s, () => SkillState());
    }
    history = (j['history'] as List).map((e) => AssessmentRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    lastWeekErrors = Map<String, int>.from(j['lastWeekErrors'] as Map);
    missions = (j['missions'] as List).map((e) => Mission.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    day = j['day'] as int;
    practiceDays = Set<int>.from(j['practiceDays'] as List);
    minutes = (j['minutes'] as num).toDouble();
    sessionsThisWeek = j['sessionsThisWeek'] as int;
    stars = j['stars'] as int;
    badges = Set<String>.from(j['badges'] as List);
    textSize = j['textSize'] as int;
    extraSpacing = j['extraSpacing'] as bool;
    voiceOn = j['voiceOn'] as bool;
    highContrast = j['highContrast'] as bool? ?? false;
    if (j['background'] != null) background = scr.Background.fromJson(Map<String, dynamic>.from(j['background'] as Map));
    screenings = [for (final e in (j['screenings'] as List? ?? const [])) scr.ScreeningReport.fromJson(Map<String, dynamic>.from(e as Map))];
    if (screen == AppScreen.home && history.isEmpty) screen = AppScreen.landing;
  }

  // ---------------- navigation ----------------
  void go(AppScreen s) {
    screen = s;
    changed();
  }

  Future<void> resetAll() async {
    final keepText = textSize, keepSpacing = extraSpacing, keepVoice = voiceOn;
    childName = explorerName = '';
    age = 6;
    grade = 'Class 1';
    consent = false;
    avatar = Avatar();
    skills = {for (final s in Skill.values) s: SkillState()};
    history = [];
    lastWeekErrors = {};
    missions = [];
    day = 1;
    practiceDays = {};
    minutes = 0;
    sessionsThisWeek = 0;
    stars = 0;
    badges = {};
    screenings = [];
    background = scr.Background();
    textSize = keepText;
    extraSpacing = keepSpacing;
    voiceOn = keepVoice;
    screen = AppScreen.landing;
    changed();
  }

  // ---------------- setup ----------------
  void saveParentSetup({required String name, required int age, required String grade, required String lang, required bool consent}) {
    childName = name.trim();
    explorerName = explorerName.isEmpty ? childName : explorerName;
    this.age = age;
    this.grade = grade;
    langCode = lang;
    this.consent = consent;
    changed();
  }

  void saveAvatar(Avatar a, String name) {
    avatar = a;
    if (name.trim().isNotEmpty) explorerName = name.trim();
    changed();
  }

  void setLang(String code) {
    langCode = code;
    changed();
  }

  void setSettings({int? textSize, bool? extraSpacing, bool? voiceOn, bool? highContrast}) {
    if (textSize != null) this.textSize = textSize;
    if (extraSpacing != null) this.extraSpacing = extraSpacing;
    if (voiceOn != null) {
      this.voiceOn = voiceOn;
      Speaker.instance.enabled = voiceOn;
    }
    if (highContrast != null) this.highContrast = highContrast;
    changed();
  }

  // ---------------- demo profiles ----------------
  static const _demoScores = <int, Map<Skill, double>>{
    0: {
      Skill.phonological: 9,
      Skill.gpc: 78,
      Skill.decoding: 30,
      Skill.wordRecognition: 82,
      Skill.spelling: 7,
      Skill.comprehension: 35,
    },
    1: {
      Skill.phonological: 80,
      Skill.gpc: 34,
      Skill.decoding: 8,
      Skill.wordRecognition: 30,
      Skill.spelling: 75,
      Skill.comprehension: 72,
    },
  };

  /// Loads Profile A (Aarav) or Profile B (Meera) so the personalization can be demonstrated instantly.
  void loadDemoProfile(int which) {
    resetAllSync();
    childName = which == 0 ? 'Aarav' : 'Meera';
    explorerName = childName;
    age = which == 0 ? 6 : 7;
    grade = which == 0 ? 'Class 1' : 'Class 2';
    consent = true;
    avatar = Avatar(hair: which == 0 ? 1 : 2, outfit: which == 0 ? 0 : 3, companion: 0);
    _applyBaseline(_demoScores[which]!, seedErrors: true);
    screen = AppScreen.skillMap;
    changed();
  }

  void resetAllSync() {
    screenings = [];
    skills = {for (final s in Skill.values) s: SkillState()};
    history = [];
    lastWeekErrors = {};
    missions = [];
    day = 1;
    practiceDays = {};
    minutes = 0;
    sessionsThisWeek = 0;
    stars = 0;
    badges = {};
  }

  // ---------------- assessment ----------------
  void _applyBaseline(Map<Skill, double> scores, {bool seedErrors = false}) {
    for (final s in Skill.values) {
      final st = skills[s]!;
      st.baseline = scores[s]!;
      st.score = scores[s]!;
      st.level = Personalizer.startLevel(Personalizer.classify(scores[s]!));
      st.recent = [];
      st.sessions = 0;
      st.scaffold = false;
      st.errors = {};
    }
    if (seedErrors) {
      skills[Skill.phonological]!.errors = {'Wrong first sound': 3, 'Failed blend': 2};
      skills[Skill.spelling]!.errors = {'Wrong matra / vowel': 3, 'Missing unit': 2};
      skills[Skill.decoding]!.errors = {'Incorrect blend': 3};
    }
    history = [AssessmentRecord(0, Map.of(scores))];
    badges.add(Badges.first.id);
    day = 1;
    practiceDays = {};
    minutes = 0;
    sessionsThisWeek = 0;
    missions = Personalizer.dailyPlan(skills, day);
  }

  Map<Skill, double> scoresFrom(List<ItemResult> results) => {
        for (final s in Skill.values) s: Personalizer.scoreAssessment(results.where((r) => r.skill == s).toList()),
      };

  void completeBaseline(List<ItemResult> results) {
    final scores = scoresFrom(results);
    _applyBaseline(scores);
    _addErrors(results);
    stars += 5;
    screen = AppScreen.skillMap;
    changed();
  }

  void _addErrors(List<ItemResult> results) {
    for (final r in results) {
      for (final t in r.tags) {
        final m = skills[r.skill]!.errors;
        m[t] = (m[t] ?? 0) + 1;
      }
    }
  }

  static const _constructSkill = {
    scr.Construct.phonological: Skill.phonological,
    scr.Construct.gpc: Skill.gpc,
    scr.Construct.decoding: Skill.decoding,
    scr.Construct.wordRecognition: Skill.wordRecognition,
    scr.Construct.spelling: Skill.spelling,
    scr.Construct.comprehension: Skill.comprehension,
  };

  void saveBackground(scr.Background b) {
    background = b;
    changed();
  }

  /// Screening finished: the report's construct percentiles become the six skill scores,
  /// which set every game's starting level (strong → higher, weak → foundational).
  void completeScreening(scr.ScreeningReport report, Map<String, List<scr.ItemResponse>> responses) {
    final measured = [for (final c in report.constructs) if (c.band != scr.ScreenBand.notMeasured) c.percentile];
    final fallback = measured.isEmpty ? 30.0 : measured.reduce((a, b) => a + b) / measured.length;
    final scores = <Skill, double>{
      for (final e in _constructSkill.entries)
        e.value: (report.of(e.key)?.band ?? scr.ScreenBand.notMeasured) == scr.ScreenBand.notMeasured ? fallback.roundToDouble() : report.of(e.key)!.percentile,
    };
    final first = !hasBaseline;
    screenings = [...screenings, report];
    if (first) {
      _applyBaseline(scores);
    } else {
      _applyReassessment(scores);
    }
    // carry the screening's error patterns into the engine
    for (final list in responses.values) {
      for (final r in list) {
        if (r.tag == null || r.tag == 'discontinued' || !r.measured) continue;
        final c = _subtestConstruct[r.subtest];
        final skill = c == null ? null : _constructSkill[c];
        if (skill == null) continue;
        final m = skills[skill]!.errors;
        m[r.tag!] = (m[r.tag!] ?? 0) + 1;
      }
    }
    stars += 5;
    screen = first ? AppScreen.skillMap : AppScreen.weeklyReport;
    changed();
  }

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

  /// Fresh-item reassessment finished: update profile and move to the report.
  void completeReassessment(List<ItemResult> results, {bool simulated = false, Map<Skill, double>? override}) {
    final scores = override ?? scoresFrom(results);
    _applyReassessment(scores, simulated: simulated);
    screen = AppScreen.weeklyReport;
    changed();
  }

  void _applyReassessment(Map<Skill, double> scores, {bool simulated = false}) {
    // snapshot this week's errors for the report
    lastWeekErrors = {};
    for (final s in Skill.values) {
      skills[s]!.errors.forEach((tag, n) => lastWeekErrors['${s.index}|$tag'] = n);
    }
    for (final s in Skill.values) {
      final st = skills[s]!;
      final oldBand = Personalizer.classify(st.score);
      st.score = scores[s]!;
      final nb = Personalizer.classify(st.score);
      final start = Personalizer.startLevel(nb);
      st.level = nb.index < oldBand.index ? start : max(start, st.level);
      st.recent = [];
      st.scaffold = false;
    }
    history = [...history, AssessmentRecord(history.length, Map.of(scores), simulated: simulated)];
    badges.add(Badges.week.id);
    stars += 5;
  }

  /// Demo shortcut: derive realistic week-1 results from the practice that really happened.
  void simulateWeekOne() {
    if (!weekReady) _fillDemoPractice();
    final rng = Random(childName.hashCode + history.length);
    final out = <Skill, double>{};
    for (final s in Skill.values) {
      final st = skills[s]!;
      final practiced = st.sessions;
      final acc = st.recent.isEmpty ? 0.7 : Personalizer.accuracy(st.recent);
      var gain = 4.0 + practiced * 3.5 + acc * 6 + rng.nextInt(4);
      if (st.score >= 80) gain = gain * 0.35;
      if (practiced == 0) gain = min(gain, 4);
      out[s] = (st.score + gain).clamp(0, 98).roundToDouble();
    }
    // a skill with heavy errors keeps lagging a bit — realistic, not all green
    final worst = Personalizer.ranked(skills).first;
    out[worst] = min(out[worst]!, skills[worst]!.score + 9);
    _applyReassessment(out, simulated: true);
    screen = AppScreen.weeklyReport;
    changed();
  }

  void startNextWeek() {
    day = 1;
    practiceDays = {};
    minutes = 0;
    sessionsThisWeek = 0;
    missions = Personalizer.dailyPlan(skills, day);
    screen = AppScreen.home;
    changed();
  }

  // ---------------- daily practice ----------------
  void advanceDay() {
    if (day <= Cfg.daysPerWeek) day++;
    if (day <= Cfg.daysPerWeek) missions = Personalizer.dailyPlan(skills, day);
    changed();
  }

  /// Demo helper: replays the rest of the week as realistic practice so the weekly loop can be shown quickly.
  void _fillDemoPractice() {
    for (var d = day; d <= Cfg.daysPerWeek; d++) {
      for (final m in Personalizer.dailyPlan(skills, d)) {
        final st = skills[m.skill]!;
        st.sessions++;
        st.recent = [...st.recent, 1, 1, 1, 0, 1].reversed.take(Cfg.recentWindow).toList().reversed.toList();
        sessionsThisWeek++;
        stars += 2;
      }
      practiceDays.add(d);
      minutes += Cfg.targetMinutesPerDay * 0.9;
    }
    day = Cfg.daysPerWeek + 1;
  }

  void jumpToEndOfWeek() {
    if (!weekReady) _fillDemoPractice();
    changed();
  }

  SessionOutcome recordGame(GameId game, List<ItemResult> results, double seconds, {int? endLevel}) {
    final skill = Skills.game(game).skill;
    final st = skills[skill]!;
    final before = st.level;
    final adaptEvents = <AdaptEvent>[];

    for (final r in results) {
      st.recent.add(r.correct ? 1 : 0);
      if (st.recent.length > Cfg.recentWindow) st.recent.removeAt(0);
    }
    _addErrors(results);
    st.sessions++;
    final acc = results.isEmpty ? 1.0 : results.where((r) => r.correct).length / results.length;
    if (endLevel != null && endLevel != before) {
      // the level already moved inside the round (live adaptation) — keep it
      st.level = endLevel;
      st.scaffold = endLevel < before;
    } else {
      final decision = Personalizer.adapt(st.recent, st.level);
      st.level = decision.level;
      st.scaffold = decision.scaffold;
    }
    if (st.level != before) {
      adaptEvents.add(AdaptEvent(skill, before, st.level));
    }

    final starsEarned = acc >= 0.8 ? 3 : (acc >= 0.5 ? 2 : 1);
    final prevUnlocked = unlocked.map((c) => c.id).toSet();
    final prevBadges = Set<String>.of(badges);
    stars += starsEarned;
    badges.add(Badges.forSkill(skill).id);
    if (adaptEvents.any((e) => e.up)) badges.add(Badges.levelUp.id);

    final mi = missions.indexWhere((m) => m.skill == skill && !m.done);
    var dayComplete = false;
    if (mi >= 0) {
      missions[mi].done = true;
      if (dayDone) {
        dayComplete = true;
        practiceDays.add(day);
        stars += 3;
        badges.add(Badges.day.id);
      }
    }
    minutes += seconds / 60.0;
    sessionsThisWeek++;

    final newC = unlocked.where((c) => !prevUnlocked.contains(c.id)).toList();
    final defs = <String, BadgeDef>{
      Badges.first.id: Badges.first,
      Badges.day.id: Badges.day,
      Badges.week.id: Badges.week,
      Badges.levelUp.id: Badges.levelUp,
      for (final s in Skill.values) Badges.forSkill(s).id: Badges.forSkill(s),
    };
    final newB = [for (final id in badges.difference(prevBadges)) defs[id]!];
    changed();
    return SessionOutcome(starsEarned, starsEarned * Cfg.pointsPerStar, acc, adaptEvents, newC, newB, dayComplete);
  }

  void equipHat(int idx) {
    avatar.hat = idx;
    changed();
  }
}
