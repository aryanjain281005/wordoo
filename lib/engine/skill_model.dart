import 'dart:math';
import '../core/config.dart';

enum SkillStatus { calibrating, struggling, steady, improving, ready }

/// Per-skill learner model. Lightweight Elo / 1-parameter IRT:
///   expected = 1 / (1 + e^-(θ − b))      θ = ability, b = item difficulty (both on the 1–10 step scale)
///   θ ← θ + K · (result − expected)
/// The served step keeps the expected success rate near [Cfg.targetSuccess].
class SkillModel {
  double theta;
  double rtMs; // smoothed response time
  double recentAcc; // smoothed accuracy
  Map<String, double> errors; // decaying error-tag weights
  List<double> history; // θ at the end of each round
  int items; // all items ever
  int cycleItems; // items in the current assessment cycle
  int calibrationLeft; // rounds that still allow big jumps
  int missRun;

  SkillModel({
    this.theta = 3,
    this.rtMs = 3000,
    this.recentAcc = .75,
    Map<String, double>? errors,
    List<double>? history,
    this.items = 0,
    this.cycleItems = 0,
    this.calibrationLeft = Cfg.calibrationRounds,
    this.missRun = 0,
  })  : errors = errors ?? {},
        history = history ?? [];

  /// Starting ability from a screening percentile (the screening really decides where play begins).
  factory SkillModel.fromScreening(double percentile, {bool measured = true}) {
    final step = startStepFor(percentile);
    return SkillModel(theta: step + _offset, calibrationLeft: measured ? Cfg.calibrationRounds : Cfg.calibrationRounds + 2);
  }

  static double get _offset => log(Cfg.targetSuccess / (1 - Cfg.targetSuccess)); // ≈ 1.27 for 78 %

  static int startStepFor(double pct) {
    for (final (limit, step) in Cfg.startStepTable) {
      if (pct < limit) return step;
    }
    return Cfg.startStepTable.last.$2;
  }

  /// Step to serve now (difficulty that gives ≈ target success).
  int get step => (theta - _offset).round().clamp(Cfg.minStep, Cfg.maxStep);

  /// 4 broad bands for simple UI (power pips).
  int get band => ((step - 1) ~/ 3 + 1).clamp(1, 4);

  double expected(double b) => 1 / (1 + exp(-(theta - b)));

  /// Update after one answer. [score] 0..1, [b] item difficulty, [ms] response time.
  void update(double score, double b, {int ms = 0, String? tag}) {
    final k = calibrationLeft > 0 ? Cfg.kCalibration : Cfg.kNormal;
    theta = (theta + k * (score - expected(b))).clamp(.5, 11.5);
    recentAcc = recentAcc * .8 + score * .2;
    if (ms > 0) rtMs = rtMs * .8 + ms * .2;
    // error memory: every answer fades old errors a little; a new error adds weight
    errors.updateAll((_, v) => v * Cfg.errorDecay);
    errors.removeWhere((_, v) => v < .15);
    if (tag != null && score < 1) errors[tag] = (errors[tag] ?? 0) + 1;
    missRun = score < .5 ? missRun + 1 : 0;
    items++;
    cycleItems++;
  }

  void endRound() {
    history.add(theta);
    if (history.length > 30) history.removeAt(0);
    if (calibrationLeft > 0) calibrationLeft--;
  }

  /// Error tags that happen repeatedly (not one-off slips).
  List<String> get focusErrors => (errors.entries.where((e) => e.value >= Cfg.errorFocusAt).toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) => e.key).take(2).toList();

  double get trend {
    if (history.length < 3) return 0;
    final h = history.sublist(max(0, history.length - 5));
    return (h.last - h.first) / (h.length - 1);
  }

  /// "Right but slow": accurate yet much slower than the fluency target.
  bool get slowButAccurate => recentAcc >= .8 && rtMs > Cfg.slowRtMs;

  bool get stable {
    if (history.length < 3) return false;
    final h = history.sublist(history.length - 3);
    return h.reduce(max) - h.reduce(min) < Cfg.stableRange;
  }

  SkillStatus get status {
    if (calibrationLeft > 0) return SkillStatus.calibrating;
    if (recentAcc < .55 || missRun >= 2) return SkillStatus.struggling;
    if (recentAcc >= .88 && trend >= 0 && !slowButAccurate) return SkillStatus.ready;
    if (trend > .15) return SkillStatus.improving;
    return SkillStatus.steady;
  }

  bool get needsScaffold => missRun >= Cfg.missesToScaffold || status == SkillStatus.struggling;

  Map<String, dynamic> toJson() => {
        'theta': theta,
        'rt': rtMs,
        'acc': recentAcc,
        'errors': errors,
        'history': history,
        'items': items,
        'cycleItems': cycleItems,
        'cal': calibrationLeft,
        'missRun': missRun,
      };

  factory SkillModel.fromJson(Map<String, dynamic> j) => SkillModel(
        theta: (j['theta'] as num).toDouble(),
        rtMs: (j['rt'] as num).toDouble(),
        recentAcc: (j['acc'] as num).toDouble(),
        errors: (j['errors'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        history: [for (final x in j['history'] as List) (x as num).toDouble()],
        items: j['items'] as int,
        cycleItems: j['cycleItems'] as int,
        calibrationLeft: j['cal'] as int,
        missRun: j['missRun'] as int? ?? 0,
      );
}

String statusLabel(SkillStatus s) => switch (s) {
      SkillStatus.calibrating => 'Finding the right level',
      SkillStatus.struggling => 'Needs extra support',
      SkillStatus.steady => 'Practising steadily',
      SkillStatus.improving => 'Improving',
      SkillStatus.ready => 'Ready for a challenge',
    };
