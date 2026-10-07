import 'dart:math';
import '../data/lang.dart';
import '../models/models.dart';

/// Generates items for all six skills from a language pack's data tables.
/// Nothing here is language specific — it only uses the LangPack interface.
class ItemFactory {
  final LangPack pack;
  final Random rng;
  ItemFactory(this.pack, [Random? r]) : rng = r ?? Random();

  T _pick<T>(List<T> l) => l[rng.nextInt(l.length)];

  /// Picks from [pool] preferring items allowed by [forms] and not already used.
  List<T> _prefer<T>(List<T> pool, bool Function(T) formOk, bool Function(T) notUsed) {
    var c = pool.where((x) => formOk(x) && notUsed(x)).toList();
    if (c.isEmpty) c = pool.where(formOk).toList();
    if (c.isEmpty) c = pool;
    return c;
  }

  Item make(Skill skill, int level, Set<Pool> forms, {Set<String> used = const {}}) {
    final lv = level.clamp(1, 4);
    return switch (skill) {
      Skill.phonological => _phon(lv, forms, used),
      Skill.gpc => _gpc(lv, forms, used),
      Skill.decoding => _decode(lv, forms, used),
      Skill.wordRecognition => _recog(lv, forms, used),
      Skill.spelling => _spell(lv, forms, used),
      Skill.comprehension => _story(lv, forms, used),
    };
  }

  List<Word> _wordsAt(int level) => pack.words.where((w) => w.level == level).toList();

  Item _shuffleOpts(String id, Skill skill, int level, String prompt, String say, List<Opt> opts, int correct,
      {String? stimulus, String? emoji, String? passage, String hint = '', String? replay, bool timed = false}) {
    final order = List<int>.generate(opts.length, (i) => i)..shuffle(rng);
    final shuffled = [for (final i in order) opts[i]];
    return Item(
      id: id,
      skill: skill,
      level: level,
      kind: ItemKind.choice,
      prompt: prompt,
      say: say,
      stimulus: stimulus,
      emoji: emoji,
      passage: passage,
      options: shuffled,
      correct: order.indexOf(correct),
      hint: hint,
      replaySay: replay ?? say,
      timed: timed,
    );
  }

  // ---------------- Phonological awareness ----------------
  Item _phon(int level, Set<Pool> forms, Set<String> used) {
    if (level == 1) {
      // first sound match
      final cands = _prefer<Word>(pack.words, (w) => forms.contains(w.form),
          (w) => !used.contains('ph1:${w.text}'));
      final eligible = cands.where((w) => pack.words.any((o) => o != w && pack.firstKey(o) == pack.firstKey(w))).toList();
      final t = _pick(eligible.isEmpty ? pack.words : eligible);
      final partners = pack.words.where((o) => o != t && pack.firstKey(o) == pack.firstKey(t)).toList();
      final match = partners.isEmpty ? _pick(pack.words.where((o) => o != t).toList()) : _pick(partners);
      final others = (pack.words.where((o) => pack.firstKey(o) != pack.firstKey(t)).toList()..shuffle(rng))
          .fold<List<Word>>([], (acc, w) {
        if (acc.length < 2 && !acc.any((a) => pack.firstKey(a) == pack.firstKey(w))) acc.add(w);
        return acc;
      });
      final opts = [
        Opt(match.text, emoji: match.emoji, say: match.text),
        for (final o in others) Opt(o.text, emoji: o.emoji, say: o.text, tag: 'Wrong first sound'),
      ];
      return _shuffleOpts('ph1:${t.text}', Skill.phonological, 1, pack.p('firstSound', w: t.text),
          pack.p('firstSound', w: t.text), opts, 0,
          stimulus: t.text, emoji: t.emoji, hint: 'Listen to the very first sound.', replay: pack.p('firstSound', w: t.text));
    }
    if (level == 2) {
      final cands = _prefer<Word>(pack.words.where((w) => pack.endKey(w) != null).toList(),
          (w) => forms.contains(w.form), (w) => !used.contains('ph2:${w.text}'));
      final eligible = cands.where((w) => pack.words.any((o) => o != w && pack.endKey(o) == pack.endKey(w))).toList();
      final t = _pick(eligible.isEmpty ? cands : eligible);
      final partners = pack.words.where((o) => o != t && pack.endKey(o) == pack.endKey(t)).toList();
      final match = partners.isEmpty ? _pick(pack.words.where((o) => o != t).toList()) : _pick(partners);
      final others = (pack.words.where((o) => pack.endKey(o) != pack.endKey(t)).toList()..shuffle(rng)).take(2);
      final opts = [
        Opt(match.text, emoji: match.emoji, say: match.text),
        for (final o in others) Opt(o.text, emoji: o.emoji, say: o.text, tag: 'Wrong ending sound'),
      ];
      return _shuffleOpts('ph2:${t.text}', Skill.phonological, 2, pack.p('rhyme', w: t.text),
          pack.p('rhyme', w: t.text), opts, 0,
          stimulus: t.text, emoji: t.emoji, hint: 'Listen to the end of the word.');
    }
    if (level == 3) {
      final cands = _prefer<Word>(pack.words.where((w) => w.level <= 2 && w.units.length <= 4).toList(),
          (w) => forms.contains(w.form), (w) => !used.contains('ph3:${w.text}') && !used.contains('ph1:${w.text}'));
      final t = _pick(cands);
      final others = (pack.words.where((o) => o != t && o.level <= 2).toList()..shuffle(rng)).take(2);
      final sounds = t.units.map(pack.sayUnit).join(',  ');
      final opts = [
        Opt(t.text, emoji: t.emoji, say: t.text),
        for (final o in others) Opt(o.text, emoji: o.emoji, say: o.text, tag: 'Failed blend'),
      ];
      return _shuffleOpts('ph3:${t.text}', Skill.phonological, 3, pack.p('blend'), '${pack.p('blend')}  $sounds', opts, 0,
          stimulus: '• ' * t.units.length, hint: 'Say the sounds fast: they make one word.', replay: sounds);
    }
    final cands = _prefer<Deletion>(pack.deletions, (d) => forms.contains(d.form), (d) => !used.contains('ph4:${d.word}'));
    final d = _pick(cands);
    final opts = [
      Opt(d.result, say: d.result),
      for (final w in d.wrong) Opt(w, say: w, tag: 'Wrong sound deletion'),
    ];
    final prompt = pack.p('delete', w: d.word, r: d.removed);
    return _shuffleOpts('ph4:${d.word}', Skill.phonological, 4, prompt, prompt, opts, 0,
        stimulus: d.word, emoji: d.emoji, hint: 'Take the sound away. What is left?');
  }

  // ---------------- Grapheme–phoneme ----------------
  Item _gpc(int level, Set<Pool> forms, Set<String> used) {
    final lvlGraphs = pack.graphs.where((g) => g.level == level).toList();
    final cands = _prefer<Graph>(lvlGraphs, (g) => forms.contains(g.form), (g) => !used.contains(g.id));
    final t = _pick(cands);
    final distract = <String>[];
    for (final s in t.similar) {
      if (s != t.text && !distract.contains(s)) distract.add(s);
    }
    final pool = lvlGraphs.where((g) => g.text != t.text).map((g) => g.text).toList()..shuffle(rng);
    for (final p in pool) {
      if (distract.length >= 2) break;
      if (!distract.contains(p)) distract.add(p);
    }
    final opts = [
      Opt(t.text, say: t.say),
      for (final d in distract.take(2))
        Opt(d, say: d, tag: level == 2 ? 'Similar-letter confusion' : (level >= 3 ? 'Pattern / matra confusion' : 'Wrong letter')),
    ];
    final prompt = pack.p('letter');
    return _shuffleOpts(t.id, Skill.gpc, level, prompt, prompt, opts, 0,
        hint: 'Listen again, then look at the shapes.', replay: t.say, stimulus: null);
  }

  // ---------------- Decoding ----------------
  Item _decode(int level, Set<Pool> forms, Set<String> used) {
    if (level >= 4) {
      final cands = _prefer<NonWord>(pack.nonWords, (n) => forms.contains(n.form), (n) => !used.contains('dn:${n.correct}'));
      final n = _pick(cands);
      final opts = [Opt(n.correct, say: n.correct), for (final w in n.wrong) Opt(w, say: w, tag: 'Incorrect blend')];
      return _shuffleOpts('dn:${n.correct}', Skill.decoding, 4, pack.p('decodeNon'), pack.p('decodeNon'), opts, 0,
          stimulus: n.units.join(' · '), hint: 'Read each piece, then glue them together.',
          replay: n.units.map(pack.sayUnit).join(',  '));
    }
    final lvl = _wordsAt(level);
    final cands = _prefer<Word>(lvl, (w) => forms.contains(w.form), (w) => !used.contains('d:${w.text}'));
    final t = _pick(cands);
    final others = (lvl.where((o) => o != t).toList()..shuffle(rng)).take(2);
    final opts = [
      Opt(t.text, emoji: t.emoji, say: t.text),
      for (final o in others) Opt(o.text, emoji: o.emoji, say: o.text, tag: 'Incorrect blend'),
    ];
    return _shuffleOpts('d:${t.text}', Skill.decoding, level, pack.p('decode'), pack.p('decode'), opts, 0,
        stimulus: t.units.join(' · '), hint: 'Read each piece, then glue them together.',
        replay: t.units.map(pack.sayUnit).join(',  '));
  }

  // ---------------- Word recognition ----------------
  Item _recog(int level, Set<Pool> forms, Set<String> used) {
    final lvl = _wordsAt(level);
    final cands = _prefer<Word>(lvl, (w) => forms.contains(w.form), (w) => !used.contains('wr:${w.text}'));
    final t = _pick(cands);
    final wrongs = <String>[];
    if (level <= 1) {
      final o = (lvl.where((w) => w != t).toList()..shuffle(rng)).take(2);
      wrongs.addAll(o.map((w) => w.text));
    } else {
      final conf = pack.confusions(t)..shuffle(rng);
      if (level == 2) {
        final sameStart = lvl.where((w) => w != t && pack.firstKey(w) == pack.firstKey(t)).map((w) => w.text).toList();
        if (sameStart.isNotEmpty) wrongs.add(_pick(sameStart));
      }
      for (final c in conf) {
        if (wrongs.length >= 2) break;
        if (!wrongs.contains(c)) wrongs.add(c);
      }
      for (final w in (lvl.where((x) => x != t).toList()..shuffle(rng))) {
        if (wrongs.length >= 2) break;
        if (!wrongs.contains(w.text)) wrongs.add(w.text);
      }
    }
    final opts = [
      Opt(t.text, say: t.text),
      for (final w in wrongs.take(2)) Opt(w, say: w, tag: level <= 1 ? 'Wrong familiar word' : 'Visual confusion'),
    ];
    return _shuffleOpts('wr:${t.text}', Skill.wordRecognition, level, pack.p('find'), t.text, opts, 0,
        hint: 'Say the word, then look for it.', replay: t.text, timed: true);
  }

  // ---------------- Spelling ----------------
  Item _spell(int level, Set<Pool> forms, Set<String> used) {
    final lvl = _wordsAt(level);
    final cands = _prefer<Word>(lvl, (w) => forms.contains(w.form), (w) => !used.contains('sp:${w.text}'));
    final t = _pick(cands);
    final units = pack.spellUnits(t);
    final extra = switch (level) { 1 => 2, 2 => 3, 3 => 3, _ => 4 };
    final tiles = [...units, ...pack.spellDistractors(t, level, extra)]..shuffle(rng);
    return Item(
      id: 'sp:${t.text}',
      skill: Skill.spelling,
      level: level,
      kind: ItemKind.build,
      prompt: pack.p('spell'),
      say: t.text,
      emoji: t.emoji,
      answer: units,
      tiles: tiles,
      hint: 'Say the word slowly. What do you hear first?',
      replaySay: t.text,
    );
  }

  // ---------------- Comprehension ----------------
  Item _story(int level, Set<Pool> forms, Set<String> used) {
    final cands = _prefer<Story>(pack.stories, (s) => forms.contains(s.form), (s) => !used.contains('st:${s.id}'));
    final s = _pick(cands);
    final q = s.qs.firstWhere((x) => x.level == level, orElse: () => s.qs.last);
    final opts = [
      for (var i = 0; i < q.options.length; i++)
        Opt(q.options[i], say: q.options[i], tag: i == q.correct ? null : q.tag),
    ];
    return _shuffleOpts('st:${s.id}:${q.level}', Skill.comprehension, level, pack.p('story'), '${s.text}  ${q.q}', opts,
        q.correct,
        stimulus: q.q, emoji: s.emoji, passage: s.text, hint: 'Look back at the story for the answer.',
        replay: s.text);
  }

  /// Classifies the wrong answer when a build item was submitted.
  String spellingTag(List<String> got, List<String> want) => pack.spellingError(got, want);
}
