import '../core/config.dart';
import '../models/models.dart';
import 'campaign.dart';
import 'skill_model.dart';

/// Thin helpers around the per-skill learner models. All thresholds live in [Cfg].
class Personalizer {
  static Band classify(double percentile) {
    if (percentile >= Cfg.strongCut) return Band.strong;
    if (percentile >= Cfg.developingCut) return Band.developing;
    return Band.needsSupport;
  }

  /// Skills ordered by screening score, weakest first.
  static List<Skill> ranked(Map<Skill, SkillState> st) {
    final l = st.keys.toList();
    l.sort((a, b) => st[a]!.score.compareTo(st[b]!.score));
    return l;
  }

  /// Skills ordered by current practice need (weak level, repeated errors, struggling), highest first.
  static List<Skill> byNeed(Map<Skill, SkillModel> m) {
    final l = m.keys.toList();
    l.sort((a, b) => Campaign.need(m[b]!).compareTo(Campaign.need(m[a]!)));
    return l;
  }

  static List<Skill> focus(Map<Skill, SkillModel> m, {int n = 3}) => byNeed(m).take(n).toList();

  static String reasonFor(Skill s, SkillModel m) => switch (m.status) {
        SkillStatus.struggling => 'Needs extra support — gentle quests with hints',
        SkillStatus.calibrating => 'Finding the right level',
        SkillStatus.improving => 'Improving — keep the momentum',
        SkillStatus.ready => 'Ready for challenge quests',
        SkillStatus.steady => 'Steady practice at the right level',
      };
}
