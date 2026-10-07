import '../data/skills.dart';
import '../engine/personalizer.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class ErrorStat {
  final Skill skill;
  final String tag;
  final int count;
  ErrorStat(this.skill, this.tag, this.count);
}

class Report {
  /// Errors of the finished week (after reassessment) or of the week in progress.
  static List<ErrorStat> errors(AppState st, {bool lastWeek = false}) {
    final out = <ErrorStat>[];
    if (lastWeek) {
      st.lastWeekErrors.forEach((k, n) {
        final parts = k.split('|');
        out.add(ErrorStat(Skill.values[int.parse(parts[0])], parts[1], n));
      });
    } else {
      st.skills.forEach((s, ss) => ss.errors.forEach((t, n) => out.add(ErrorStat(s, t, n))));
    }
    out.sort((a, b) => b.count.compareTo(a.count));
    return out;
  }

  static double delta(AppState st, Skill s) {
    if (st.history.length < 2) return 0;
    return st.history.last.scores[s]! - st.history.first.scores[s]!;
  }

  static double overall(AppState st) {
    if (st.history.length < 2) return 0;
    final d = Skill.values.map((s) => delta(st, s)).reduce((a, b) => a + b) / Skill.values.length;
    return d;
  }

  static Skill? biggestImprovement(AppState st) {
    if (st.history.length < 2) return null;
    final l = Skill.values.toList()..sort((a, b) => delta(st, b).compareTo(delta(st, a)));
    return l.first;
  }

  static const _improved = {
    Skill.phonological: 'Sound awareness improved — first sounds and blending are getting easier.',
    Skill.gpc: 'Matching letters to sounds improved.',
    Skill.decoding: 'Reading accuracy improved with familiar words.',
    Skill.wordRecognition: 'Recognising familiar words became faster and more accurate.',
    Skill.spelling: 'Spelling errors reduced.',
    Skill.comprehension: 'Understanding of what happened and why improved.',
  };
  static const _still = {
    Skill.phonological: 'Changing and deleting sounds still needs support.',
    Skill.gpc: 'Less common letter patterns still need practice.',
    Skill.decoding: 'Decoding longer words still needs support.',
    Skill.wordRecognition: 'Telling look-alike words apart still needs practice.',
    Skill.spelling: 'Spelling longer words still needs support.',
    Skill.comprehension: 'Inference questions (“how did they feel?”) still need support.',
  };

  static List<String> observations(AppState st) {
    final out = <String>[];
    if (st.history.length >= 2) {
      final ranked = Skill.values.toList()..sort((a, b) => delta(st, b).compareTo(delta(st, a)));
      for (final s in ranked.where((s) => delta(st, s) >= 6).take(3)) {
        out.add(_improved[s]!);
      }
      final lag = Skill.values.where((s) => Personalizer.classify(st.skills[s]!.score) != Band.strong).toList()
        ..sort((a, b) => st.skills[a]!.score.compareTo(st.skills[b]!.score));
      for (final s in lag.take(2)) {
        out.add(_still[s]!);
      }
    } else {
      final weak = Personalizer.ranked(st.skills).take(2);
      for (final s in weak) {
        out.add(_still[s]!);
      }
    }
    final e = errors(st, lastWeek: st.history.length >= 2);
    if (e.isNotEmpty) out.add('Most common slip: ${e.first.tag.toLowerCase()} (${Skills.of(e.first.skill).shortName}).');
    return out;
  }

  static String why(AppState st, Skill s) {
    final d = delta(st, s);
    final b = Personalizer.classify(st.skills[s]!.score);
    if (st.history.length >= 2) {
      if (d >= 12 && b == Band.strong) return 'Improved strongly — a lighter touch this week';
      if (d >= 8) return 'Improving — keep the momentum';
      if (b == Band.needsSupport) return 'Still needs support — more targeted practice';
      return 'Developing — steady practice';
    }
    return Personalizer.reasonFor(s, st.skills[s]!);
  }
}
