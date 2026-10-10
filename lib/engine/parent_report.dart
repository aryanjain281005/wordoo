import '../data/skills.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'report.dart';
import 'campaign.dart';

/// The numbers behind the emailed parent report: the same figures the Grown-up Dashboard shows (baseline vs latest check-in,
/// practice totals, common slips). The server's Gemini report writer turns them into the email; no raw answers or audio leave the phone.
Map<String, dynamic> parentReportData(AppState st) {
  String day(DateTime d) => d.toIso8601String().substring(0, 10);
  final base = st.history.isEmpty ? null : st.history.first.scores;
  final cur = st.history.isEmpty ? null : st.history.last.scores;
  final started = [for (final e in st.campaign.islands.entries) if (e.value.nodes > 0) Campaign.islandName(e.key)];
  return {
    'report_language': st.langCode == 'hi' ? 'hi' : 'en',
    'child': {'name': st.explorerName, 'age': st.age, 'class': st.grade},
    'season': 'Season ${st.campaign.season}: ${seasonName(st.campaign.season)}',
    'check_ins_done': st.cycle,
    if (st.screenings.isNotEmpty) 'baseline_date': day(st.screenings.first.date),
    if (st.screenings.isNotEmpty) 'latest_date': day(st.screenings.last.date),
    'skills': [
      for (final s in Skill.values)
        {
          'skill': Skills.of(s).name,
          'baseline_pct': (base?[s] ?? st.skills[s]!.score).round(),
          'latest_pct': (cur?[s] ?? st.skills[s]!.score).round(),
        },
    ],
    'game_stats': {
      'levels_cleared': st.campaign.islands.values.fold<int>(0, (a, i) => a + i.nodes),
      'stars': st.stars,
      'islands_started': started,
    },
    'difficult_items': [for (final e in Report.errors(st).take(4)) '${Skills.of(e.skill).name}: ${e.tag} (${e.count}×)'],
    'observations': Report.observations(st),
  };
}
