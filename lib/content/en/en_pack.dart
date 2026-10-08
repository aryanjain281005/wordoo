import 'dart:math';
import '../content_pack.dart';
import 'en_features.dart';
import 'en_stories.dart';
import 'word_data.dart';

class EnglishGameContent extends GameContentPack {
  @override
  String get code => 'en';
  @override
  String get tts => 'en-IN';

  static final List<WordEntry> _words = () {
    final byText = <String, WordEntry>{};
    for (final row in enWordData) {
      final parts = row.split('|');
      final raw = parts[0];
      final emoji = parts.length > 1 ? parts[1] : null;
      final e = EnFeatures.tag(raw, emoji: emoji);
      final prev = byText[e.text];
      if (prev == null || (prev.emoji == null && e.emoji != null) || (!prev.irregular && e.irregular) || (!prev.common && e.common)) {
        byText[e.text] = EnFeatures.tag(
          '${(e.common || (prev?.common ?? false)) ? '*' : ''}${(e.irregular || (prev?.irregular ?? false)) ? '!' : ''}${e.text}',
          emoji: e.emoji ?? prev?.emoji,
        );
      }
    }
    // a picture may only stand for one word (otherwise picture choices become ambiguous)
    final usedEmoji = <String>{};
    final out = <WordEntry>[];
    for (final w in byText.values) {
      if (w.emoji != null && !usedEmoji.add(w.emoji!)) {
        out.add(EnFeatures.tag('${w.common ? '*' : ''}${w.irregular ? '!' : ''}${w.text}'));
      } else {
        out.add(w);
      }
    }
    return out;
  }();

  @override
  List<WordEntry> get words => _words;

  static const _graphemes = [
    // step 1–4: single letters (Jolly-Phonics style order)
    GraphemeEntry('s', 'sss', 1), GraphemeEntry('a', 'a, like in apple', 1), GraphemeEntry('t', 'tuh', 1), GraphemeEntry('p', 'puh', 1),
    GraphemeEntry('i', 'i, like in insect', 1), GraphemeEntry('n', 'nnn', 1),
    GraphemeEntry('m', 'mmm', 2), GraphemeEntry('d', 'duh', 2), GraphemeEntry('g', 'guh', 2), GraphemeEntry('o', 'o, like in octopus', 2),
    GraphemeEntry('c', 'kuh', 2), GraphemeEntry('k', 'kuh', 2),
    GraphemeEntry('e', 'e, like in egg', 3), GraphemeEntry('u', 'u, like in umbrella', 3), GraphemeEntry('r', 'rrr', 3), GraphemeEntry('h', 'huh', 3),
    GraphemeEntry('f', 'fff', 3), GraphemeEntry('l', 'lll', 3),
    GraphemeEntry('j', 'juh', 4), GraphemeEntry('v', 'vvv', 4), GraphemeEntry('w', 'wuh', 4), GraphemeEntry('x', 'ks', 4),
    GraphemeEntry('y', 'yuh', 4), GraphemeEntry('z', 'zzz', 4), GraphemeEntry('qu', 'kwuh', 4),
    // step 5: look-alike letters
    GraphemeEntry('b', 'buh', 5, ['d', 'p']), GraphemeEntry('d', 'duh', 5, ['b', 'q']), GraphemeEntry('p', 'puh', 5, ['q', 'b']),
    GraphemeEntry('q', 'kwuh', 5, ['p', 'g']), GraphemeEntry('n', 'nnn', 5, ['m', 'u']), GraphemeEntry('m', 'mmm', 5, ['n', 'w']),
    // step 6: consonant digraphs
    GraphemeEntry('sh', 'shh', 6, ['ch', 'th']), GraphemeEntry('ch', 'ch, like in chair', 6, ['sh', 'th']), GraphemeEntry('th', 'th, like in thumb', 6, ['sh', 'ch']),
    GraphemeEntry('ng', 'ng, like in ring', 6, ['nk', 'n']), GraphemeEntry('ck', 'kuh, like in duck', 6, ['k', 'ch']),
    // step 7: long-vowel teams
    GraphemeEntry('ee', 'ee, like in tree', 7, ['ea', 'ai']), GraphemeEntry('oa', 'oh, like in boat', 7, ['ow', 'oo']), GraphemeEntry('ai', 'ay, like in rain', 7, ['ay', 'ee']),
    GraphemeEntry('oo', 'oo, like in moon', 7, ['ou', 'oa']), GraphemeEntry('ay', 'ay, like in play', 7, ['ai', 'ey']),
    // step 8: r-controlled and diphthongs
    GraphemeEntry('ar', 'ar, like in car', 8, ['or', 'er']), GraphemeEntry('or', 'or, like in fork', 8, ['ar', 'ur']), GraphemeEntry('er', 'er, like in her', 8, ['ir', 'ar']),
    GraphemeEntry('ou', 'ow, like in cloud', 8, ['ow', 'oo']), GraphemeEntry('oi', 'oy, like in coin', 8, ['oy', 'ou']),
    // step 9: trickier spellings
    GraphemeEntry('igh', 'eye, like in light', 9, ['ie', 'i']), GraphemeEntry('ew', 'oo, like in new', 9, ['ue', 'oo']), GraphemeEntry('aw', 'aw, like in saw', 9, ['au', 'or']),
    GraphemeEntry('ph', 'fff, like in phone', 9, ['f', 'wh']), GraphemeEntry('wh', 'wuh, like in when', 9, ['w', 'ph']),
    // step 10: advanced patterns
    GraphemeEntry('tch', 'ch, like in match', 10, ['ch', 'sh']), GraphemeEntry('dge', 'juh, like in bridge', 10, ['ge', 'j']), GraphemeEntry('kn', 'nnn, like in knee', 10, ['n', 'kw']),
    GraphemeEntry('wr', 'rrr, like in write', 10, ['r', 'wh']), GraphemeEntry('tion', 'shun, like in station', 10, ['sion', 'shun']),
  ];

  @override
  List<GraphemeEntry> get graphemes => _graphemes;

  @override
  List<StoryEntry> get stories => enStories;

  @override
  Map<String, String> get prompts => const {
        'firstSound': 'Which one starts like {w}?',
        'endSound': 'Which one ends like {w}?',
        'rhyme': 'Which one rhymes with {w}?',
        'blend': 'Put the sounds together!',
        'clap': 'Tap the drum for every beat in {w}!',
        'delete': 'Say {w} without the {r} sound.',
        'deleteMid': 'Say {w}, but leave out the {r} sound.',
        'swap': 'Say {w}. Now change {r} to {x}.',
        'letter': 'Which letters make this sound?',
        'decode': 'Blend the sounds. Which word is it?',
        'decodeHear': 'Read it, then tap the word you hear.',
        'decodeNon': 'An alien word! How do we say it?',
        'find': 'Find the word you hear',
        'spell': 'Build the word',
        'story': 'Read and answer',
      };

  static const _say = {
    'c': 'kuh', 'k': 'kuh', 'a': 'ah', 'e': 'eh', 'i': 'ih', 'o': 'aw', 'u': 'uh', 'b': 'buh', 'd': 'duh', 'f': 'fff', 'g': 'guh',
    'h': 'huh', 'j': 'juh', 'l': 'lll', 'm': 'mmm', 'n': 'nnn', 'p': 'puh', 'r': 'rrr', 's': 'sss', 't': 'tuh', 'v': 'vvv',
    'w': 'wuh', 'x': 'ks', 'y': 'yuh', 'z': 'zzz', 'sh': 'shh', 'ch': 'chuh', 'th': 'thh', 'ck': 'kuh', 'ng': 'ng', 'qu': 'kwuh',
    'ee': 'ee', 'ea': 'ee', 'oa': 'oh', 'ai': 'ay', 'ay': 'ay', 'oo': 'oo', 'ou': 'ow', 'ow': 'ow', 'oi': 'oy', 'oy': 'oy',
    'ar': 'ar', 'or': 'or', 'er': 'er', 'ir': 'er', 'ur': 'er', 'aw': 'aw', 'ew': 'oo', 'ie': 'eye', 'igh': 'eye', 'ue': 'oo',
    'll': 'lll', 'ss': 'sss', 'ff': 'fff', 'zz': 'zzz', 'ph': 'fff', 'wh': 'wuh', 'kn': 'nnn', 'wr': 'rrr', 'tch': 'chuh', 'dge': 'juh', 'tion': 'shun',
  };

  @override
  String sayUnit(String unit) => _say[unit] ?? unit;

  // ---------------- made-up words ----------------
  static const _onsets1 = ['b', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'r', 's', 't', 'v', 'z'];
  static const _onsets2 = ['bl', 'br', 'cl', 'cr', 'dr', 'fl', 'fr', 'gl', 'gr', 'pl', 'pr', 'sk', 'sl', 'sm', 'sn', 'sp', 'st', 'sw', 'tr'];
  static const _digraphOn = ['sh', 'ch', 'th'];
  static const _short = ['a', 'e', 'i', 'o', 'u'];
  static const _teams = ['ee', 'oa', 'ai', 'oo', 'ar', 'or'];
  static const _codas = ['b', 'd', 'g', 'k', 'm', 'n', 'p', 't', 'x'];
  static const _codas2 = ['nd', 'mp', 'st', 'nk', 'lt', 'sk', 'ft'];

  @override
  List<WordEntry> nonwords(int step, int count, int seed) {
    final rng = Random(seed);
    final real = {for (final w in _words) w.text};
    final out = <WordEntry>[];
    var guard = 0;
    while (out.length < count && guard++ < 500) {
      String w;
      String pick(List<String> l) => l[rng.nextInt(l.length)];
      if (step <= 7) {
        w = pick(_onsets1) + pick(_short) + pick(_codas);
      } else if (step == 8) {
        w = (rng.nextBool() ? pick(_onsets2) + pick(_short) + pick(_codas) : pick(_onsets1) + pick(_short) + pick(_codas2));
      } else if (step == 9) {
        w = (rng.nextBool() ? pick(_digraphOn) : pick(_onsets1)) + pick(_teams) + pick(_codas);
      } else {
        w = pick(_onsets1) + pick(_short) + pick(_codas) + pick(_onsets1) + pick(_short) + pick(_codas);
      }
      if (real.contains(w) || out.any((o) => o.text == w)) continue;
      final t = EnFeatures.tag(w);
      out.add(WordEntry(
        text: t.text,
        units: t.units,
        syllables: t.syllables,
        digraphs: t.digraphs,
        blends: t.blends,
        vowelTeams: t.vowelTeams,
        silentE: t.silentE,
        irregular: false,
        common: false,
        difficulty: (t.difficulty + 2.0).clamp(1, 10),
        nonword: true,
        rime: t.rime,
      ));
    }
    return out;
  }

  // ---------------- visual confusions ----------------
  @override
  List<String> confusions(String t, int seed) {
    final rng = Random(seed);
    final out = <String>[];
    void add(String s) {
      if (s != t && s.isNotEmpty && !out.contains(s)) out.add(s);
    }

    const flip = {'b': 'd', 'd': 'b', 'p': 'q', 'q': 'p', 'm': 'n', 'n': 'm', 'u': 'n', 'w': 'm'};
    for (var i = 0; i < t.length; i++) {
      if (flip.containsKey(t[i])) {
        add(t.substring(0, i) + flip[t[i]]! + t.substring(i + 1));
        break;
      }
    }
    if (t.length >= 3) {
      final i = 1 + rng.nextInt(t.length - 2);
      add(t.substring(0, i) + t[i + 1] + t[i] + t.substring(i + 2)); // transposition
    }
    const vow = 'aeiou';
    for (var i = 0; i < t.length; i++) {
      final v = vow.indexOf(t[i]);
      if (v >= 0) {
        add(t.substring(0, i) + vow[(v + 1 + rng.nextInt(4)) % 5] + t.substring(i + 1));
        break;
      }
    }
    if (t.length >= 4) add(t.substring(0, t.length - 1)); // missing last letter
    if (t.endsWith('e') && t.length >= 4) add(t.substring(0, t.length - 1));
    add(t.length >= 3 ? t.substring(0, t.length - 1) + (t.endsWith('t') ? 'd' : 't') : '${t}e');
    return out;
  }

  // ---------------- template stories for early steps ----------------
  static const _names = [('Riya', 'she'), ('Aman', 'he'), ('Tara', 'she'), ('Kabir', 'he'), ('Meera', 'she'), ('Sam', 'he'), ('Zoya', 'she'), ('Arjun', 'he')];
  static const _places = [('the park', '🌳'), ('school', '🏫'), ('the market', '🛒'), ('the beach', '🏖️'), ('the farm', '🚜'), ('the zoo', '🦁')];
  static const _animals = [('a dog', '🐶'), ('a cat', '🐱'), ('a duck', '🦆'), ('a cow', '🐄'), ('a frog', '🐸'), ('a monkey', '🐒'), ('a fish', '🐟')];
  static const _foods = [('a mango', '🥭'), ('a banana', '🍌'), ('an apple', '🍎'), ('a cookie', '🍪'), ('some rice', '🍚'), ('a sandwich', '🥪')];

  @override
  StoryEntry storyFromTemplate(int step, int seed) {
    final rng = Random(seed);
    T pick<T>(List<T> l) => l[rng.nextInt(l.length)];
    List<T> three<T>(List<T> l, T first) {
      final rest = (l.where((x) => x != first).toList()..shuffle(rng)).take(2).toList();
      return [first, ...rest];
    }

    final (name, he) = pick(_names);
    final place = pick(_places), animal = pick(_animals), food = pick(_foods);
    final He = he[0].toUpperCase() + he.substring(1);
    final text = step <= 1
        ? '$name went to ${place.$1}. $He saw ${animal.$1}.'
        : (step == 2 ? '$name went to ${place.$1}. $He saw ${animal.$1}. Then $he ate ${food.$1}.' : '$name went to ${place.$1}. $He was very hungry, so $he ate ${food.$1}. Then $he played with ${animal.$1}.');
    final qs = <StoryQuestion>[
      StoryQuestion('Where did $name go?', [for (final p in three(_places, place)) (p.$1, p.$2)], 'detail'),
      StoryQuestion('What did $name see?', [for (final a in three(_animals, animal)) (a.$1, a.$2)], 'detail'),
      if (step >= 2) StoryQuestion('What did $name eat?', [for (final f in three(_foods, food)) (f.$1, f.$2)], 'detail'),
      if (step >= 3) StoryQuestion('Why did $name eat?', [('$He was hungry', null), ('$He was sleepy', null), ('$He was cold', null)], 'cause'),
    ];
    return StoryEntry('tpl:$step:$seed', '$name’s day', place.$2, text, step, qs);
  }
}
