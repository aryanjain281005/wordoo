import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/core/assets.dart';
import 'package:wordoo/core/theme.dart';
import 'package:wordoo/engine/campaign.dart';
import 'package:wordoo/engine/levels.dart';
import 'package:wordoo/models/models.dart';
import 'package:wordoo/screens/avatar_creator.dart';
import 'package:wordoo/screens/collection.dart';
import 'package:wordoo/screens/explorer_room.dart';
import 'package:wordoo/screens/game_screen.dart';
import 'package:wordoo/screens/journal.dart';
import 'package:wordoo/screens/landing.dart';
import 'package:wordoo/screens/library.dart';
import 'package:wordoo/screens/reports.dart';
import 'package:wordoo/screens/skill_map.dart';
import 'package:wordoo/screens/world_map.dart';
import 'package:wordoo/state/app_state.dart';

/// Layout check (Phase 7): every screen and every game, on a small phone and with large text, must lay out
/// without overflowing. Release builds silently clip overflows, so they are only caught here.
void main() {
  late AppState st;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> boot(WidgetTester t) async {
    await t.runAsync(() async {
      await (FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
      await WordooAssets.instance.load();
    });
    st = AppState()..loadDemoProfile(0);
    st.explorerName = 'Aaravkrishnan'; // long name on purpose
  }

  const sizes = [Size(360, 640), Size(412, 915)];
  const scales = [1.0, 1.3];

  Future<List<String>> pumpAt(WidgetTester t, Widget w, Size size, double scale, {int ms = 1500}) async {
    final errors = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      final s = d.exceptionAsString();
      final where = d.toString().split('\n').where((x) => x.contains('creator') || x.contains('.dart')).take(3).join(' | ');
      if (s.contains('overflowed') || s.contains('RenderFlex') || s.contains('was not laid out')) errors.add('${s.split('\n').first} @ $where');
    };
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    await t.pumpWidget(ChangeNotifierProvider.value(
      value: st,
      child: MaterialApp(
        theme: AppTheme.build(),
        home: MediaQuery(data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)), child: w),
      ),
    ));
    for (var k = 0; k < ms ~/ 100; k++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    FlutterError.onError = old;
    return errors;
  }

  final screens = <String, Widget Function()>{
    'landing': () => const LandingScreen(),
    'avatar': () => const AvatarCreator(),
    'map': () => const WorldMapScreen(),
    'skill map': () => const SkillMapScreen(),
    'journal': () => const JournalScreen(),
    'treasures': () => const CollectionScreen(),
    'room': () => const ExplorerRoomScreen(),
    'library': () => const LibraryScreen(),
    'dashboard': () => const ParentDashboard(),
  };

  for (final e in screens.entries) {
    testWidgets('screen fits: ${e.key}', (t) async {
      await boot(t);
      final bad = <String>[];
      for (final size in sizes) {
        for (final sc in scales) {
          for (final err in await pumpAt(t, e.value(), size, sc)) {
            bad.add('${size.width.toInt()}x${size.height.toInt()} @${sc}x: $err');
          }
          await t.pumpWidget(const SizedBox());
        }
      }
      expect(bad, isEmpty, reason: bad.toSet().join('\n'));
      t.view.reset();
    });
  }

  for (final i in IslandId.values) {
    for (final g in islandGames(i)) {
      testWidgets('game fits: ${g.name} (intro + play, every level)', (t) async {
        await boot(t);
        final bad = <String>[];
        for (final size in sizes) {
          for (final sc in scales) {
            for (var lv = 1; lv <= levelsPerGame; lv += 3) {
              final q = Quest(i, QuestKind.standard, 'A long quest title for testing the layout', i == IslandId.observatory ? Skill.values.toList() : [islandSkill[i]!], 6, g, lv - 1);
              final key = GlobalKey();
              for (final err in await pumpAt(t, GameScreen(key: key, quest: q, devStep: levelStep(g, lv)), size, sc, ms: 800)) {
                bad.add('${size.width.toInt()}x${size.height.toInt()} @${sc}x L$lv intro: $err');
              }
              // start playing
              final go = find.text('Let’s go!');
              if (go.evaluate().isNotEmpty) {
                await t.ensureVisible(go.first);
                await t.tap(go.first, warnIfMissed: false);
                final errors = <String>[];
                final old = FlutterError.onError;
                FlutterError.onError = (d) {
                  final s = d.exceptionAsString();
                  if (s.contains('overflowed') || s.contains('was not laid out')) errors.add(s.split('\n').first);
                };
                for (var k = 0; k < 15; k++) {
                  await t.pump(const Duration(milliseconds: 100));
                }
                FlutterError.onError = old;
                bad.addAll(errors.map((x) => '${size.width.toInt()}x${size.height.toInt()} @${sc}x L$lv play: $x'));
              }
              await t.pumpWidget(const SizedBox());
              await t.pump(const Duration(seconds: 20));
            }
          }
        }
        expect(bad, isEmpty, reason: bad.toSet().join('\n'));
        t.view.reset();
      });
    }
  }
}
