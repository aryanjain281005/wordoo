import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../engine/personalizer.dart';
import '../engine/campaign.dart';
import '../engine/report.dart';
import '../engine/skill_model.dart';
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
    final items = Skill.values.fold<int>(0, (a, s) => a + st.model(s).cycleItems);
    Widget stat(String v, String l) => Expanded(
          child: Column(children: [
            Text(v, style: ts(24, color: C.purple)),
            Text(l, textAlign: TextAlign.center, style: ts(12, color: C.inkSoft, w: FontWeight.w600)),
          ]),
        );
    return Row(children: [
      stat('${st.cycleDays}', 'days played'),
      stat('${st.cycleMinutes.round()}', 'minutes'),
      stat('${st.cycleRounds}', 'quests'),
      stat('$items', 'answers'),
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

/// Per-skill learning picture: starting step from the screening → current step, status and practice targets.
class SkillPlan extends StatelessWidget {
  final AppState st;
  const SkillPlan(this.st, {super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final s in Skill.values) _row(s),
    ]);
  }

  Widget _row(Skill s) {
    final m = st.model(s);
    final start = st.cycleStartStep[s] ?? m.step;
    final island = islandOf(s);
    final ist = st.campaign.islands[island]!;
    final focus = m.focusErrors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(Skills.of(s).emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Skills.of(s).name, style: ts(15)),
            Text('Step $start → ${m.step} of 10 · ${statusLabel(m.status)}', style: ts(13, color: C.purple)),
            Text('${Campaign.islandName(island)}: ${tierName(ist.tier)}, chapter ${ist.nodes.clamp(0, Cfg.chapterNodes)}/${Cfg.chapterNodes} · ${m.cycleItems} answers',
                style: ts(12, color: C.inkSoft, w: FontWeight.w500)),
            if (focus.isNotEmpty) Text('Practising: ${focus.join(', ').toLowerCase()}', style: ts(12, color: C.orangeDark, w: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

/// What still has to happen before the next check-in (never a date).
class RetestChecklist extends StatelessWidget {
  final AppState st;
  const RetestChecklist(this.st, {super.key});
  @override
  Widget build(BuildContext context) {
    final r = st.retest;
    if (r.ready) {
      return Row(children: [
        const Icon(Icons.check_circle_rounded, color: C.green),
        const SizedBox(width: 8),
        Expanded(child: Text('Ready! The Star Bridge check-in is open on the map.', style: ts(15))),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('The check-in opens after all seven islands are played through:', style: ts(14, color: C.inkSoft, w: FontWeight.w600)),
      const SizedBox(height: 6),
      for (final m in r.missing.take(8))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            const Icon(Icons.radio_button_unchecked_rounded, size: 16, color: C.inkSoft),
            const SizedBox(width: 8),
            Expanded(child: Text(m, style: ts(13, w: FontWeight.w500))),
          ]),
        ),
      if (r.missing.length > 8) Text('…and ${r.missing.length - 8} more', style: ts(12, color: C.inkSoft)),
    ]);
  }
}
