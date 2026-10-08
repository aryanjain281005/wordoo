import 'dart:math';
import 'models.dart';

/// On-device port of the VoxLexi analysis pipeline (rule_based_scoring.py + text_comparison.py):
///  • pause detection from the energy / sound-level stream
///  • reading duration vs expected duration
///  • weighted fluency-risk score (0.6 time, 0.2 pause frequency, 0.2 pause duration)
///  • word-sequence alignment of transcript vs expected text (correct / wrong / missing)
/// Changes from VoxLexi: expected speed comes from grade norms (not a fixed 120–150 wpm),
/// matching is fuzzy and phonetic, and nothing here produces a "dyslexia probability".
class VoxLexi {
  // ---------------- energy / pause analysis ----------------
  static SpeechMetrics analyzeLevels(List<(int, double)> levels, {String transcript = '', List<String> alternates = const [], double confidence = 0, int minPauseMs = 300}) {
    if (levels.length < 3) {
      return SpeechMetrics(transcript: transcript, alternates: alternates, confidence: confidence);
    }
    final vals = levels.map((e) => e.$2).toList()..sort();
    double pct(double p) => vals[((vals.length - 1) * p).round()];
    final floor = pct(.2), high = pct(.9);
    final thr = floor + max(1.5, (high - floor) * .35);
    int? onset, offset;
    for (final (t, v) in levels) {
      if (v > thr) {
        onset ??= t;
        offset = t;
      }
    }
    if (onset == null || offset == null) {
      return SpeechMetrics(transcript: transcript, alternates: alternates, confidence: confidence, latencyMs: levels.last.$1);
    }
    var pauses = 0, pauseMs = 0;
    int? quietStart;
    for (final (t, v) in levels) {
      if (t < onset || t > offset) continue;
      if (v <= thr) {
        quietStart ??= t;
      } else if (quietStart != null) {
        final gap = t - quietStart;
        if (gap >= minPauseMs) {
          pauses++;
          pauseMs += gap;
        }
        quietStart = null;
      }
    }
    return SpeechMetrics(
      transcript: transcript,
      alternates: alternates,
      confidence: confidence,
      durationMs: max(0, offset - onset),
      latencyMs: onset,
      pauses: pauses,
      pauseMs: pauseMs,
    );
  }

  /// VoxLexi `compute_fluency_risk_score`, with grade-based expected duration.
  static double fluencyRisk({required double actualSec, required double expectedSec, required int pauses, required double pauseSec}) {
    double c(double x) => x.isFinite ? x.clamp(0.0, 1.0) : 0.0;
    final timeRisk = expectedSec <= 1e-6 ? 0.0 : c((actualSec - expectedSec) / expectedSec);
    final minutes = max(actualSec / 60.0, 1e-3);
    final freqRisk = c((pauses / minutes - 2.0) / 8.0);
    final durRisk = c((pauseSec / max(actualSec, 1e-6)) / .25);
    return c(.6 * timeRisk + .2 * freqRisk + .2 * durRisk);
  }

  // ---------------- text normalisation & matching ----------------
  static final _latin = RegExp(r"[^a-z\s]");
  static String _normEn(String s) => s.toLowerCase().replaceAll(_latin, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _normHi(String s) {
    var t = s.replaceAll('़', '').replaceAll('ँ', 'ं').replaceAll(RegExp(r'[।,.!?"“”‘’\-]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  static bool _isDevanagari(String s) => s.runes.any((r) => r >= 0x0900 && r <= 0x097F);

  static String normalize(String s) => _isDevanagari(s) ? _normHi(s) : _normEn(s);

  /// Phonetic key for English so "fap" ~ "fab", "kat" ~ "cat".
  static String phoneticEn(String w) {
    var s = _normEn(w).replaceAll(' ', '');
    if (s.isEmpty) return s;
    s = s
        .replaceAll('ph', 'f')
        .replaceAll('ck', 'k')
        .replaceAll('qu', 'kw')
        .replaceAll('q', 'k')
        .replaceAll('x', 'ks')
        .replaceAll('wh', 'w')
        .replaceAll(RegExp(r'^kn'), 'n')
        .replaceAll(RegExp(r'^wr'), 'r')
        .replaceAllMapped(RegExp(r'c([eiy])'), (m) => 's${m[1]}')
        .replaceAll('c', 'k')
        .replaceAll('z', 's')
        .replaceAll('ee', 'i')
        .replaceAll('ea', 'i')
        .replaceAll('oo', 'u')
        .replaceAll(RegExp(r'y$'), 'i');
    if (s.length > 3 && s.endsWith('e') && !'aeiou'.contains(s[s.length - 2])) s = s.substring(0, s.length - 1);
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i == 0 || s[i] != s[i - 1]) b.write(s[i]);
    }
    return b.toString();
  }

  static int lev(String a, String b) {
    final x = a.runes.toList(), y = b.runes.toList();
    if (x.isEmpty) return y.length;
    if (y.isEmpty) return x.length;
    var prev = List<int>.generate(y.length + 1, (i) => i);
    for (var i = 0; i < x.length; i++) {
      final cur = <int>[i + 1];
      for (var j = 0; j < y.length; j++) {
        cur.add(min(min(prev[j + 1] + 1, cur[j] + 1), prev[j] + (x[i] == y[j] ? 0 : 1)));
      }
      prev = cur;
    }
    return prev.last;
  }

  static double similarity(String a, String b, {bool phonetic = false}) {
    var x = normalize(a), y = normalize(b);
    if (phonetic && !_isDevanagari(x)) {
      x = phoneticEn(x);
      y = phoneticEn(y);
    }
    x = x.replaceAll(' ', '');
    y = y.replaceAll(' ', '');
    if (x.isEmpty || y.isEmpty) return 0;
    if (x == y) return 1;
    final m = max(x.runes.length, y.runes.length);
    return max(0, 1 - lev(x, y) / m);
  }

  /// Best match of a single target against everything the recognizer heard.
  static double bestMatch(String target, SpeechMetrics m, {List<String> accept = const [], bool phonetic = false}) {
    final heard = <String>{m.transcript, ...m.alternates}.where((s) => s.trim().isNotEmpty).toList();
    final tokens = <String>{};
    for (final h in heard) {
      tokens.add(h);
      tokens.addAll(normalize(h).split(' ').where((t) => t.isNotEmpty));
    }
    final targets = {target, ...accept};
    var best = 0.0;
    for (final t in targets) {
      for (final h in tokens) {
        best = max(best, similarity(t, h, phonetic: phonetic));
        if (phonetic) best = max(best, similarity(t, h));
      }
    }
    return best;
  }

  /// Partial-credit item score from a match similarity.
  static double scoreFromMatch(double sim, {bool nonword = false}) {
    final full = nonword ? .75 : .85, part = nonword ? .5 : .6;
    if (sim >= full) return 1;
    if (sim >= part) return .5;
    return 0;
  }

  /// VoxLexi `compare_word_sequences`, with fuzzy equality.
  static ({List<(String, String)> items, int correct, int total}) compareSequences(String expected, String predicted) {
    final exp = normalize(expected).split(' ').where((w) => w.isNotEmpty).toList();
    final pred = normalize(predicted).split(' ').where((w) => w.isNotEmpty).toList();
    bool eq(String a, String b) => a == b || similarity(a, b, phonetic: true) >= .8;
    final items = <(String, String)>[];
    var i = 0, j = 0;
    while (i < exp.length) {
      if (j >= pred.length) {
        items.add((exp[i], 'missing'));
        i++;
        continue;
      }
      if (eq(exp[i], pred[j])) {
        items.add((exp[i], 'correct'));
        i++;
        j++;
        continue;
      }
      if (i + 1 < exp.length && eq(exp[i + 1], pred[j])) {
        items.add((exp[i], 'missing'));
        i++;
        continue;
      }
      if (j + 1 < pred.length && eq(exp[i], pred[j + 1])) {
        // inserted word in speech — skip it and retry
        j++;
        continue;
      }
      items.add((exp[i], 'wrong'));
      i++;
      j++;
    }
    final correct = items.where((e) => e.$2 == 'correct').length;
    return (items: items, correct: correct, total: max(1, items.length));
  }

  /// Count unique category words in a free-flowing answer (semantic fluency).
  static ({int count, List<String> words}) countCategory(String transcript, List<String> alternates, Set<String> lexicon) {
    final found = <String>{};
    final norm = {for (final w in lexicon) normalize(w): w};
    for (final text in {transcript, ...alternates}) {
      final t = normalize(text);
      final toks = t.split(' ').where((w) => w.isNotEmpty).toList();
      for (var i = 0; i < toks.length; i++) {
        for (final n in [toks[i], if (i + 1 < toks.length) '${toks[i]} ${toks[i + 1]}']) {
          if (norm.containsKey(n)) {
            found.add(norm[n]!);
          } else if (n.length >= 4) {
            for (final k in norm.keys) {
              if (k.length >= 4 && similarity(k, n) >= .84) {
                found.add(norm[k]!);
                break;
              }
            }
          }
        }
      }
    }
    return (count: found.length, words: found.toList());
  }

  /// Rapid naming: align the spoken stream to the expected picture sequence.
  static double ranAccuracy(String transcript, List<String> expectedNames, List<String> acceptGroups) {
    final groups = [for (final g in acceptGroups) g.split('|').map(normalize).toList()];
    final toks = normalize(transcript).split(' ').where((w) => w.isNotEmpty).toList();
    var hits = 0, k = 0;
    for (final name in expectedNames) {
      final gi = expectedNames.indexOf(name) % groups.length;
      final options = groups.isEmpty ? [normalize(name)] : groups[_groupIndex(name, expectedNames, groups)];
      // look ahead a few tokens for a match
      for (var look = k; look < min(toks.length, k + 3); look++) {
        if (options.any((o) => similarity(o, toks[look], phonetic: true) >= .75)) {
          hits++;
          k = look + 1;
          break;
        }
      }
      if (gi < 0) break;
    }
    return expectedNames.isEmpty ? 0 : hits / expectedNames.length;
  }

  static int _groupIndex(String name, List<String> names, List<List<String>> groups) {
    final n = normalize(name);
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].contains(n)) return i;
    }
    return 0;
  }
}
