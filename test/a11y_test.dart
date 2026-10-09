import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/core/assets.dart';
import 'package:wordoo/core/theme.dart';
import 'package:wordoo/screens/collection.dart';
import 'package:wordoo/screens/journal.dart';
import 'package:wordoo/screens/landing.dart';
import 'package:wordoo/screens/reports.dart';
import 'package:wordoo/screens/world_map.dart';
import 'package:wordoo/state/app_state.dart';

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));
  final screens = <String, Widget Function()>{
    'landing': () => const LandingScreen(),
    'map': () => const WorldMapScreen(),
    'journal': () => const JournalScreen(),
    'treasures': () => const CollectionScreen(),
    'dashboard': () => const ParentDashboard(),
  };
  for (final e in screens.entries) {
    testWidgets('accessibility: ${e.key}', (t) async {
      final handle = t.ensureSemantics();
      await t.runAsync(() async {
        await (FontLoader('Fredoka')..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'))).load();
        await ReadleAssets.instance.load();
      });
      final st = AppState()..loadDemoProfile(0);
      t.view.physicalSize = const Size(1080, 2340);
      t.view.devicePixelRatio = 2.75;
      await t.pumpWidget(ChangeNotifierProvider.value(value: st, child: MaterialApp(theme: AppTheme.build(), home: Material(type: MaterialType.transparency, child: e.value()))));
      for (var k = 0; k < 15; k++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
      t.view.reset();
    });
  }
}
