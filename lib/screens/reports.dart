import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../data/lang.dart';
import '../data/skills.dart';
import '../engine/personalizer.dart';
import '../engine/report.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/report_widgets.dart';
import 'loop_screen.dart';
import '../screening/ui/report_screen.dart';

Widget _scroll(Widget child) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: child)),
    );

/// Parent-facing weekly report: baseline vs week 1.
class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final week = st.history.length - 1;
    final best = Report.biggestImprovement(st);
    final focus = Personalizer.weekFocus(st.skills).first;
    final simulated = st.history.last.simulated;
    return AdventureBackground(
      scene: Scene.day,
      calm: true,
      child: SafeArea(
        child: _scroll(Column(children: [
          Panel(
            color: const Color(0xFFFFFDF5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${st.explorerName}’s Week $week Progress Report', style: ts(26))),
                bandPill('Grown-up view', C.purple, size: 12),
              ]),
              const SizedBox(height: 4),
              Text('Fresh questions, same skills — so we can see real progress, not memory.', style: ts(14, color: C.inkSoft, w: FontWeight.w600)),
              if (simulated)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Demo: Week-$week results were simulated from the practice played.', style: ts(12, color: C.orangeDark)),
                ),
              const Divider(height: 28),
              OverallBars(st),
              const Divider(height: 28),
              sectionTitle('Skill Performance', sub: 'Baseline → this week, for each of the six skills'),
              SkillCompare(st),
            ]),
          ),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('🏆 Biggest improvement', style: ts(15, color: C.inkSoft)), const SizedBox(height: 6), Text(best == null ? '—' : Skills.of(best).name, style: ts(19))]))),
            const SizedBox(width: 12),
            Expanded(child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('🎯 Current focus', style: ts(15, color: C.inkSoft)), const SizedBox(height: 6), Text(Skills.of(focus).name, style: ts(19))]))),
          ]),
          const SizedBox(height: 14),
          Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [sectionTitle('Practice consistency'), PracticeCard(st)])),
          const SizedBox(height: 14),
          Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [sectionTitle('What we observed'), ObservedCard(Report.observations(st))])),
          const SizedBox(height: 14),
          Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [sectionTitle('Common slips this week', sub: 'Used to target practice'), ErrorsCard(Report.errors(st, lastWeek: true))])),
          const SizedBox(height: 14),
          const SupportNote(),
          const SizedBox(height: 18),
          BigButton(label: 'See the Next Adventure', icon: Icons.auto_awesome_rounded, style: BtnStyle.go, width: 340, onTap: () => st.go(AppScreen.nextAdventure)),
          const SizedBox(height: 20),
        ])),
      ),
    );
  }
}

/// "Your Next Adventure Awaits!" — plan regenerated from the new profile.
class NextAdventureScreen extends StatelessWidget {
  const NextAdventureScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final focus = Personalizer.weekFocus(st.skills);
    final dayOne = Personalizer.dailyPlan(st.skills, 1);
    return AdventureBackground(
      scene: Scene.treasure,
      calm: true,
      child: SafeArea(
        child: _scroll(Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            decoration: BoxDecoration(color: C.parchment, borderRadius: BorderRadius.circular(32), border: Border.all(color: C.parchmentDark, width: 5), boxShadow: [softShadow(const Color(0x55000000), 26, 12)]),
            child: Column(children: [
              Text('Your Next Adventure Awaits!', textAlign: TextAlign.center, style: ts(32, color: const Color(0xFF9B3E1A), w: FontWeight.w900)),
              const SizedBox(height: 6),
              Companion(type: st.avatar.companion, size: 96, message: 'Look, ${st.explorerName}! A new map, made just for you.', speakLocale: st.pack.tts),
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: Text('Focus for next week:', style: ts(21, color: const Color(0xFF7A4E22)))),
              const SizedBox(height: 8),
              for (final s in focus)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(20), border: Border.all(color: Skills.of(s).color, width: 2.5)),
                    child: Row(children: [
                      Text(Skills.of(s).emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(Skills.of(s).region, style: ts(18)),
                        Text(Report.why(st, s), style: ts(13, color: C.inkSoft, w: FontWeight.w600)),
                      ])),
                      Text(Skills.game(Skills.of(s).demoGame).emoji, style: const TextStyle(fontSize: 28)),
                    ]),
                  ),
                ),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: Text('Suggested missions:', style: ts(21, color: const Color(0xFF7A4E22)))),
              const SizedBox(height: 8),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final m in dayOne) bandPill('${Skills.game(m.game).emoji} ${Skills.game(m.game).name}', Skills.of(m.skill).color, size: 17),
              ]),
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: Text('Starting power for each skill:', style: ts(18, color: const Color(0xFF7A4E22)))),
              const SizedBox(height: 6),
              for (final s in Skill.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Text(Skills.of(s).emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(Skills.of(s).shortName, style: ts(14))),
                    PowerPips(level: st.skills[s]!.level),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 18),
          BigButton(label: 'Continue My Journey', icon: Icons.explore_rounded, style: BtnStyle.go, width: 340, onTap: () => st.go(AppScreen.loop)),
          const SizedBox(height: 20),
        ])),
      ),
    );
  }
}

/// Everything a grown-up needs, in one place — plus demo controls for judges.
class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final has = st.history.length >= 2;
    final focus = Personalizer.weekFocus(st.skills);
    return AdventureBackground(
      scene: Scene.night,
      calm: true,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              RoundIconButton(icon: Icons.arrow_back_rounded, label: 'Back to adventure', onTap: () => st.go(AppScreen.home)),
              const SizedBox(width: 12),
              Expanded(child: Text('Grown-up Dashboard', style: ts(26, color: Colors.white))),
            ]),
          ),
          Expanded(
            child: _scroll(Column(children: [
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    AvatarView(hair: st.avatar.hair, outfit: st.avatar.outfit, height: 90, hatEmoji: st.avatar.hat >= 0 ? Collectibles.all[st.avatar.hat].emoji : null),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(st.explorerName, style: ts(26)),
                      Text('Age ${st.age} • ${st.grade} • ${st.pack.native}', style: ts(14, color: C.inkSoft, w: FontWeight.w600)),
                      Text(has ? 'Week ${st.history.length - 1} complete — Week ${st.history.length} plan ready' : 'Week 1 of practice • Day ${st.day > 7 ? 7 : st.day} of 7', style: ts(14, color: C.purple)),
                    ])),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                sectionTitle('Skill profile', sub: 'Each skill is measured — and adapts — on its own'),
                for (final s in Skill.values) _profileRow(st, s),
                const SizedBox(height: 6),
                const SupportNote(),
              ])),
              const SizedBox(height: 14),
              Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                sectionTitle(has ? 'Baseline vs this week' : 'Skill performance', sub: has ? 'Skill Performance (not a medical score)' : 'Baseline from the first adventure — week-1 check-in comes after 7 days'),
                SkillCompare(st),
              ])),
              const SizedBox(height: 14),
              Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [sectionTitle('Practice consistency'), PracticeCard(st)])),
              const SizedBox(height: 14),
              Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [sectionTitle('Common slips', sub: 'The engine targets these, not just “easier”'), ErrorsCard(Report.errors(st))])),
              const SizedBox(height: 14),
              Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                sectionTitle('Current focus & plan', sub: 'Generated from the skill profile'),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final s in focus) bandPill('${Skills.of(s).emoji} ${Skills.of(s).name}', Skills.of(s).color, size: 14)]),
                const SizedBox(height: 12),
                WeekPlan(st),
              ])),
              const SizedBox(height: 14),
              Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [sectionTitle('What we observed'), ObservedCard(Report.observations(st))])),
              const SizedBox(height: 14),
              _settings(context, st),
              const SizedBox(height: 14),
              _demo(context, st),
              const SizedBox(height: 14),
              Panel(
                child: Text('🔒 Privacy: only a nickname, age/class, language and practice results are stored — on this device. No phone number, location, photo or ID is collected.', style: ts(14, color: C.inkSoft, w: FontWeight.w600, h: 1.35)),
              ),
              const SizedBox(height: 24),
            ])),
          ),
        ]),
      ),
    );
  }

  Widget _profileRow(AppState st, Skill s) {
    final m = Skills.of(s);
    final b = st.bandOf(s);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(m.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Expanded(child: Text(m.name, style: ts(15))),
        PowerPips(level: st.skills[s]!.level),
        const SizedBox(width: 10),
        SizedBox(width: 118, child: Align(alignment: Alignment.centerRight, child: bandPill(BandInfo.label(b), BandInfo.color(b), size: 12))),
      ]),
    );
  }

  Widget _settings(BuildContext context, AppState st) {
    Widget chip(String t, bool sel, VoidCallback f) => GestureDetector(
          onTap: f,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: sel ? C.purple : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.purple, width: 2)),
            child: Text(t, style: ts(15, color: sel ? Colors.white : C.purple)),
          ),
        );
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionTitle('Settings & accessibility'),
        Text('Text size', style: ts(15, color: C.inkSoft)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          chip('Normal', st.textSize == 0, () => st.setSettings(textSize: 0)),
          chip('Large', st.textSize == 1, () => st.setSettings(textSize: 1)),
          chip('Extra large', st.textSize == 2, () => st.setSettings(textSize: 2)),
        ]),
        const SizedBox(height: 12),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('Extra letter spacing', style: ts(16)), value: st.extraSpacing, onChanged: (v) => st.setSettings(extraSpacing: v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('Spoken instructions (read aloud)', style: ts(16)), value: st.voiceOn, onChanged: (v) => st.setSettings(voiceOn: v)),
        const SizedBox(height: 6),
        Text('Learning language', style: ts(15, color: C.inkSoft)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final l in LangRegistry.all)
            Opacity(opacity: l.available ? 1 : .5, child: chip(l.available ? l.native : '${l.name} (soon)', st.langCode == l.code, l.available ? () => st.setLang(l.code) : () {})),
        ]),
      ]),
    );
  }

  Widget _demo(BuildContext context, AppState st) {
    return Panel(
      color: const Color(0xFFFFF3C4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionTitle('Demo controls', sub: 'For presenting the one-week loop quickly'),
        Wrap(spacing: 10, runSpacing: 10, children: [
          BigButton(label: 'Profile A (Aarav)', style: BtnStyle.soft, height: 50, fontSize: 15, onTap: () => st.loadDemoProfile(0)),
          BigButton(label: 'Profile B (Meera)', style: BtnStyle.soft, height: 50, fontSize: 15, onTap: () => st.loadDemoProfile(1)),
          BigButton(label: 'Skip to tomorrow', style: BtnStyle.soft, height: 50, fontSize: 15, onTap: st.day > Cfg.daysPerWeek ? null : st.advanceDay),
          BigButton(label: 'Jump to end of week', style: BtnStyle.soft, height: 50, fontSize: 15, onTap: st.weekReady ? null : st.jumpToEndOfWeek),
          BigButton(label: 'Run screening now', style: BtnStyle.go, height: 50, fontSize: 15, onTap: () => st.go(AppScreen.intro)),
          BigButton(label: 'Simulate week-1 results', style: BtnStyle.primary, height: 50, fontSize: 15, onTap: st.hasBaseline && st.history.length < 2 ? st.simulateWeekOne : null),
          BigButton(label: 'Screening report', style: BtnStyle.soft, height: 50, fontSize: 15, onTap: st.lastScreening == null ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScreeningReportScreen(report: st.lastScreening!, childName: st.explorerName)))),
          BigButton(label: 'Latest report', style: BtnStyle.soft, height: 50, fontSize: 15, onTap: st.history.length >= 2 ? () => st.go(AppScreen.weeklyReport) : null),
          BigButton(label: 'Learning loop', style: BtnStyle.soft, height: 50, fontSize: 15, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoopScreen(buttonLabel: 'Close', onContinue: () => Navigator.of(context).pop())))),
          BigButton(label: 'Reset everything', style: BtnStyle.soft, height: 50, fontSize: 15, onTap: () => st.resetAll()),
        ]),
      ]),
    );
  }
}
