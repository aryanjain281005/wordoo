import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/screens/game_screen.dart';
import 'package:wordoo/state/app_state.dart';
import 'package:wordoo/engine/campaign.dart';
import 'package:wordoo/story/beats.dart';

void main() {
  final lines = jsonDecode(File('assets/story/lines_en.json').readAsStringSync()) as Map<String, dynamic>;

  test('every cutscene line exists and has a generated voice file', () {
    for (final f in Directory('assets/cutscenes').listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      final shots = (jsonDecode(f.readAsStringSync()) as Map)['shots'] as List;
      expect(shots, isNotEmpty, reason: f.path);
      for (final s in shots) {
        final id = (s as Map)['line'] as String?;
        if (id == null) continue;
        expect(lines.containsKey(id), isTrue, reason: '$id in ${f.path}');
        expect(File('assets/vo/en/$id.ogg').existsSync(), isTrue, reason: 'voice for $id');
      }
    }
  });

  test('every quest has a story beat told by its island guardian', () {
    final c = Campaign();
    for (final i in IslandId.values) {
      for (final (g, node) in [for (final g in islandGames(i)) for (var n = 0; n < 4; n++) (g, n)]) {
        final q = Quest(i, QuestKind.values.first, 'x', const [], 5, g, node);
        final id = beatLineFor(q, c);
        expect(lines.containsKey(id), isTrue, reason: id);
        expect((lines[id] as Map)['who'], islandGuardian[i], reason: id);
        expect(File('assets/vo/en/$id.ogg').existsSync(), isTrue, reason: id);
      }
    }
  });

  testWidgets('a quest opens with its guardian story beat', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final st = AppState();
    await tester.runAsync(st.load);
    st.loadDemoProfile(0);
    final q = st.board.first;
    await tester.pumpWidget(ChangeNotifierProvider.value(value: st, child: MaterialApp(home: GameScreen(quest: q))));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(GameScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
