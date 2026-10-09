import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/core/theme.dart';
import 'package:wordoo/engine/campaign.dart';
import 'package:wordoo/engine/levels.dart';
import 'package:wordoo/models/models.dart';
import 'package:wordoo/screens/game_screen.dart';
import 'package:wordoo/state/app_state.dart';

/// Crash hunt (Phase 7): every game, every level, hammered with random taps and swipes like a small child.
/// Any exception (layout, state, null, range…) fails the test. Plugins missing in tests (audio/TTS) are ignored.
void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  for (final i in IslandId.values) {
    for (final g in islandGames(i)) {
      testWidgets('no crash: ${g.name}, all 4 levels, random play', (t) async {
        final errors = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) {
          final s = d.exceptionAsString();
          if (!s.contains('MissingPluginException')) { errors.add(s.split('\n').first); if (errors.length == 1) debugPrint('FIRST ERROR: ${d.toString().substring(0, min(3000, d.toString().length))}'); }
        };
        final st = AppState()..loadDemoProfile(1);
        final rng = Random(g.index * 7 + 1);
        t.view.physicalSize = const Size(1080, 2340);
        t.view.devicePixelRatio = 2.75;
        for (var lv = 1; lv <= levelsPerGame; lv++) {
          final q = Quest(i, QuestKind.standard, 'Fuzz', i == IslandId.observatory ? Skill.values.toList() : [islandSkill[i]!], 6, g, lv - 1);
          await t.pumpWidget(ChangeNotifierProvider.value(value: st, child: MaterialApp(theme: AppTheme.build(), home: GameScreen(quest: q, devStep: levelStep(g, lv)))));
          await t.pump(const Duration(milliseconds: 500));
          final go = find.text('Let’s go!');
          if (go.evaluate().isNotEmpty) {
            await t.ensureVisible(go.first);
            await t.tap(go.first, warnIfMissed: false);
          }
          final size = t.view.physicalSize / t.view.devicePixelRatio;
          for (var k = 0; k < 70; k++) {
            if (find.byType(GameScreen).evaluate().isEmpty) break;
            final p = Offset(20 + rng.nextDouble() * (size.width - 40), 160 + rng.nextDouble() * (size.height - 200));
            switch (rng.nextInt(4)) {
              case 0 || 1:
                await t.tapAt(p);
              case 2:
                await t.dragFrom(p, Offset((rng.nextDouble() - .5) * 400, (rng.nextDouble() - .5) * 400));
              default:
                final ok = find.text('✓');
                if (ok.evaluate().isNotEmpty) await t.tap(ok.first, warnIfMissed: false);
            }
            await t.pump(Duration(milliseconds: 100 + rng.nextInt(600)));
          }
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(seconds: 30));
        }
        FlutterError.onError = old;
        expect(errors.toSet(), isEmpty);
        t.view.reset();
      });
    }
  }
}
