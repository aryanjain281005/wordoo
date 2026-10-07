import '../core/config.dart';
import '../data/skills.dart';
import '../models/models.dart';

/// Rule-based, explainable personalization. All thresholds come from [Cfg].
class Personalizer {
  static Band classify(double score) {
    if (score >= Cfg.strongCut) return Band.strong;
    if (score >= Cfg.developingCut) return Band.developing;
    return Band.needsSupport;
  }

  static int startLevel(Band b) => switch (b) {
        Band.strong => Cfg.levelStrong,
        Band.developing => Cfg.levelDeveloping,
        Band.needsSupport => Cfg.levelNeedsSupport,
      };

  /// Weighted score for an assessment: harder items count a little more.
  static double scoreAssessment(List<ItemResult> results) {
    if (results.isEmpty) return 0;
    var got = 0.0, tot = 0.0;
    for (final r in results) {
      final w = 1.0 + (r.level - 1) * 0.5;
      tot += w;
      if (r.correct) got += w;
    }
    return (got / tot * 100).roundToDouble();
  }

  static double accuracy(List<int> recent) {
    if (recent.isEmpty) return 1;
    return recent.reduce((a, b) => a + b) / recent.length;
  }

  /// Decide next level + scaffolding from recent accuracy.
  static ({int level, bool scaffold}) adapt(List<int> recent, int level) {
    if (recent.length < Cfg.minAttemptsToAdapt) return (level: level, scaffold: false);
    final acc = accuracy(recent);
    if (acc >= Cfg.increaseAccuracy) {
      return (level: (level + 1).clamp(Cfg.minLevel, Cfg.maxLevel), scaffold: false);
    }
    if (acc >= Cfg.maintainAccuracy) return (level: level, scaffold: false);
    return (level: (level - 1).clamp(Cfg.minLevel, Cfg.maxLevel), scaffold: true);
  }

  /// Priority of a skill for practice: weak skills first, repeated errors weigh in.
  static double priority(SkillState s) {
    final errs = s.errors.values.fold<int>(0, (a, b) => a + b);
    final recentMiss = s.recent.where((x) => x == 0).length;
    return (100 - s.score) + errs.clamp(0, 10) * 0.8 + recentMiss * 1.2;
  }

  static List<Skill> ranked(Map<Skill, SkillState> st) {
    final l = st.keys.toList();
    l.sort((a, b) => priority(st[b]!).compareTo(priority(st[a]!)));
    return l;
  }

  /// ≈10 minutes: three short missions chosen from the profile.
  /// Weakest skill every day, a second weak skill alternating, and a rotating
  /// third mission so strong skills keep progressing.
  static List<Mission> dailyPlan(Map<Skill, SkillState> st, int day) {
    final r = ranked(st);
    final d = day - 1;
    final picks = <Skill>[
      r[0],
      r[1 + (d % 2)],
      r[3 + (d % 3)],
    ];
    return [for (final s in picks) Mission(s, Skills.of(s).demoGame)];
  }

  /// Focus areas for the coming week.
  static List<Skill> weekFocus(Map<Skill, SkillState> st, {int n = 3}) => ranked(st).take(n).toList();

  static String reasonFor(Skill s, SkillState st) {
    final band = classify(st.score);
    return switch (band) {
      Band.needsSupport => 'Building the foundations first',
      Band.developing => 'Growing steadily — a little more practice',
      Band.strong => 'Ready for stretch challenges',
    };
  }
}
