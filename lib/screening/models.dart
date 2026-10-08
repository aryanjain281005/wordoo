/// Screening data model — DALI-aligned constructs, scored by the app (no adult scoring).
library;

enum Construct { phonological, gpc, decoding, wordRecognition, spelling, comprehension, oralLanguage, rapidNaming }

/// DALI groups its tests into three domains.
enum Domain { phonologicalProcessing, literacy, semanticRetrieval }

enum TaskType { picture, audioChoice, letterChoice, tiles, readAloud, ran, fluency, listening, sentencePicture, passage, oralReading }

enum GradeBand { junior, middle } // DALI JST (Classes 1–2) / MST (Classes 3–5)

enum Indicator { low, some, elevated }

enum ScreenBand { strong, developing, needsSupport, notMeasured }

class ChoiceOpt {
  final String label;
  final String? emoji;
  final String? say;
  const ChoiceOpt(this.label, {this.emoji, this.say});
}

class Question {
  final String q;
  final List<ChoiceOpt> options;
  final int correct;
  final String tag;
  const Question(this.q, this.options, this.correct, {this.tag = 'Wrong detail'});
}

/// One screening item. Every item belongs to pool A (baseline) or B (weekly check) for fresh-item testing.
class SItem {
  final String id;
  final String subtest;
  final String pool; // 'A' or 'B'
  final int difficulty; // 1..3
  final String? target; // word / sound / expected speech
  final String? emoji;
  final String? say; // spoken stimulus
  final List<ChoiceOpt> options;
  final int correct;
  final List<String> accept; // acceptable spoken variants (picture naming / RAN)
  final List<String> answer; // spelling units
  final List<String> distractors; // spelling extra tiles
  final String? passage;
  final List<Question> questions;
  final GradeBand? only; // restrict to a band
  const SItem({
    required this.id,
    required this.subtest,
    required this.pool,
    this.difficulty = 1,
    this.target,
    this.emoji,
    this.say,
    this.options = const [],
    this.correct = 0,
    this.accept = const [],
    this.answer = const [],
    this.distractors = const [],
    this.passage,
    this.questions = const [],
    this.only,
  });
}

/// Measurements from one spoken response (VoxLexi-style).
class SpeechMetrics {
  final String transcript;
  final List<String> alternates;
  final double confidence;
  final int durationMs; // speech onset → offset
  final int latencyMs; // mic open → speech onset
  final int pauses;
  final int pauseMs;
  const SpeechMetrics({
    this.transcript = '',
    this.alternates = const [],
    this.confidence = 0,
    this.durationMs = 0,
    this.latencyMs = 0,
    this.pauses = 0,
    this.pauseMs = 0,
  });
  Map<String, dynamic> toJson() => {
        'transcript': transcript,
        'confidence': confidence,
        'durationMs': durationMs,
        'latencyMs': latencyMs,
        'pauses': pauses,
        'pauseMs': pauseMs,
      };
}

class ItemResponse {
  final String itemId;
  final String subtest;
  final double score; // 0..1 (partial credit allowed for speech)
  final int ms;
  final int replays;
  final String? tag;
  final SpeechMetrics? speech;
  final bool measured; // false when the device could not capture speech
  final double? rate; // task-specific rate (items/sec, words/min, count)
  const ItemResponse({
    required this.itemId,
    required this.subtest,
    required this.score,
    required this.ms,
    this.replays = 0,
    this.tag,
    this.speech,
    this.measured = true,
    this.rate,
  });
  bool get correct => score >= .99;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'subtest': subtest,
        'score': score,
        'ms': ms,
        'replays': replays,
        'tag': tag,
        'measured': measured,
        'rate': rate,
        if (speech != null) 'speech': speech!.toJson(),
      };
}

class SubtestResult {
  final String id;
  final Construct construct;
  final double accuracy; // 0..1
  final double? rate; // e.g. WCPM, items/sec, count
  final double z;
  final double percentile;
  final ScreenBand band;
  final int items;
  final bool measured;
  final List<String> tags;
  const SubtestResult({
    required this.id,
    required this.construct,
    required this.accuracy,
    this.rate,
    required this.z,
    required this.percentile,
    required this.band,
    required this.items,
    this.measured = true,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'construct': construct.index,
        'accuracy': accuracy,
        'rate': rate,
        'z': z,
        'percentile': percentile,
        'band': band.index,
        'items': items,
        'measured': measured,
        'tags': tags,
      };
  factory SubtestResult.fromJson(Map<String, dynamic> j) => SubtestResult(
        id: j['id'] as String,
        construct: Construct.values[j['construct'] as int],
        accuracy: (j['accuracy'] as num).toDouble(),
        rate: (j['rate'] as num?)?.toDouble(),
        z: (j['z'] as num).toDouble(),
        percentile: (j['percentile'] as num).toDouble(),
        band: ScreenBand.values[j['band'] as int],
        items: j['items'] as int,
        measured: j['measured'] as bool? ?? true,
        tags: List<String>.from(j['tags'] as List? ?? const []),
      );
}

class ConstructResult {
  final Construct construct;
  final double percentile; // 0..100 — used as the skill score
  final ScreenBand band;
  final List<String> subtests;
  const ConstructResult(this.construct, this.percentile, this.band, this.subtests);
  Map<String, dynamic> toJson() => {'c': construct.index, 'p': percentile, 'b': band.index, 's': subtests};
  factory ConstructResult.fromJson(Map<String, dynamic> j) =>
      ConstructResult(Construct.values[j['c'] as int], (j['p'] as num).toDouble(), ScreenBand.values[j['b'] as int], List<String>.from(j['s'] as List));
}

class ScreeningReport {
  final DateTime date;
  final String lang;
  final GradeBand band;
  final String pool;
  final Indicator indicator;
  final Map<Domain, bool> domainFlags;
  final List<ConstructResult> constructs;
  final List<SubtestResult> subtests;
  final List<String> observations;
  final List<String> strengths;
  final List<String> needs;
  final int minutes;
  final bool speechAvailable;
  const ScreeningReport({
    required this.date,
    required this.lang,
    required this.band,
    required this.pool,
    required this.indicator,
    required this.domainFlags,
    required this.constructs,
    required this.subtests,
    required this.observations,
    required this.strengths,
    required this.needs,
    required this.minutes,
    required this.speechAvailable,
  });

  ConstructResult? of(Construct c) {
    for (final r in constructs) {
      if (r.construct == c) return r;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'lang': lang,
        'band': band.index,
        'pool': pool,
        'indicator': indicator.index,
        'domains': domainFlags.map((k, v) => MapEntry(k.index.toString(), v)),
        'constructs': constructs.map((c) => c.toJson()).toList(),
        'subtests': subtests.map((s) => s.toJson()).toList(),
        'observations': observations,
        'strengths': strengths,
        'needs': needs,
        'minutes': minutes,
        'speech': speechAvailable,
      };

  factory ScreeningReport.fromJson(Map<String, dynamic> j) => ScreeningReport(
        date: DateTime.parse(j['date'] as String),
        lang: j['lang'] as String,
        band: GradeBand.values[j['band'] as int],
        pool: j['pool'] as String,
        indicator: Indicator.values[j['indicator'] as int],
        domainFlags: (j['domains'] as Map).map((k, v) => MapEntry(Domain.values[int.parse(k as String)], v as bool)),
        constructs: (j['constructs'] as List).map((e) => ConstructResult.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        subtests: (j['subtests'] as List).map((e) => SubtestResult.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        observations: List<String>.from(j['observations'] as List),
        strengths: List<String>.from(j['strengths'] as List),
        needs: List<String>.from(j['needs'] as List),
        minutes: j['minutes'] as int,
        speechAvailable: j['speech'] as bool? ?? true,
      );
}

/// Short grown-up questionnaire — needed to interpret results, not to score them.
class Background {
  String homeLanguage;
  String schoolMedium;
  int yearsInSchool;
  bool visionChecked;
  bool hearingChecked;
  bool speechDelay;
  bool familyHistory;
  bool voiceConsent;
  Background({
    this.homeLanguage = 'Hindi',
    this.schoolMedium = 'English',
    this.yearsInSchool = 1,
    this.visionChecked = true,
    this.hearingChecked = true,
    this.speechDelay = false,
    this.familyHistory = false,
    this.voiceConsent = false,
  });
  Map<String, dynamic> toJson() => {
        'home': homeLanguage,
        'school': schoolMedium,
        'years': yearsInSchool,
        'vision': visionChecked,
        'hearing': hearingChecked,
        'speechDelay': speechDelay,
        'family': familyHistory,
        'voice': voiceConsent,
      };
  factory Background.fromJson(Map<String, dynamic> j) => Background(
        homeLanguage: j['home'] as String? ?? 'Hindi',
        schoolMedium: j['school'] as String? ?? 'English',
        yearsInSchool: j['years'] as int? ?? 1,
        visionChecked: j['vision'] as bool? ?? true,
        hearingChecked: j['hearing'] as bool? ?? true,
        speechDelay: j['speechDelay'] as bool? ?? false,
        familyHistory: j['family'] as bool? ?? false,
        voiceConsent: j['voice'] as bool? ?? false,
      );
}
