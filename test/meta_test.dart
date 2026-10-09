import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/engine/campaign.dart';
import 'package:wordoo/engine/meta.dart';
import 'package:wordoo/state/app_state.dart';
import 'flow_test.dart' show playQuest;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('collections: 6 games × 12 items, thresholds rise and new items keep coming', () {
    expect(collections.length, 6);
    for (final c in collections) {
      expect(c.items.length, 12);
      final at = c.items.map((i) => i.at).toList();
      for (var k = 1; k < at.length; k++) {
        expect(at[k], greaterThan(at[k - 1]));
      }
      expect(c.unlockedAt(0), isEmpty);
      expect(c.nextAt(0), c.items.first);
      expect(c.nextAt(1000), isNull);
    }
  });

  test('cosy streak: flowers never go down; a single rain day keeps the run', () {
    final d = DateTime(2026, 10, 9);
    expect(CozyStreak.from({}).flowers, 0);
    final s1 = CozyStreak.from({'2026-10-06', '2026-10-07', '2026-10-09'}, today: d);
    expect(s1.flowers, 3);
    expect(s1.run, 3, reason: 'one missed day is a rain day');
    expect(s1.rainDayUsed, isTrue);
    final s2 = CozyStreak.from({'2026-10-01', '2026-10-02', '2026-10-08', '2026-10-09'}, today: d);
    expect(s2.flowers, 4);
    expect(s2.run, 2, reason: 'a long break starts a new run but keeps every flower');
    final s3 = CozyStreak.from({'2026-10-01', '2026-10-02'}, today: d);
    expect(s3.flowers, 2);
    expect(s3.run, 0);
  });

  test('a long play-through earns gems, gifts for effort, collection items and teasers', () async {
    final st = AppState()..loadDemoProfile(0);
    final rng = Random(5);
    var gemsSeen = 0, giftsSeen = 0, itemsSeen = 0, teasers = 0;
    for (var k = 0; k < 120 && IslandId.values.where(st.campaign.chapterDone).length < 3; k++) {
      final q = st.board.first;
      final o = playQuest(st, q, rng, p: .65);
      if (o.gem != null) {
        gemsSeen++;
        expect(o.chapterComplete, isTrue);
        expect(st.gems, contains(gemId(st.campaign.season, o.gem!)));
      }
      if (o.gift != null) giftsSeen++;
      itemsSeen += o.newItems.length;
      if (o.teaser != null) teasers++;
    }
    expect(gemsSeen, greaterThanOrEqualTo(1));
    expect(giftsSeen, greaterThanOrEqualTo(1), reason: 'mistakes worked through add up to gifts');
    expect(st.effort, lessThan(giftEvery));
    expect(itemsSeen, greaterThan(3));
    expect(teasers, greaterThan(0));
    expect(st.playDays.length, 1, reason: 'all in one day');
    // persistence round-trip
    final again = AppState();
    await again.load();
    expect(again.gems, st.gems);
    expect(again.gifts, st.gifts);
    expect(again.bandStickers, st.bandStickers);
    expect(again.playDays, st.playDays);
  });

  test('every island has a gem and a voiced teaser line', () async {
    for (final i in IslandId.values) {
      expect(islandGem[i], isNotNull);
      expect(teaserLineId(i), 'tease_${i.name}');
    }
  });
}
