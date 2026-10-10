import 'battery.dart';
import 'models.dart';

/// How the child answered one question, beyond right or wrong.
class ResponseQuality {
  final bool slow; // took longer than a comfortable time for this kind of task
  final bool longPause; // a long wait before speaking, or pauses while speaking
  final bool lowConfidence; // the recogniser was unsure what was said (unclear or hesitant speech)
  final bool replayed; // asked to hear the instruction again more than once
  const ResponseQuality({this.slow = false, this.longPause = false, this.lowConfidence = false, this.replayed = false});

  /// True when nothing about the way the child answered suggests effort or hesitation.
  bool get clean => !slow && !longPause && !lowConfidence && !replayed;

  List<String> get reasons => [if (slow) 'slow', if (longPause) 'long pause', if (lowConfidence) 'unclear speech', if (replayed) 'needed replays'];

  Map<String, dynamic> toJson() => {'slow': slow, 'longPause': longPause, 'lowConfidence': lowConfidence, 'replayed': replayed};
}

/// The three-pool rule of the adaptive screening (easy / medium / hard questions):
///
///  • wrong answer                                   → next question from the EASY pool
///  • right, but slow / long pause / unclear / replays → next question from the MEDIUM pool
///  • right, quick and clean                          → next question from the HARD pool
///  • partly right (speech tasks with partial credit)  → MEDIUM pool
///
/// The first question of every station comes from the MEDIUM pool. Thresholds are PROVISIONAL (to be tuned on pilot data).
class Adaptive {
  static const startTier = Tier.medium;

  /// Comfortable answering time in ms for one question of this task type; younger children (Classes 1–2) get 30 % more.
  static int slowAfterMs(TaskType t, GradeBand band) {
    final base = switch (t) {
      TaskType.picture || TaskType.audioChoice || TaskType.letterChoice || TaskType.sentencePicture => 9000,
      TaskType.tiles => 30000,
      TaskType.readAloud => 9000,
      TaskType.listening || TaskType.passage => 14000,
      TaskType.oralReading || TaskType.fluency || TaskType.ran => 1 << 30, // timed by design, never judged per question
    };
    return band == GradeBand.junior ? (base * 1.3).round() : base;
  }

  /// Looks at the answer(s) to one question (a story question has several).
  static ResponseQuality assess(List<ItemResponse> rs, SubtestDef def, GradeBand band) {
    final m = rs.where((r) => r.measured).toList();
    if (m.isEmpty) return const ResponseQuality();
    final limit = slowAfterMs(def.task, band);
    final slow = m.any((r) => r.ms > limit);
    var longPause = false, lowConf = false;
    for (final r in m) {
      final sp = r.speech;
      if (sp == null) continue;
      // waiting more than 3.5 s before the first sound, 2 or more pauses, or 1.2 s+ of silence inside the answer
      if (sp.latencyMs > 3500 || sp.pauses >= 2 || sp.pauseMs > 1200) longPause = true;
      if (sp.transcript.isNotEmpty && sp.confidence > 0 && sp.confidence < .5) lowConf = true;
    }
    return ResponseQuality(slow: slow, longPause: longPause, lowConfidence: lowConf, replayed: m.any((r) => r.replays >= 2));
  }

  /// Mean score of the answers to one question (0..1).
  static double score(List<ItemResponse> rs) {
    final m = rs.where((r) => r.measured).toList();
    return m.isEmpty ? 1 : m.map((r) => r.score).reduce((a, b) => a + b) / m.length;
  }

  /// The pool the NEXT question comes from.
  static Tier next(List<ItemResponse> rs, ResponseQuality q) {
    final s = score(rs);
    if (s < .5) return Tier.easy;
    if (s < .99 || !q.clean) return Tier.medium;
    return Tier.hard;
  }

  /// Picks the next question: from [tier] if the pool still has one, otherwise the nearest pool.
  /// Prefers this cycle's form (A/B), then the question the child has met least often.
  static SItem? pick(List<SItem> candidates, Tier tier, {required Set<String> used, required String form, Map<String, int> seen = const {}}) {
    final free = candidates.where((i) => !used.contains(i.id)).toList();
    if (free.isEmpty) return null;
    for (final d in _byDistance(tier)) {
      final pool = free.where((i) => i.tier == d).toList();
      if (pool.isEmpty) continue;
      pool.sort((a, b) {
        final sa = seen[a.id] ?? 0, sb = seen[b.id] ?? 0;
        if (sa != sb) return sa.compareTo(sb);
        if (a.pool != b.pool) return a.pool == form ? -1 : 1;
        // generated questions are fresh for the child: they go before the shipped ones that were already met
        if (a.source != b.source) return a.source == 'seed' ? 1 : -1;
        return a.id.compareTo(b.id);
      });
      return pool.first;
    }
    return null;
  }

  static List<Tier> _byDistance(Tier t) => switch (t) {
        Tier.easy => [Tier.easy, Tier.medium, Tier.hard],
        Tier.medium => [Tier.medium, Tier.easy, Tier.hard],
        Tier.hard => [Tier.hard, Tier.medium, Tier.easy],
      };
}

/// One step of the adaptive path (kept for the report and for the cloud telemetry).
class TraceStep {
  final String subtest, itemId;
  final Tier tier; // the pool this question came from
  final double score;
  final int ms;
  final ResponseQuality quality;
  final Tier nextTier; // the pool the next question was drawn from
  const TraceStep({required this.subtest, required this.itemId, required this.tier, required this.score, required this.ms, required this.quality, required this.nextTier});
  Map<String, dynamic> toJson() => {'subtest': subtest, 'itemId': itemId, 'tier': tier.name, 'score': score, 'ms': ms, 'quality': quality.toJson(), 'nextTier': nextTier.name};
}
