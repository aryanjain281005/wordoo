import 'dart:math';
import '../content/content_pack.dart';
import '../models/models.dart';
import 'levels.dart';

/// Builds practice items for any skill at any step (1–10) from the language's content pack.
/// Selection prefers: the right difficulty → the child's current error focus → items seen least.
class ItemGen {
  final GameContentPack c;
  final Random rng;
  final Map<String, int> seen;
  ItemGen(this.c, {Random? rng, Map<String, int>? seen})
      : rng = rng ?? Random(),
        seen = seen ?? {};

  Item make(Skill skill, int step, {List<String> focus = const []}) {
    final s = step.clamp(1, 10);
    final it = switch (skill) {
      Skill.phonological => _phon(s, focus),
      Skill.gpc => _gpc(s, focus),
      Skill.decoding => _decode(s, focus),
      Skill.wordRecognition => _recog(s, focus),
      Skill.spelling => _spell(s, focus),
      Skill.comprehension => _story(s),
    };
    seen[it.id] = (seen[it.id] ?? 0) + 1;
    return it;
  }

  /// One item for [level] (1–4) of [game]. Every level of a game uses the same concept; only the difficulty
  /// changes. [bump] shifts the difficulty (later seasons). Only spelling and decoding use the child's error
  /// focus, because for the other games it would change the kind of task.
  Item forLevel(GameId game, int level, {int bump = 0, List<String> focus = const []}) {
    final l = level.clamp(1, levelsPerGame);
    final st = levelStep(game, l, bump: bump);
    final it = switch (game) {
      GameId.soundOrchestra => _phon(st, const [], fmt0: l == 1 ? 3 : 4, audio: l >= 3),
      GameId.soundNinja => _beats(l),
      GameId.letterArcher || GameId.soundPortal => _gpc(st.clamp(2, 10), const []),
      GameId.wordRocket => _decode(st, focus, pictures: l <= 3),
      GameId.wordBuilder => _decode(st, focus),
      GameId.wordDetective || GameId.wordFlash => _recog(st, const []),
      GameId.spellingHive || GameId.magicWriter => _spell(st, focus),
      GameId.storyQuest => _story(st),
      GameId.starObservatory => make(Skill.values[rng.nextInt(6)], st * 2),
    };
    seen[it.id] = (seen[it.id] ?? 0) + 1;
    return it;
  }

  /// Sound Ninja: how many pieces does the word slice into? Levels 1–3 count beats (syllables), level 4
  /// counts every sound in a short word.
  Item _beats(int level) {
    final sounds = level == 4;
    final (lo, hi) = switch (level) { 1 => (1, 2), 2 => (2, 3), 3 => (3, 4), _ => (2, 4) };
    final want = lo + rng.nextInt(hi - lo + 1);
    final pool = c.words.where((w) {
      if (w.emoji == null || w.nonword || w.irregular || w.text.length > 11) return false;
      return sounds ? (w.syllables == 1 && !w.silentE && w.units.length == want) : w.syllables == want;
    }).toList();
    pool.sort((a, b) => (seen['pc:${a.text}'] ?? 0).compareTo(seen['pc:${b.text}'] ?? 0));
    final t = _pick(pool.take(8).toList());
    final n = sounds ? t.units.length : t.syllables;
    final others = <int>{for (final d in [-1, 1, 2, -2]) if (n + d >= 1 && n + d <= 5) n + d}.take(2);
    final p = sounds ? 'Slice “${t.text}” into its sounds!' : 'Slice “${t.text}” into its beats!';
    return _choice('pc:${t.text}', Skill.phonological, level * 2, p, p,
        [Opt('$n', say: t.text), for (final o in others) Opt('$o', say: t.text, tag: sounds ? 'Failed blend' : 'Syllable count error')],
        stimulus: t.text, emoji: t.emoji, replay: sounds ? t.units.map(c.sayUnit).join(',  ') : t.text, hint: sounds ? 'Say it very slowly. Each sound is one slice.' : 'Say it slowly and cut at every beat.', diff: level * 2.0);
  }

  // ---------------- helpers ----------------
  T _pick<T>(List<T> l) => l[rng.nextInt(l.length)];

  /// Words near [step] satisfying [ok]; widens the window until enough candidates exist; least-seen first.
  List<WordEntry> _near(int step, bool Function(WordEntry) ok, {int want = 6, String prefix = ''}) {
    for (var win = 0; win <= 9; win++) {
      final l = c.words.where((w) => ok(w) && (w.step - step).abs() <= win).toList();
      if (l.length >= want || win == 9) {
        l.shuffle(rng);
        l.sort((a, b) => (seen['$prefix${a.text}'] ?? 0).compareTo(seen['$prefix${b.text}'] ?? 0));
        return l;
      }
    }
    return [];
  }

  WordEntry _leastSeen(List<WordEntry> l, String prefix) {
    final top = l.take(max(1, min(4, l.length))).toList();
    return _pick(top);
  }

  List<WordEntry> _others(List<WordEntry> pool, int n, bool Function(WordEntry) ok) {
    final l = pool.where(ok).toList()..shuffle(rng);
    final out = <WordEntry>[];
    for (final w in l) {
      if (out.length >= n) break;
      if (out.any((o) => o.text == w.text || (o.emoji != null && o.emoji == w.emoji))) continue;
      out.add(w);
    }
    return out;
  }

  Item _choice(String id, Skill skill, int step, String prompt, String say, List<Opt> opts, {String? stimulus, String? emoji, String? passage, String hint = '', String? replay, bool timed = false, double? diff, bool audio = false}) {
    final order = List<int>.generate(opts.length, (i) => i)..shuffle(rng);
    return Item(
      id: id,
      skill: skill,
      level: step,
      kind: ItemKind.choice,
      prompt: prompt,
      say: say,
      stimulus: stimulus,
      emoji: emoji,
      passage: passage,
      options: [for (final i in order) opts[i]],
      correct: order.indexOf(0),
      hint: hint,
      replaySay: replay ?? say,
      timed: timed,
      diff: diff ?? step.toDouble(),
      audioOptions: audio,
    );
  }

  static const _closeOnset = {
    'b': ['p', 'd'], 'p': ['b', 't'], 'd': ['t', 'b'], 't': ['d', 'k'], 'm': ['n'], 'n': ['m'], 'f': ['v', 's'], 'v': ['f'],
    's': ['z', 'sh'], 'sh': ['ch', 's'], 'ch': ['sh', 'j'], 'c': ['g', 't'], 'k': ['g'], 'g': ['k', 'c'], 'l': ['r'], 'r': ['l', 'w'],
  };

  // ---------------- phonological awareness ----------------
  Item _phon(int step, List<String> focus, {int? fmt0, bool audio = false}) {
    var fmt = fmt0 ?? step;
    if (fmt0 == null) {
      if (focus.contains('Wrong first sound')) fmt = min(step, 2);
      if (focus.contains('Rhyme confusion') || focus.contains('Wrong ending sound')) fmt = step <= 4 ? max(3, step) : 7;
      if (focus.contains('Failed blend')) fmt = step <= 6 ? max(5, step) : 6;
    }
    final pics = c.words.where((w) => w.emoji != null && !w.irregular && w.syllables <= 2).toList();
    WordEntry pickT(bool Function(WordEntry) ok, String pre) => _leastSeen(_near(min(step, 5), (w) => w.emoji != null && ok(w), prefix: pre), pre);

    if (fmt <= 2 && focus.isEmpty && rng.nextDouble() < .35) {
      // Clap the Beat: one drum tap per syllable (1–2 beats at step 1, up to 3 at step 2)
      // pick the beat count first, so answers are not almost always "1"
      final maxSyl = step <= 1 ? 2 : 3;
      final want = 1 + rng.nextInt(maxSyl);
      final pool = c.words.where((w) => w.emoji != null && !w.nonword && w.syllables == want && w.text.length <= 10).toList()
        ..sort((a, b) => (a.difficulty - step).abs().compareTo((b.difficulty - step).abs()));
      final t = _leastSeen(pool.take(40).toList(), 'pc:');
      final p = c.p('clap', w: t.text);
      return _choice('pc:${t.text}', Skill.phonological, step, p, p,
          [Opt('${t.syllables}', say: t.text), for (var n = 1; n <= 3; n++) if (n != t.syllables) Opt('$n', say: t.text, tag: 'Syllable count error')],
          stimulus: t.text, emoji: t.emoji, replay: t.text, hint: 'Say it slowly and tap for each beat.', diff: step.toDouble());
    }
    if (fmt <= 2) {
      final t = pickT((w) => pics.any((o) => o.text != w.text && o.firstUnit == w.firstUnit), 'ps:');
      final match = _pick(pics.where((o) => o.text != t.text && o.firstUnit == t.firstUnit).toList());
      final close = _closeOnset[t.firstUnit] ?? const <String>[];
      final others = _others(pics, 2, (o) => o.firstUnit != t.firstUnit && (fmt == 1 || close.contains(o.firstUnit) || close.isEmpty));
      final others2 = others.length < 2 ? _others(pics, 2, (o) => o.firstUnit != t.firstUnit) : others;
      final p = c.p('firstSound', w: t.text);
      return _choice('ps:${t.text}', Skill.phonological, step, p, p,
          [Opt(match.text, emoji: match.emoji, say: match.text), for (final o in others2) Opt(o.text, emoji: o.emoji, say: o.text, tag: 'Wrong first sound')],
          emoji: t.emoji, hint: 'Listen to the very first sound.', diff: fmt.toDouble());
    }
    if (fmt <= 4) {
      // rhymes by sound: only words in a checked rhyme family (fall back to spelling only if a language has none)
      final fam = c.rhymeFamily;
      String? rh(WordEntry w) => fam.isEmpty ? w.rime : fam[w.text];
      final rpics = c.words.where((w) => w.emoji != null && !w.nonword && rh(w) != null).toList();
      final t = pickT((w) => rh(w) != null && rpics.any((o) => o.text != w.text && rh(o) == rh(w)), 'pr:');
      final match = _pick(rpics.where((o) => o.text != t.text && rh(o) == rh(t)).toList());
      // wrong answers must clearly NOT rhyme (and at level 2+ start with the same sound, to make it tricky)
      bool notRhyme(WordEntry o) => o.text != t.text && rh(o) != rh(t) && o.rime != t.rime && o.text.substring(max(0, o.text.length - 2)) != t.text.substring(max(0, t.text.length - 2));
      final others = _others(pics, 2, (o) => notRhyme(o) && (fmt == 3 || o.firstUnit == t.firstUnit));
      final others2 = others.length < 2 ? _others(pics, 2, notRhyme) : others;
      final p = c.p('rhyme', w: t.text);
      return _choice('pr:${t.text}', Skill.phonological, step, p, p,
          [Opt(match.text, emoji: match.emoji, say: match.text), for (final o in others2) Opt(o.text, emoji: o.emoji, say: o.text, tag: 'Rhyme confusion')],
          emoji: t.emoji, hint: 'Listen to the end of the word.', diff: max(fmt, step).toDouble(), audio: audio);
    }
    if (fmt <= 6) {
      final n = fmt == 5 ? 3 : 4;
      final t = pickT((w) => w.units.length == n || (fmt == 6 && w.syllables == 2 && w.units.length <= 6), 'pb:');
      final others = _others(pics, 2, (o) => o.text != t.text && o.firstUnit != t.firstUnit);
      final sounds = t.units.map(c.sayUnit).join(',  ');
      return _choice('pb:${t.text}', Skill.phonological, step, c.p('blend'), '${c.p('blend')}  $sounds',
          [Opt(t.text, emoji: t.emoji, say: t.text), for (final o in others) Opt(o.text, emoji: o.emoji, say: o.text, tag: 'Failed blend')],
          stimulus: List.filled(t.units.length, '•').join(' '), replay: sounds, hint: 'Say the sounds fast — they make one word.', diff: fmt.toDouble());
    }
    if (fmt == 7) {
      final t = pickT((w) => pics.any((o) => o.text != w.text && o.units.last == w.units.last && o.firstUnit != w.firstUnit), 'pe:');
      final match = _pick(pics.where((o) => o.text != t.text && o.units.last == t.units.last && o.firstUnit != t.firstUnit).toList());
      final others = _others(pics, 2, (o) => o.units.last != t.units.last);
      final p = c.p('endSound', w: t.text);
      return _choice('pe:${t.text}', Skill.phonological, step, p, p,
          [Opt(match.text, emoji: match.emoji, say: match.text), for (final o in others) Opt(o.text, emoji: o.emoji, say: o.text, tag: 'Wrong ending sound')],
          emoji: t.emoji, hint: 'Listen to the very last sound.', diff: 7);
    }
    bool cons(String u) => !'aeiouy'.contains(u[0]);
    if (fmt == 8) {
      final t = _leastSeen(_near(4, (w) => w.units.length >= 3 && w.units.length <= 5 && cons(w.firstUnit) && !w.irregular && w.syllables == 1, prefix: 'pd:'), 'pd:');
      final rest = t.units.sublist(1).join();
      final noLast = t.units.sublist(0, t.units.length - 1).join();
      final p = c.p('delete', w: t.text, r: c.sayUnit(t.firstUnit));
      return _choice('pd:${t.text}', Skill.phonological, step, p, p, [Opt(rest, say: rest), Opt(noLast, say: noLast, tag: 'Sound deletion / replacement error'), Opt(t.text, say: t.text, tag: 'Sound deletion / replacement error')],
          emoji: t.emoji, hint: 'Take the first sound away. What is left?', diff: 8, audio: true);
    }
    if (fmt == 9) {
      final t = _leastSeen(_near(4, (w) => w.units.length >= 4 && w.blends > 0 && cons(w.units[0]) && cons(w.units[1]) && w.syllables == 1, prefix: 'pm:'), 'pm:');
      final ans = [t.units[0], ...t.units.sublist(2)].join();
      final wrong = t.units.sublist(1).join();
      final p = c.p('deleteMid', w: t.text, r: c.sayUnit(t.units[1]));
      return _choice('pm:${t.text}', Skill.phonological, step, p, p, [Opt(ans, say: ans), Opt(wrong, say: wrong, tag: 'Sound deletion / replacement error'), Opt(t.text, say: t.text, tag: 'Sound deletion / replacement error')],
          emoji: t.emoji, hint: 'Leave out the sound in the middle.', diff: 9, audio: true);
    }
    // 10: substitution within a rhyme family
    final fams = <String, List<WordEntry>>{};
    for (final w in c.words.where((w) => w.rime != null && w.syllables == 1 && !w.irregular && cons(w.firstUnit) && w.units.length <= 4)) {
      fams.putIfAbsent(w.rime!, () => []).add(w);
    }
    final ok = fams.values.where((l) => l.length >= 3).toList();
    final fam = _pick(ok)..shuffle(rng);
    final a = fam[0], b = fam[1], d = fam[2];
    final p = c.p('swap', w: a.text, r: c.sayUnit(a.firstUnit), x: c.sayUnit(b.firstUnit));
    return _choice('pw:${a.text}>${b.text}', Skill.phonological, step, p, p, [Opt(b.text, say: b.text), Opt(d.text, say: d.text, tag: 'Sound deletion / replacement error'), Opt(a.text, say: a.text, tag: 'Sound deletion / replacement error')],
        hint: 'Swap only the first sound.', diff: 10, audio: true);
  }

  // ---------------- letter–sound ----------------
  Item _gpc(int step, List<String> focus) {
    var s = step;
    if (focus.contains('Similar letter / matra confusion') || focus.contains('Similar-letter confusion')) s = max(5, min(step, 6));
    final at = c.graphemes.where((g) => g.step == s).toList();
    at.shuffle(rng);
    at.sort((a, b) => (seen[a.id] ?? 0).compareTo(seen[b.id] ?? 0));
    final t = _pick(at.take(3).toList());
    final d = <String>[for (final x in t.confusable) if (x != t.text) x];
    final pool = (c.graphemes.where((g) => (g.step - s).abs() <= 1 && g.text != t.text).map((g) => g.text).toSet().toList())..shuffle(rng);
    for (final x in pool) {
      if (d.length >= 2) break;
      if (!d.contains(x)) d.add(x);
    }
    return _choice(t.id, Skill.gpc, step, c.p('letter'), t.say,
        [Opt(t.text, say: t.say), for (final x in d.take(2)) Opt(x, tag: s == 5 ? 'Similar-letter confusion' : 'Wrong letter / pattern')],
        hint: 'Listen again, then look at the shapes.', replay: t.say, diff: s.toDouble());
  }

  // ---------------- decoding ----------------
  Item _decode(int step, List<String> focus, {bool pictures = false}) {
    if (step >= 8) {
      final nws = c.nonwords(step, 1, rng.nextInt(1 << 30));
      final n = nws.first;
      final variants = <String>{};
      const vow = ['a', 'e', 'i', 'o', 'u'];
      for (var i = 0; i < n.units.length && variants.length < 2; i++) {
        final u = n.units[i];
        if (vow.contains(u)) {
          final copy = [...n.units]..[i] = vow[(vow.indexOf(u) + 1 + rng.nextInt(3)) % 5];
          variants.add(copy.join());
        }
      }
      if (n.units.length >= 3) variants.add([...n.units.sublist(0, n.units.length - 1), n.units.first].join());
      final v = variants.where((x) => x != n.text).take(2).toList();
      while (v.length < 2) {
        v.add('${n.text}${['s', 'y'][v.length]}');
      }
      return _choice('dn:${n.text}', Skill.decoding, step, c.p('decodeNon'), c.p('decodeNon'),
          [Opt(n.text, say: n.text), for (final x in v) Opt(x, say: x, tag: 'Incorrect blend')],
          stimulus: n.units.join(' · '), replay: n.units.map(c.sayUnit).join(',  '), hint: 'Read each piece, then glue them together.', diff: n.difficulty, audio: true);
    }
    final wantBlend = focus.contains('Incorrect blend');
    final cand = _near(step, (w) => !w.irregular && (!pictures || w.emoji != null) && (!wantBlend || w.blends > 0 || w.digraphs > 0), prefix: 'd:');
    final t = _leastSeen(cand, 'd:');
    final picture = step <= 6 && t.emoji != null;
    final pool = c.words.where((w) => (w.step - step).abs() <= 2 && w.text != t.text && (!picture || w.emoji != null)).toList();
    var others = _others(pool, 2, (o) => step >= 4 ? o.firstUnit == t.firstUnit : true);
    if (others.length < 2) others = _others(pool, 2, (_) => true);
    if (picture) {
      return _choice('d:${t.text}', Skill.decoding, step, c.p('decode'), c.p('decode'),
          [Opt(t.text, emoji: t.emoji, say: t.text), for (final o in others) Opt(o.text, emoji: o.emoji, say: o.text, tag: 'Incorrect blend')],
          stimulus: t.units.join(' · '), replay: t.units.map(c.sayUnit).join(',  '), hint: 'Read each piece, then glue them together.', diff: t.difficulty);
    }
    return _choice('d:${t.text}', Skill.decoding, step, c.p('decodeHear'), c.p('decodeHear'),
        [Opt(t.text, say: t.text), for (final o in others) Opt(o.text, say: o.text, tag: 'Incorrect blend')],
        stimulus: t.units.join(' · '), replay: t.units.map(c.sayUnit).join(',  '), hint: 'Read each piece, then glue them together.', diff: t.difficulty, audio: true);
  }

  // ---------------- word recognition ----------------
  Item _recog(int step, List<String> focus) {
    final visual = focus.contains('Visual confusion');
    final cand = _near(step, (w) => w.text.length >= 2, prefix: 'wr:');
    final t = _leastSeen(cand, 'wr:');
    final wrongs = <String>[];
    final s = visual ? max(step, 7) : step;
    if (s <= 2) {
      wrongs.addAll(_others(c.words.where((w) => (w.step - step).abs() <= 1).toList(), 2, (o) => o.text[0] != t.text[0] && o.text != t.text).map((e) => e.text));
    } else if (s <= 4) {
      wrongs.addAll(_others(c.words.toList(), 2, (o) => o.text[0] == t.text[0] && o.text != t.text && (o.text.length - t.text.length).abs() <= 1).map((e) => e.text));
    } else if (s <= 6) {
      // real-word neighbours one letter apart
      int diff(String a, String b) => a.length != b.length ? 9 : [for (var i = 0; i < a.length; i++) if (a[i] != b[i]) i].length;
      wrongs.addAll(_others(c.words.toList(), 2, (o) => diff(o.text, t.text) == 1).map((e) => e.text));
    }
    for (final x in c.confusions(t.text, rng.nextInt(1 << 20))) {
      if (wrongs.length >= 2) break;
      if (!wrongs.contains(x) && x != t.text) wrongs.add(x);
    }
    for (final w in _others(c.words.toList(), 3, (o) => o.text != t.text)) {
      if (wrongs.length >= 2) break;
      if (!wrongs.contains(w.text)) wrongs.add(w.text);
    }
    return _choice('wr:${t.text}', Skill.wordRecognition, step, c.p('find'), t.text,
        [Opt(t.text, say: t.text), for (final w in wrongs.take(2)) Opt(w, say: w, tag: s >= 5 ? 'Visual confusion' : 'Wrong familiar word')],
        hint: 'Say the word, then look for it.', replay: t.text, timed: true, diff: max(step.toDouble(), t.difficulty * .5 + step * .5));
  }

  // ---------------- spelling ----------------
  static const _alpha = 'abcdefghijklmnopqrstuvwxyz';
  static const _lookalike = {'b': 'd', 'd': 'b', 'p': 'q', 'm': 'n', 'n': 'm', 'a': 'e', 'e': 'i', 'i': 'e', 'o': 'u', 'u': 'o', 'f': 't', 'c': 'k', 'k': 'c', 's': 'c'};
  Item _spell(int step, List<String> focus) {
    final vowelFocus = focus.contains('Wrong vowel');
    final cand = _near(step, (w) => w.text.length >= 2 && w.text.length <= 11 && RegExp(r'^[a-z]+$').hasMatch(w.text) && (!vowelFocus || w.vowelTeams > 0 || w.silentE || w.syllables == 1), prefix: 'sp:');
    final t = _leastSeen(cand, 'sp:');
    final letters = t.text.split('');
    final extra = step <= 2 ? 2 : (step <= 5 ? 3 : (step <= 8 ? 4 : 5));
    final d = <String>[];
    for (final ch in letters) {
      final l = _lookalike[ch];
      if (step >= 3 && l != null && !letters.contains(l) && !d.contains(l)) d.add(l);
    }
    while (d.length < extra) {
      final ch = _alpha[rng.nextInt(26)];
      if (!letters.contains(ch) && !d.contains(ch)) d.add(ch);
    }
    final tiles = [...letters, ...d.take(extra)]..shuffle(rng);
    return Item(
      id: 'sp:${t.text}',
      skill: Skill.spelling,
      level: step,
      kind: ItemKind.build,
      prompt: c.p('spell'),
      say: t.text,
      emoji: t.emoji,
      answer: letters,
      tiles: tiles,
      hint: 'Say the word slowly. What do you hear first?',
      replaySay: t.text,
      diff: t.difficulty * .6 + step * .4,
    );
  }

  // ---------------- comprehension ----------------
  Item _story(int step) {
    StoryEntry st;
    if (step <= 3 && rng.nextDouble() < .7) {
      st = c.storyFromTemplate(step, rng.nextInt(1 << 30));
    } else {
      final l = [...c.stories]..sort((a, b) {
          final da = (a.step - step).abs(), db = (b.step - step).abs();
          if (da != db) return da.compareTo(db);
          return (seen['st:${a.id}'] ?? 0).compareTo(seen['st:${b.id}'] ?? 0);
        });
      st = l.first;
      seen['st:${st.id}'] = (seen['st:${st.id}'] ?? 0) + 1;
    }
    final qi = st.questions.isEmpty ? 0 : (seen['stq:${st.id}'] ?? 0) % st.questions.length;
    seen['stq:${st.id}'] = (seen['stq:${st.id}'] ?? 0) + 1;
    final q = st.questions[qi];
    final tag = switch (q.type) { 'cause' => 'Cause / effect error', 'sequence' => 'Sequence error', 'inference' => 'Inference error', 'prediction' => 'Prediction error', _ => 'Wrong detail' };
    return _choice('st:${st.id}:$qi', Skill.comprehension, step, c.p('story'), '${st.text}  ${q.q}',
        [for (var i = 0; i < q.options.length; i++) Opt(q.options[i].$1, emoji: q.options[i].$2, say: q.options[i].$1, tag: i == 0 ? null : tag)],
        stimulus: q.q, emoji: st.emoji, passage: st.text, hint: 'Look back at the story for the answer.', replay: st.text,
        diff: st.step + (q.type == 'inference' || q.type == 'prediction' ? 1.0 : 0));
  }
}
