import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'adventure.dart';
import 'avatar_creator.dart';
import 'landing.dart';
import 'loop_screen.dart';
import 'onboarding.dart';
import 'reports.dart';
import 'skill_map.dart';
import 'world_map.dart';

/// Single place that maps app state → screen, with a gentle cross-fade.
class AppShell extends StatelessWidget {
  const AppShell({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    if (!st.loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final Widget screen = switch (st.screen) {
      AppScreen.landing => const LandingScreen(),
      AppScreen.parent => const ParentOnboarding(),
      AppScreen.avatar => const AvatarCreator(),
      AppScreen.intro => const AdventureIntro(),
      AppScreen.assessment => const AssessmentScreen(),
      AppScreen.skillMap => const SkillMapScreen(),
      AppScreen.home => const WorldMapScreen(),
      AppScreen.dashboard => const ParentDashboard(),
      AppScreen.weeklyReport => const WeeklyReportScreen(),
      AppScreen.nextAdventure => const NextAdventureScreen(),
      AppScreen.loop => LoopScreen(onContinue: st.startNextWeek),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      child: KeyedSubtree(key: ValueKey(st.screen), child: screen),
    );
  }
}
