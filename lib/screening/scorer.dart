import 'dart:math';
import 'battery.dart';
import 'models.dart';

/// Turns item responses into subtest → construct → domain results and a screening report.
/// Rules:
///  • subtest z = accuracy z (and/or rate z) against PROVISIONAL grade-band reference values
///  • band: Strong ≥ 50th percentile, Developing 16th–50th, Needs Support < 16th
///  • DALI rule: a domain is flagged when ≥ 50 % of its measured subtests are Needs Support
///  • indicator: 0 flagged domains → Low, 1 → Some, ≥ 2 → Elevated (refer for full assessment)
/// Weight of an answer by the difficulty pool it came from (PROVISIONAL, to be calibrated on pilot data).
double tierWeight(int tier) => switch (tier) { 1 => .7, 3 => 1.3, _ => 1.0 };

class Scorer {
  static double normalCdf(double z) {
    // Abramowitz–Stegun erf approximation
    final t = 1 / (1 + .3275911 * z.abs() / sqrt2);
    final y = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - .284496736) * t + .254829592) * t * exp(-z * z / 2);
    return z >= 0 ? .5 * (1 + y) : .5 * (1 - y);
  }

  static ScreenBand bandOf(double pct) => pct >= 50 ? ScreenBand.strong : (pct >= 16 ? ScreenBand.developing : ScreenBand.needsSupport);

  static SubtestResult scoreSubtest(SubtestDef def, List<ItemResponse> rs, GradeBand band) {
    final m = rs.where((r) => r.measured).toList();
    if (m.isEmpty) {
      return SubtestResult(id: def.id, construct: def.construct, accuracy: 0, z: 0, percentile: 0, band: ScreenBand.notMeasured, items: rs.length, measured: false);
    }
    // Adaptive screening: a right answer in the hard pool says more than one in the easy pool, so each answer is weighted by
    // its pool (easy 0.7, medium 1.0, hard 1.3). With every answer in the medium pool this is the plain average.
    double w(ItemResponse r) => tierWeight(r.tier);
    final acc = m.map((r) => r.score * w(r)).reduce((a, b) => a + b) / m.map(w).reduce((a, b) => a + b);
    final rates = m.where((r) => r.rate != null).map((r) => r.rate!).toList();
    final rate = rates.isEmpty ? null : rates.reduce((a, b) => a + b) / rates.length;
    final n = def.norm(band);
    final zAcc = (acc - n.accMean) / n.accSd;
    double z;
    if (rate != null && n.rateMean != null && n.rateSd != null) {
      final zRate = (rate - n.rateMean!) / n.rateSd!;
      z = (1 - n.rateWeight) * zAcc + n.rateWeight * zRate;
    } else {
      z = zAcc;
    }
    z = z.clamp(-3.0, 3.0);
    final pct = (normalCdf(z) * 100).roundToDouble();
    final tags = <String>[for (final r in m) if (r.tag != null && r.tag != 'discontinued') r.tag!];
    return SubtestResult(id: def.id, construct: def.construct, accuracy: acc, rate: rate, z: z, percentile: pct, band: bandOf(pct), items: rs.length, tags: tags);
  }

  static ScreeningReport build({
    required Map<String, List<ItemResponse>> responses,
    required GradeBand band,
    required String lang,
    required String pool,
    required Background bg,
    required bool speechAvailable,
    required int minutes,
  }) {
    final subs = <SubtestResult>[];
    for (final def in battery) {
      if (def.count(band) == 0) continue;
      subs.add(scoreSubtest(def, responses[def.id] ?? const [], band));
    }
    // constructs
    final constructs = <ConstructResult>[];
    for (final c in Construct.values) {
      final s = subs.where((x) => x.construct == c && x.measured).toList();
      if (s.isEmpty) {
        constructs.add(ConstructResult(c, 0, ScreenBand.notMeasured, const []));
        continue;
      }
      final z = s.map((x) => x.z).reduce((a, b) => a + b) / s.length;
      final pct = (normalCdf(z) * 100).roundToDouble();
      constructs.add(ConstructResult(c, pct, bandOf(pct), s.map((x) => x.id).toList()));
    }
    // domains (DALI rule)
    final flags = <Domain, bool>{};
    for (final d in Domain.values) {
      final s = subs.where((x) => x.measured && constructDomain[x.construct] == d).toList();
      if (s.isEmpty) {
        flags[d] = false;
        continue;
      }
      final low = s.where((x) => x.band == ScreenBand.needsSupport).length;
      flags[d] = low / s.length >= .5;
    }
    final nFlag = flags.values.where((v) => v).length;
    final nNeeds = constructs.where((c) => c.band == ScreenBand.needsSupport).length;
    final indicator = nFlag >= 2 ? Indicator.elevated : ((nFlag == 1 || nNeeds >= 2) ? Indicator.some : Indicator.low);

    final strengths = [for (final c in constructs) if (c.band == ScreenBand.strong) constructNames[c.construct]!];
    final needs = [for (final c in constructs) if (c.band == ScreenBand.needsSupport) constructNames[c.construct]!];
    return ScreeningReport(
      date: DateTime.now(),
      lang: lang,
      band: band,
      pool: pool,
      indicator: indicator,
      domainFlags: flags,
      constructs: constructs,
      subtests: subs,
      observations: observe(subs, constructs, band, bg, lang, speechAvailable),
      strengths: strengths,
      needs: needs,
      minutes: minutes,
      speechAvailable: speechAvailable,
    );
  }

  static List<String> observe(List<SubtestResult> subs, List<ConstructResult> cons, GradeBand band, Background bg, String lang, bool speech) {
    final o = <String>[];
    SubtestResult? s(String id) => subs.where((x) => x.id == id && x.measured).firstOrNull;
    ScreenBand b(Construct c) => cons.firstWhere((x) => x.construct == c).band;

    final word = s('wordReading'), non = s('nonwordReading');
    if (word != null) o.add('Read ${(word.accuracy * 100).round()}% of the word list correctly.');
    if (word != null && non != null && word.accuracy - non.accuracy >= .3) {
      o.add('Familiar words were read much better than new (made-up) words — sounding out unfamiliar words needs practice.');
    }
    final orf = s('oralReading');
    if (orf != null && orf.rate != null) {
      final n = subtestById('oralReading').norm(band).rateMean!;
      o.add('Read aloud at about ${orf.rate!.round()} words correct per minute (typical for this class: about ${n.round()}).');
    }
    final ran = s('ran');
    if (ran != null && ran.rate != null && ran.band == ScreenBand.needsSupport) {
      o.add('Naming familiar pictures quickly took longer than expected (${ran.rate!.toStringAsFixed(2)} per second).');
    }
    final lis = s('listening'), rc = s('readingComp');
    if (lis != null && rc != null && lis.band == ScreenBand.strong && rc.band != ScreenBand.strong) {
      o.add('Understood the story well when listening, but less when reading — reading the words is the main hurdle, not understanding.');
    }
    final sp = s('spelling');
    if (sp != null && sp.tags.isNotEmpty) {
      final top = _mostCommon(sp.tags);
      o.add('Most common spelling slip: ${top.toLowerCase()}.');
    }
    if (b(Construct.phonological) == ScreenBand.needsSupport) o.add('Hearing and changing sounds inside words needs support — this is a key early reading skill.');
    if (!speech) o.add('Voice activities were not measured on this device, so reading-aloud skills are not included.');
    // context notes (DALI: interpret against language exposure)
    final testLang = lang == 'hi' ? 'Hindi' : 'English';
    if (!bg.schoolMedium.toLowerCase().contains(testLang.toLowerCase()) && !bg.homeLanguage.toLowerCase().contains(testLang.toLowerCase())) {
      o.add('Tested in $testLang, which is neither the home language nor the school medium — lower scores may reflect less exposure.');
    }
    if (bg.yearsInSchool < 1) o.add('Less than one year of school so far — interpret literacy scores with care.');
    if (!bg.visionChecked || !bg.hearingChecked) o.add('Please get vision and hearing checked; these can affect reading.');
    if (bg.speechDelay) o.add('Early speech delay was reported — oral language results matter more here.');
    if (bg.familyHistory) o.add('A family history of reading difficulty was reported — keep a close watch on progress.');
    return o;
  }

  static String _mostCommon(List<String> t) {
    final m = <String, int>{};
    for (final x in t) {
      m[x] = (m[x] ?? 0) + 1;
    }
    return (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }
}

String indicatorLabel(Indicator i) => switch (i) {
      Indicator.low => 'Low indicators',
      Indicator.some => 'Some indicators',
      Indicator.elevated => 'Elevated indicators',
    };

String indicatorAdvice(Indicator i) => switch (i) {
      Indicator.low => 'No consistent difficulty was seen. Keep reading together and check in each week.',
      Indicator.some => 'Some skills need extra practice. Wordoo will focus on them; watch progress at the weekly check-in.',
      Indicator.elevated =>
        'Consistent difficulty was seen in two or more areas. Please consider a full assessment by a qualified professional (for example an educational psychologist using DALI-DAB or the NIMHANS SLD battery).',
    };

String bandLabel(ScreenBand b) => switch (b) {
      ScreenBand.strong => 'Strong',
      ScreenBand.developing => 'Developing',
      ScreenBand.needsSupport => 'Needs Support',
      ScreenBand.notMeasured => 'Not measured',
    };
