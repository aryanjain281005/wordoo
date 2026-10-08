import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/common.dart';
import '../battery.dart';
import '../models.dart';
import '../scorer.dart';

Color bandColor(ScreenBand b) => switch (b) {
      ScreenBand.strong => const Color(0xFF2FA866),
      ScreenBand.developing => const Color(0xFFF2A21B),
      ScreenBand.needsSupport => const Color(0xFFEF7A3C),
      ScreenBand.notMeasured => const Color(0xFF9AA0B8),
    };

IconData bandIcon(ScreenBand b) => switch (b) {
      ScreenBand.strong => Icons.star_rounded,
      ScreenBand.developing => Icons.trending_up_rounded,
      ScreenBand.needsSupport => Icons.flag_rounded,
      ScreenBand.notMeasured => Icons.mic_off_rounded,
    };

/// Grown-up screening report: indicator, six skills + two supporting skills, DALI domains,
/// observations, and an educator detail table. Never a diagnosis.
class ScreeningReportScreen extends StatelessWidget {
  final ScreeningReport report;
  final String childName;
  final VoidCallback? onContinue;
  const ScreeningReportScreen({super.key, required this.report, required this.childName, this.onContinue});

  @override
  Widget build(BuildContext context) {
    final r = report;
    final ic = switch (r.indicator) { Indicator.low => const Color(0xFF2FA866), Indicator.some => const Color(0xFFF2A21B), Indicator.elevated => const Color(0xFFEF7A3C) };
    return Scaffold(
      body: AdventureBackground(
        scene: Scene.night,
        calm: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                RoundIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => onContinue != null ? onContinue!() : Navigator.of(context).pop(), size: 48),
                const SizedBox(width: 10),
                Expanded(child: Text('Screening Report', style: ts(24, color: Colors.white))),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.all(14), children: [
                Panel(
                  color: const Color(0xFFFFFDF5),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$childName’s literacy screening', style: ts(22)),
                    Text('${r.lang == 'hi' ? 'Hindi' : 'English'} • ${r.band == GradeBand.junior ? 'Junior (Class 1–2)' : 'Middle (Class 3–5)'} • form ${r.pool} • about ${r.minutes < 1 ? 1 : r.minutes} min',
                        style: ts(13, color: C.inkSoft, w: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: ic.withValues(alpha: .12), borderRadius: BorderRadius.circular(18), border: Border.all(color: ic, width: 2.5)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(r.indicator == Indicator.low ? Icons.verified_rounded : (r.indicator == Indicator.some ? Icons.info_rounded : Icons.flag_circle_rounded), color: ic, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(indicatorLabel(r.indicator), style: ts(20, color: Color.lerp(ic, Colors.black, .35)!)),
                            const SizedBox(height: 4),
                            Text(indicatorAdvice(r.indicator), style: ts(14, color: C.ink, w: FontWeight.w500, h: 1.35)),
                          ]),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Panel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Skill profile', style: ts(20)),
                    Text('Percentile compared with the expected level for this class (provisional)', style: ts(12, color: C.inkSoft, w: FontWeight.w500)),
                    const SizedBox(height: 8),
                    for (final c in r.constructs) _constructRow(c),
                  ]),
                ),
                const SizedBox(height: 12),
                Panel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DALI-aligned domains', style: ts(20)),
                    const SizedBox(height: 6),
                    for (final d in Domain.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Icon(r.domainFlags[d]! ? Icons.flag_rounded : Icons.check_circle_rounded, color: r.domainFlags[d]! ? const Color(0xFFEF7A3C) : const Color(0xFF2FA866)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(domainNames[d]!, style: ts(15))),
                          Text(r.domainFlags[d]! ? 'Needs attention' : 'No flag', style: ts(13, color: C.inkSoft)),
                        ]),
                      ),
                  ]),
                ),
                const SizedBox(height: 12),
                if (r.strengths.isNotEmpty || r.needs.isNotEmpty)
                  Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (r.strengths.isNotEmpty) ...[
                        Text('💪 Strengths', style: ts(18)),
                        for (final x in r.strengths) Text('• $x', style: ts(15, w: FontWeight.w500)),
                        const SizedBox(height: 8),
                      ],
                      if (r.needs.isNotEmpty) ...[
                        Text('🎯 Skills to practise first', style: ts(18)),
                        for (final x in r.needs) Text('• $x', style: ts(15, w: FontWeight.w500)),
                      ],
                    ]),
                  ),
                const SizedBox(height: 12),
                Panel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('What we observed', style: ts(20)),
                    const SizedBox(height: 6),
                    for (final o in r.observations)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.visibility_rounded, size: 18, color: C.purple),
                          const SizedBox(width: 8),
                          Expanded(child: Text(o, style: ts(14, w: FontWeight.w500, h: 1.35))),
                        ]),
                      ),
                  ]),
                ),
                const SizedBox(height: 12),
                Panel(
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text('Educator detail (each activity)', style: ts(18)),
                      children: [for (final s in r.subtests) _subRow(s, r.band)],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFEAF5FF), borderRadius: BorderRadius.circular(18), border: Border.all(color: C.sky, width: 2)),
                  child: Text(
                    'This is an educational literacy screening, not a clinical diagnosis. Reading-aloud items were scored automatically by the device’s speech recognition, which can make mistakes. '
                    'Reference values are provisional until local norms are collected. If difficulties continue, consider talking to a teacher or a qualified professional.',
                    style: ts(13, color: C.inkSoft, w: FontWeight.w500, h: 1.35),
                  ),
                ),
                const SizedBox(height: 16),
                if (onContinue != null) Center(child: BigButton(label: 'Continue', icon: Icons.arrow_forward_rounded, style: BtnStyle.go, width: 260, onTap: onContinue)),
                const SizedBox(height: 20),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _constructRow(ConstructResult c) {
    final col = bandColor(c.band);
    final measured = c.band != ScreenBand.notMeasured;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(constructNames[c.construct]!, style: ts(15))),
          Icon(bandIcon(c.band), color: col, size: 18),
          const SizedBox(width: 4),
          Text(measured ? '${bandLabel(c.band)} · ${c.percentile.round()}th' : bandLabel(c.band), style: ts(13, color: Color.lerp(col, Colors.black, .3)!)),
        ]),
        const SizedBox(height: 4),
        Container(
          height: 10,
          decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(6)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: measured ? (c.percentile / 100).clamp(.03, 1) : 0,
            child: Container(decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(6))),
          ),
        ),
      ]),
    );
  }

  Widget _subRow(SubtestResult s, GradeBand band) {
    final d = subtestById(s.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(flex: 5, child: Text(d.parentName, style: ts(13))),
        Expanded(
          flex: 4,
          child: Text(
            !s.measured
                ? 'not measured'
                : '${(s.accuracy * 100).round()}% correct${s.rate != null ? ' · ${s.rate!.toStringAsFixed(s.rate! < 10 ? 2 : 0)} ${d.rateLabel}' : ''}',
            style: ts(12, color: C.inkSoft, w: FontWeight.w500),
          ),
        ),
        SizedBox(width: 88, child: Align(alignment: Alignment.centerRight, child: bandPill(bandLabel(s.band), bandColor(s.band), size: 11))),
      ]),
    );
  }
}
