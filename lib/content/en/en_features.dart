import '../content_pack.dart';

/// English orthography rules used to tag every word automatically.
class EnFeatures {
  // longest first so that greedy matching works
  static const graphemes = [
    'tion', 'tch', 'dge', 'igh', 'ough',
    'sh', 'ch', 'th', 'ck', 'ng', 'wh', 'ph', 'qu', 'kn', 'wr', 'mb',
    'ee', 'ea', 'oa', 'ai', 'ay', 'oo', 'ou', 'ow', 'oi', 'oy', 'ar', 'or', 'er', 'ir', 'ur', 'aw', 'ew', 'ie', 'ue', 'au',
    'll', 'ss', 'ff', 'zz', 'bb', 'dd', 'gg', 'mm', 'nn', 'pp', 'rr', 'tt',
  ];
  static const digraphSet = {'sh', 'ch', 'th', 'ck', 'ng', 'wh', 'ph', 'qu', 'kn', 'wr', 'mb', 'tch', 'dge', 'tion'};
  static const vowelTeamSet = {'ee', 'ea', 'oa', 'ai', 'ay', 'oo', 'ou', 'ow', 'oi', 'oy', 'ar', 'or', 'er', 'ir', 'ur', 'aw', 'ew', 'ie', 'ue', 'au', 'igh', 'ough'};
  static const vowels = 'aeiou';

  static List<String> segment(String w) {
    final out = <String>[];
    var i = 0;
    while (i < w.length) {
      String? hit;
      for (final g in graphemes) {
        if (w.startsWith(g, i)) {
          hit = g;
          break;
        }
      }
      hit ??= w[i];
      out.add(hit);
      i += hit.length;
    }
    return out;
  }

  static bool isVowelUnit(String u) => u.split('').any((c) => vowels.contains(c)) && !digraphSet.contains(u) || u == 'y';

  static bool hasSilentE(String w) {
    if (w.length < 4 || !w.endsWith('e')) return false;
    final c = w[w.length - 2], v = w[w.length - 3];
    return !vowels.contains(c) && vowels.contains(v) && !(w.length > 4 && vowels.contains(w[w.length - 4]));
  }

  static int syllables(String w) {
    var s = w.toLowerCase();
    if (s.length <= 3) return 1;
    // plural -es after a silent e is not a syllable (grapes, gloves) — but it is after s/x/z/ch/sh (boxes)
    if (s.endsWith('es') && !RegExp(r'(s|x|z|ch|sh)es$').hasMatch(s)) s = s.substring(0, s.length - 1);
    if (s.endsWith('e') && !s.endsWith('ee') && s.length > 3) {
      final consonantLe = s.endsWith('le') && !vowels.contains(s[s.length - 3]); // ap-ple, cas-tle: the "le" is a beat
      if (!consonantLe && !vowels.contains(s[s.length - 2])) s = s.substring(0, s.length - 1); // whale, snake: silent e
    }
    return RegExp(r'[aeiouy]+').allMatches(s).length.clamp(1, 7);
  }

  /// Consonant clusters made of separate letters (fr, st, nd, mp…), at the start or end.
  static int blends(List<String> units) {
    bool cons(String u) => u.length == 1 && !vowels.contains(u) && u != 'y';
    var n = 0;
    if (units.length >= 3 && cons(units[0]) && cons(units[1])) n++;
    if (units.length >= 3 && cons(units[units.length - 1]) && cons(units[units.length - 2]) && !hasSilentE(units.join())) n++;
    return n;
  }

  static WordEntry tag(String raw, {String? emoji}) {
    var common = false, irregular = false, w = raw;
    while (w.startsWith('*') || w.startsWith('!')) {
      if (w.startsWith('*')) common = true;
      if (w.startsWith('!')) irregular = true;
      w = w.substring(1);
    }
    final units = segment(w);
    final dig = units.where(digraphSet.contains).length;
    final vt = units.where(vowelTeamSet.contains).length;
    final se = hasSilentE(w);
    final syl = syllables(w);
    final bl = blends(units);
    var d = 1.0 +
        0.45 * (w.length - 3).clamp(0, 12) +
        0.8 * dig +
        0.8 * bl +
        1.0 * vt +
        1.2 * (se ? 1 : 0) +
        1.3 * (syl - 1) +
        (common ? -0.6 : 0.3) +
        (irregular ? 2.0 : 0);
    d = d.clamp(1.0, 10.0);
    String? rime;
    for (var i = units.length - 1; i >= 0; i--) {
      if (isVowelUnit(units[i])) {
        rime = units.sublist(i).join();
        break;
      }
    }
    if (se && units.length >= 3) rime = units.sublist(units.length - 3).join();
    return WordEntry(text: w, emoji: emoji, units: units, syllables: syl, digraphs: dig, blends: bl, vowelTeams: vt, silentE: se, irregular: irregular, common: common, difficulty: d, rime: rime);
  }
}
