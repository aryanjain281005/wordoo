import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../engine/personalizer.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/props.dart';
import '../screening/scorer.dart';
import '../screening/ui/report_screen.dart';

/// Result of the first adventure: the six-skill map (a grown-up/system view) + how the world is personalised.
class SkillMapScreen extends StatelessWidget {
  const SkillMapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final ranked = Personalizer.ranked(st.skills);
    final weak = ranked.first, mid = ranked[2], strong = ranked.last;
    return AdventureBackground(
      scene: Scene.treasure,
      calm: true,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(children: [
                const _ScrollRoll(),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: BoxDecoration(
                    color: C.parchment,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: C.parchmentDark, width: 5),
                    boxShadow: [softShadow(const Color(0x55000000), 26, 12)],
                  ),
                  child: Column(children: [
                    Text('${st.explorerName}’s Skill Map', textAlign: TextAlign.center, style: ts(32, color: const Color(0xFF7A4E22), w: FontWeight.w900)),
                    const SizedBox(height: 4),
                    bandPill('Grown-up view • literacy skill snapshot', C.purple, size: 13),
                    const SizedBox(height: 14),
                    for (var i = 0; i < Skill.values.length; i++) Pop(index: i, child: _Row(skill: Skill.values[i], score: st.skills[Skill.values[i]]!.score)),
                    const SizedBox(height: 6),
                    Text('These are the skills we’ll strengthen on your adventure.', textAlign: TextAlign.center, style: ts(17, color: C.inkSoft, w: FontWeight.w600)),
                  ]),
                ),
                const _ScrollRoll(),
                if (st.lastScreening != null) ...[
                  const SizedBox(height: 12),
                  Pop(
                    index: 5,
                    child: Panel(
                      color: Colors.white.withValues(alpha: .95),
                      child: Column(children: [
                        Text('Screening result: ${indicatorLabel(st.lastScreening!.indicator)}', textAlign: TextAlign.center, style: ts(18)),
                        const SizedBox(height: 6),
                        Text(indicatorAdvice(st.lastScreening!.indicator), textAlign: TextAlign.center, style: ts(13, color: C.inkSoft, w: FontWeight.w500)),
                        const SizedBox(height: 10),
                        BigButton(
                          label: 'Full screening report',
                          icon: Icons.description_rounded,
                          style: BtnStyle.soft,
                          height: 52,
                          fontSize: 17,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScreeningReportScreen(report: st.lastScreening!, childName: st.explorerName))),
                        ),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    for (final k in const [('forest', Color(0xFF56C27E), Color(0xFF2E9B5B)), ('treasure', Color(0xFFFFD35C), Color(0xFFE0A41A)), ('castle', Color(0xFFFF8FB8), Color(0xFFD9578A))])
                      SizedBox(width: 96, height: 96, child: CustomPaint(painter: IslandArt(k.$1, k.$2, k.$3))),
                  ]),
                ),
                const SizedBox(height: 6),
                Pop(
                  index: 6,
                  child: Panel(
                    color: Colors.white.withValues(alpha: .94),
                    child: Column(children: [
                      Text('Personalizing your world…', style: ts(24)),
                      const SizedBox(height: 12),
                      Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
                        _chip('🆘', 'More help in ${Skills.of(weak).shortName}', BandInfo.color(Band.needsSupport)),
                        _chip('💪', 'More practice in ${Skills.of(mid).shortName}', BandInfo.color(Band.developing)),
                        _chip('🚀', 'Advanced levels in ${Skills.of(strong).shortName}', BandInfo.color(Band.strong)),
                      ]),
                      const SizedBox(height: 10),
                      Text('This is a practice guide, not a diagnosis. If difficulties continue, consider talking to a teacher or a qualified professional.',
                          textAlign: TextAlign.center, style: ts(13, color: C.inkSoft, w: FontWeight.w500)),
                    ]),
                  ),
                ),
                const SizedBox(height: 18),
                Pop(index: 7, child: BigButton(label: 'Enter My World', icon: Icons.map_rounded, style: BtnStyle.go, width: 300, onTap: () => st.go(AppScreen.home))),
                const SizedBox(height: 10),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String e, String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: c.withValues(alpha: .14), borderRadius: BorderRadius.circular(20), border: Border.all(color: c, width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(e, style: const TextStyle(fontSize: 22)), const SizedBox(width: 8), Flexible(child: Text(t, style: ts(15), softWrap: true))]),
      );
}

class _Row extends StatelessWidget {
  final Skill skill;
  final double score;
  const _Row({required this.skill, required this.score});
  @override
  Widget build(BuildContext context) {
    final m = Skills.of(skill);
    final b = Personalizer.classify(score);
    final color = BandInfo.color(b);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Text(m.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: ts(16, color: C.ink), maxLines: 2),
            const SizedBox(height: 5),
            Container(
              height: 14,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (score / 100).clamp(.06, 1)),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: v, child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)))),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 118, child: Align(alignment: Alignment.centerRight, child: bandPill(BandInfo.label(b), color, size: 14))),
      ]),
    );
  }
}

class _ScrollRoll extends StatelessWidget {
  const _ScrollRoll();
  @override
  Widget build(BuildContext context) => Container(
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9C77E), Color(0xFFC79A4B), Color(0xFFE9C77E)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [softShadow(const Color(0x44000000), 8, 4)],
        ),
      );
}
