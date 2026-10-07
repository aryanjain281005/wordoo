import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../engine/personalizer.dart';
import '../engine/report.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'common.dart';

Widget sectionTitle(String t, {String? sub}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: ts(22)),
        if (sub != null) Text(sub, style: ts(14, color: C.inkSoft, w: FontWeight.w600)),
      ]),
    );

/// Baseline vs latest "Skill Performance" for every skill.
class SkillCompare extends StatelessWidget {
  final AppState st;
  const SkillCompare(this.st, {super.key});
  @override
  Widget build(BuildContext context) {
    final has = st.history.length >= 2;
    final base = st.history.first.scores;
    final cur = st.history.last.scores;
    return Column(children: [
      for (final s in Skill.values)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: _row(s, base[s]!, cur[s]!, has),
        ),
    ]);
  }

  Widget _row(Skill s, double b, double c, bool has) {
    final m = Skills.of(s);
    final bb = Personalizer.classify(b), cb = Personalizer.classify(c);
    final d = c - b;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(m.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Expanded(child: Text(m.name, style: ts(16))),
        if (has) ...[
          Text('${b.round()}% → ${c.round()}%', style: ts(16, color: C.ink)),
          const SizedBox(width: 6),
          Icon(d >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 18, color: d >= 3 ? C.green : C.inkSoft),
        ] else
          Text('${c.round()}%', style: ts(16)),
      ]),
      const SizedBox(height: 5),
      Stack(children: [
        Container(height: 12, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
        if (has)
          FractionallySizedBox(widthFactor: (b / 100).clamp(.03, 1), child: Container(height: 12, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)))),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (c / 100).clamp(.03, 1)),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => FractionallySizedBox(
            widthFactor: v,
            child: Container(height: 12, decoration: BoxDecoration(color: BandInfo.color(cb), borderRadius: BorderRadius.circular(8))),
          ),
        ),
      ]),
      const SizedBox(height: 5),
      Row(children: [
        if (has && bb != cb) ...[
          bandPill(BandInfo.label(bb), BandInfo.color(bb), size: 12),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 16)),
          bandPill(BandInfo.label(cb), BandInfo.color(cb), size: 12),
        ] else
          bandPill(BandInfo.label(cb), BandInfo.color(cb), size: 12),
      ]),
    ]);
  }
}

class PracticeCard extends StatelessWidget {
  final AppState st;
  const PracticeCard(this.st, {super.key});
  @override
  Widget build(BuildContext context) {
    final days = st.practiceDays.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var d = 1; d <= Cfg.daysPerWeek; d++)
          Column(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: st.practiceDays.contains(d) ? C.green : (d == st.day ? C.gold.withValues(alpha: .4) : Colors.black12),
                border: d == st.day ? Border.all(color: C.gold, width: 3) : null,
              ),
              child: st.practiceDays.contains(d) ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : Text('$d', style: ts(14, color: C.inkSoft)),
            ),
          ]),
      ]),
      const SizedBox(height: 10),
      Text('$days of ${Cfg.daysPerWeek} days practised  •  about ${st.minutes.round()} minutes this week  •  ${st.sessionsThisWeek} games played', style: ts(15, color: C.inkSoft, w: FontWeight.w600)),
    ]);
  }
}

class ErrorsCard extends StatelessWidget {
  final List<ErrorStat> errors;
  const ErrorsCard(this.errors, {super.key});
  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return Text('No repeated mistakes yet — keep playing!', style: ts(16, color: C.inkSoft));
    return Column(children: [
      for (final e in errors.take(5))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Text(Skills.of(e.skill).emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text('${e.tag}  •  ${Skills.of(e.skill).shortName}', style: ts(15))),
            bandPill('${e.count}×', C.orange, size: 13),
          ]),
        ),
    ]);
  }
}

class ObservedCard extends StatelessWidget {
  final List<String> items;
  const ObservedCard(this.items, {super.key});
  @override
  Widget build(BuildContext context) => Column(children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle_rounded, color: C.green, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(t, style: ts(15, w: FontWeight.w600, h: 1.3))),
            ]),
          ),
      ]);
}

class SupportNote extends StatelessWidget {
  const SupportNote({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFEAF5FF), borderRadius: BorderRadius.circular(18), border: Border.all(color: C.sky, width: 2)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('💬', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is a literacy skill-practice report, not a diagnosis. If difficulties continue, consider talking to a teacher or a qualified professional.',
              style: ts(14, color: C.inkSoft, w: FontWeight.w600, h: 1.35),
            ),
          ),
        ]),
      );
}

class OverallBars extends StatelessWidget {
  final AppState st;
  const OverallBars(this.st, {super.key});
  @override
  Widget build(BuildContext context) {
    final d = Report.overall(st);
    return Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Overall skill performance', style: ts(14, color: C.inkSoft)),
        Text('${d >= 0 ? '+' : ''}${d.round()}%', style: ts(48, color: d >= 0 ? C.green : C.orange, w: FontWeight.w900)),
      ]),
      const Spacer(),
      SizedBox(
        height: 70,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final s in Skill.values)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (st.history.last.scores[s]! / 100)),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Container(width: 16, height: 70 * v, decoration: BoxDecoration(color: BandInfo.color(Personalizer.classify(st.history.last.scores[s]!)), borderRadius: BorderRadius.circular(5))),
              ),
            ),
        ]),
      ),
    ]);
  }
}

/// Day-by-day plan generated from the profile — shows personalisation at a glance.
class WeekPlan extends StatelessWidget {
  final AppState st;
  const WeekPlan(this.st, {super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var d = 1; d <= Cfg.daysPerWeek; d++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 52, child: Text('Day $d', style: ts(14, color: d == st.day ? C.purple : C.inkSoft))),
            for (final m in Personalizer.dailyPlan(st.skills, d))
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  decoration: BoxDecoration(color: Skills.of(m.skill).color.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text('${Skills.game(m.game).emoji} ${Skills.game(m.game).name}', style: ts(13))),
                ),
              ),
          ]),
        ),
    ]);
  }
}
