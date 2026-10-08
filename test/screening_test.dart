import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordoo/screening/bank.dart';
import 'package:wordoo/screening/battery.dart';
import 'package:wordoo/screening/models.dart';
import 'package:wordoo/screening/scorer.dart';
import 'package:wordoo/screening/ui/screening_screen.dart';
import 'package:wordoo/screening/voxlexi.dart';
import 'package:wordoo/state/app_state.dart';

void main() {
  test('every subtest has enough fresh items for both forms, both bands, both languages', () {
    for (final lang in ['en', 'hi']) {
      final bank = bankFor(lang);
      for (final band in GradeBand.values) {
        for (final def in battery) {
          final n = def.count(band);
          if (n == 0) continue;
          for (final pool in ['A', 'B']) {
            final items = bank.forSubtest(def.id, pool, band);
            expect(items.length, greaterThanOrEqualTo(n), reason: '$lang ${def.id} $pool $band has ${items.length} < $n');
          }
          final a = bank.forSubtest(def.id, 'A', band).map((i) => i.target ?? i.passage ?? i.id).toSet();
          final b = bank.forSubtest(def.id, 'B', band).map((i) => i.target ?? i.passage ?? i.id).toSet();
          if (def.id != 'ran') expect(a.intersection(b).where((x) => !x.startsWith('ran')), isEmpty, reason: '$lang ${def.id} A/B overlap');
        }
      }
      for (final it in bank.items.where((i) => i.subtest == 'spelling')) {
        expect(it.answer.join(), it.target, reason: '$lang spelling ${it.target}');
      }
      for (final it in bank.items.where((i) => i.options.isNotEmpty && i.subtest != 'ran')) {
        expect(it.correct, lessThan(it.options.length));
        expect(it.options.map((o) => o.label).toSet().length, it.options.length, reason: '$lang ${it.id} duplicate options');
      }
    }
  });

  group('VoxLexi port', () {
    test('matching is fuzzy and phonetic', () {
      expect(VoxLexi.similarity('cat', 'Cat.'), 1);
      expect(VoxLexi.phoneticEn('kat'), VoxLexi.phoneticEn('cat'));
      const m = SpeechMetrics(transcript: 'fab', alternates: ['fap', 'fab']);
      expect(VoxLexi.scoreFromMatch(VoxLexi.bestMatch('fap', m, phonetic: true), nonword: true), 1);
      const wrong = SpeechMetrics(transcript: 'elephant');
      expect(VoxLexi.scoreFromMatch(VoxLexi.bestMatch('dog', wrong)), 0);
      expect(VoxLexi.similarity('पानी', 'पानी'), 1);
      expect(VoxLexi.similarity('चाँद', 'चांद'), 1); // chandrabindu ~ anusvara
    });

    test('sequence alignment counts correct / missing words', () {
      final r = VoxLexi.compareSequences('The cat sat on a mat', 'the cat on a mat');
      expect(r.correct, 5);
      expect(r.items.where((e) => e.$2 == 'missing').length, 1);
    });

    test('pause detection from the sound-level stream', () {
      final levels = <(int, double)>[];
      for (var t = 0; t < 4000; t += 50) {
        final speaking = (t > 300 && t < 1500) || (t > 2200 && t < 3500);
        levels.add((t, speaking ? 8.0 : -1.0));
      }
      final m = VoxLexi.analyzeLevels(levels);
      expect(m.pauses, 1);
      expect(m.pauseMs, greaterThanOrEqualTo(600));
      expect(m.latencyMs, inInclusiveRange(300, 400));
    });

    test('fluency risk rises when reading is slow and broken', () {
      final ok = VoxLexi.fluencyRisk(actualSec: 20, expectedSec: 20, pauses: 1, pauseSec: .5);
      final slow = VoxLexi.fluencyRisk(actualSec: 45, expectedSec: 20, pauses: 9, pauseSec: 10);
      expect(slow, greaterThan(ok));
      expect(slow, greaterThan(.66));
    });

    test('category counting and rapid naming', () {
      final c = VoxLexi.countCategory('dog cat elephant lion dog tiger', const [], bankFor('en').animals);
      expect(c.count, 5);
      final acc = VoxLexi.ranAccuracy('dog sun apple house star', ['dog', 'sun', 'apple', 'house', 'star'], ['dog', 'sun', 'apple', 'house', 'star']);
      expect(acc, 1);
    });
  });

  group('scoring', () {
    Map<String, List<ItemResponse>> all(double score, {double rateFactor = 1}) => {
          for (final d in battery)
            d.id: [
              ItemResponse(
                itemId: d.id,
                subtest: d.id,
                score: score,
                ms: 1000,
                rate: d.normJunior.rateMean == null ? null : d.normJunior.rateMean! * rateFactor,
              )
            ],
        };

    test('strong performance → low indicator, all strong', () {
      final r = Scorer.build(responses: all(1, rateFactor: 1.4), band: GradeBand.junior, lang: 'en', pool: 'A', bg: Background(schoolMedium: 'English'), speechAvailable: true, minutes: 15);
      expect(r.indicator, Indicator.low);
      expect(r.constructs.every((c) => c.band == ScreenBand.strong), isTrue);
    });

    test('weak performance across domains → elevated indicator (DALI rule)', () {
      final r = Scorer.build(responses: all(.1, rateFactor: .3), band: GradeBand.junior, lang: 'en', pool: 'A', bg: Background(schoolMedium: 'English'), speechAvailable: true, minutes: 15);
      expect(r.indicator, Indicator.elevated);
      expect(r.domainFlags.values.where((v) => v).length, greaterThanOrEqualTo(2));
      expect(indicatorAdvice(r.indicator), contains('assessment'));
    });

    test('speech not available → speaking skills "not measured", never guessed', () {
      final resp = all(1);
      for (final d in battery.where((d) => d.speech)) {
        resp[d.id] = [ItemResponse(itemId: d.id, subtest: d.id, score: 0, ms: 0, measured: false)];
      }
      final r = Scorer.build(responses: resp, band: GradeBand.junior, lang: 'en', pool: 'A', bg: Background(schoolMedium: 'English'), speechAvailable: false, minutes: 10);
      expect(r.of(Construct.decoding)!.band, ScreenBand.notMeasured);
      expect(r.observations.any((o) => o.contains('not measured')), isTrue);
    });

    test('screening sets independent starting levels', () {
      SharedPreferences.setMockInitialValues({});
      final st = AppState()..grade = 'Class 1';
      final resp = all(1, rateFactor: 1.4);
      resp['spelling'] = [const ItemResponse(itemId: 's', subtest: 'spelling', score: 0, ms: 900, tag: 'Wrong vowel')];
      final r = Scorer.build(responses: resp, band: GradeBand.junior, lang: 'en', pool: 'A', bg: Background(schoolMedium: 'English'), speechAvailable: true, minutes: 15);
      st.completeScreening(r, resp);
      expect(st.screenings.length, 1);
      expect(st.skills.values.map((s) => s.level).toSet().length, greaterThan(1));
      expect(st.skills.entries.firstWhere((e) => e.key.name == 'spelling').value.level, 1);
      expect(st.screen, AppScreen.skillMap);
    });
  });

  testWidgets('screening flow starts and shows the first station', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final st = AppState()..grade = 'Class 1';
    await tester.pumpWidget(ChangeNotifierProvider.value(value: st, child: const MaterialApp(home: Scaffold(body: ScreeningScreen()))));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Rhyme Time'), findsWidgets);
    await tester.tap(find.text('Go!'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('rhymes with'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });
}
