import 'dart:math';
import 'lang.dart';

class EnglishPack extends LangPack {
  @override
  String get code => 'en';
  @override
  String get name => 'English';
  @override
  String get native => 'English';
  @override
  String get tts => 'en-US';
  @override
  bool get available => true;

  static List<Word> _build(List<List<Object>> rows) {
    final counts = <int, int>{};
    return rows.map((r) {
      final lvl = r[0] as int;
      final i = counts[lvl] = (counts[lvl] ?? -1) + 1;
      return Word(r[1] as String, r[2] as String, (r[3] as String).split('-'), lvl, formFor(i),
          rime: r.length > 4 ? r[4] as String : null);
    }).toList();
  }

  static final List<Word> _words = _build([
    // Level 1 — simple CVC words
    [1, 'cat', '🐱', 'c-a-t', 'at'],
    [1, 'dog', '🐶', 'd-o-g'],
    [1, 'pig', '🐷', 'p-i-g'],
    [1, 'sun', '☀️', 's-u-n', 'un'],
    [1, 'bus', '🚌', 'b-u-s'],
    [1, 'hat', '🎩', 'h-a-t', 'at'],
    [1, 'pen', '🖊️', 'p-e-n'],
    [1, 'bed', '🛏️', 'b-e-d'],
    [1, 'cup', '🥤', 'c-u-p'],
    [1, 'nut', '🥜', 'n-u-t'],
    [1, 'bat', '🦇', 'b-a-t', 'at'],
    [1, 'rat', '🐀', 'r-a-t', 'at'],
    [1, 'bun', '🍞', 'b-u-n', 'un'],
    [1, 'fox', '🦊', 'f-o-x'],
    // Level 2 — digraphs, blends, vowel teams
    [2, 'ship', '🚢', 'sh-i-p'],
    [2, 'fish', '🐟', 'f-i-sh', 'ish'],
    [2, 'frog', '🐸', 'f-r-o-g'],
    [2, 'drum', '🥁', 'd-r-u-m'],
    [2, 'moon', '🌙', 'm-oo-n', 'oon'],
    [2, 'tree', '🌳', 't-r-ee', 'ee'],
    [2, 'star', '⭐', 's-t-ar', 'ar'],
    [2, 'cake', '🎂', 'c-a-k-e'],
    [2, 'duck', '🦆', 'd-u-ck'],
    [2, 'chick', '🐤', 'ch-i-ck'],
    [2, 'car', '🚗', 'c-ar', 'ar'],
    [2, 'bee', '🐝', 'b-ee', 'ee'],
    [2, 'spoon', '🥄', 's-p-oo-n', 'oon'],
    [2, 'ring', '💍', 'r-i-ng', 'ing'],
    [2, 'king', '👑', 'k-i-ng', 'ing'],
    [2, 'dish', '🍽️', 'd-i-sh', 'ish'],
    [2, 'shell', '🐚', 'sh-e-ll', 'ell'],
    [2, 'bell', '🔔', 'b-e-ll', 'ell'],
    // Level 3 — two-syllable words
    [3, 'rabbit', '🐰', 'rab-bit'],
    [3, 'bottle', '🍼', 'bot-tle'],
    [3, 'rocket', '🚀', 'rock-et'],
    [3, 'planet', '🌍', 'plan-et'],
    [3, 'flower', '🌸', 'flow-er'],
    [3, 'pencil', '✏️', 'pen-cil'],
    [3, 'dragon', '🐉', 'drag-on'],
    [3, 'monkey', '🐒', 'mon-key'],
    [3, 'turtle', '🐢', 'tur-tle'],
    [3, 'garden', '🌷', 'gar-den'],
    // Level 4 — longer words
    [4, 'elephant', '🐘', 'el-e-phant'],
    [4, 'umbrella', '☂️', 'um-brel-la'],
    [4, 'butterfly', '🦋', 'but-ter-fly'],
    [4, 'pineapple', '🍍', 'pine-ap-ple'],
    [4, 'dinosaur', '🦖', 'di-no-saur'],
    [4, 'crocodile', '🐊', 'croc-o-dile'],
    [4, 'computer', '💻', 'com-pu-ter'],
    [4, 'strawberry', '🍓', 'straw-ber-ry'],
  ]);

  static final List<Graph> _graphs = () {
    final rows = <List<Object>>[
      // level, text, say, similar
      [1, 'm', 'mmm'], [1, 's', 'sss'], [1, 't', 'tuh'], [1, 'p', 'puh'], [1, 'n', 'nnn'],
      [1, 'f', 'fff'], [1, 'l', 'lll'], [1, 'h', 'huh'], [1, 'r', 'rrr'], [1, 'g', 'guh'],
      [2, 'b', 'buh', 'd,p'], [2, 'd', 'duh', 'b,p'], [2, 'p', 'puh', 'b,q'], [2, 'm', 'mmm', 'n,w'],
      [2, 'n', 'nnn', 'm,h'], [2, 'w', 'wuh', 'm,v'], [2, 'f', 'fff', 't,l'], [2, 'g', 'guh', 'q,y'],
      [3, 'sh', 'shh'], [3, 'ch', 'chuh'], [3, 'th', 'thh'], [3, 'ee', 'ee'], [3, 'oa', 'oh'],
      [3, 'ai', 'ay'], [3, 'oo', 'oo'],
      [4, 'igh', 'eye'], [4, 'ph', 'fff'], [4, 'kn', 'nnn'], [4, 'wr', 'rrr'], [4, 'ow', 'ow'],
      [4, 'tion', 'shun'], [4, 'ur', 'er'], [4, 'ew', 'oo'],
    ];
    final counts = <int, int>{};
    return rows.map((r) {
      final lvl = r[0] as int;
      final i = counts[lvl] = (counts[lvl] ?? -1) + 1;
      return Graph(r[1] as String, r[2] as String, lvl, formFor(i),
          similar: r.length > 3 ? (r[3] as String).split(',') : const []);
    }).toList();
  }();

  static const _nonWords = [
    NonWord(['f', 'a', 'p'], 'fap', ['fip', 'fop'], Pool.a),
    NonWord(['sh', 'e', 'p'], 'shep', ['ship', 'shap'], Pool.b),
    NonWord(['b', 'l', 'i', 'ck'], 'blick', ['black', 'block'], Pool.p),
    NonWord(['z', 'u', 'm'], 'zum', ['zim', 'zam'], Pool.p),
    NonWord(['t', 'r', 'u', 'ng'], 'trung', ['trang', 'tring'], Pool.p),
    NonWord(['ch', 'o', 'p'], 'chop', ['chap', 'chip'], Pool.p),
  ];

  static const _deletions = [
    Deletion('cat', '🐱', 'c', 'at', ['ca', 'ta'], Pool.a),
    Deletion('sun', '☀️', 's', 'un', ['su', 'sn'], Pool.b),
    Deletion('star', '⭐', 's', 'tar', ['sar', 'sta'], Pool.p),
    Deletion('bat', '🦇', 'b', 'at', ['ba', 'bt'], Pool.p),
    Deletion('bun', '🍞', 'b', 'un', ['bu', 'bn'], Pool.p),
    Deletion('plate', '🍽️', 'p', 'late', ['plat', 'pate'], Pool.p),
  ];

  static const _stories = [
    Story('en-a', Pool.a, 'Milo’s Hat', '🎩🌧️🦆',
        'Milo lost his red hat in the park. Then it began to rain, so Milo felt cold. A kind duck found the hat and gave it back.', [
      StoryQ(1, 'Wrong detail', 'What did Milo lose?', ['A red hat', 'A ball', 'A kite'], 0),
      StoryQ(2, 'Cause / effect error', 'Why did Milo feel cold?', ['It began to rain', 'He lost his shoes', 'He was sleepy'], 0),
      StoryQ(3, 'Prediction error', 'What will Milo do next?', ['Put the hat on and smile', 'Throw the hat away', 'Sleep in the rain'], 0),
      StoryQ(4, 'Inference error', 'How did Milo feel at the end?', ['Happy', 'Angry', 'Scared'], 0),
    ]),
    Story('en-b', Pool.b, 'Tia’s Seeds', '🌱💧🌻',
        'Tia planted seeds in a pot. She gave them water every day. After many days, a green plant came up.', [
      StoryQ(1, 'Wrong detail', 'What did Tia plant?', ['Seeds', 'Shoes', 'Stones'], 0),
      StoryQ(2, 'Cause / effect error', 'Why did the plant grow?', ['Tia gave it water', 'It was night', 'A bird sat there'], 0),
      StoryQ(3, 'Prediction error', 'What will the plant do next?', ['Grow bigger', 'Fly away', 'Turn into a stone'], 0),
      StoryQ(4, 'Inference error', 'How did Tia feel?', ['Proud', 'Sleepy', 'Sad'], 0),
    ]),
    Story('en-p1', Pool.p, 'Fox and the Berries', '🦊🍓🌳',
        'Milo was hungry. The berries were too high to reach. He stacked three logs and climbed up to eat.', [
      StoryQ(1, 'Wrong detail', 'What did Milo stack?', ['Logs', 'Books', 'Boxes'], 0),
      StoryQ(2, 'Cause / effect error', 'Why did Milo climb up?', ['To reach the berries', 'To say hello', 'To take a nap'], 0),
      StoryQ(3, 'Prediction error', 'What will Milo do next?', ['Eat the berries', 'Go to school', 'Paint a wall'], 0),
      StoryQ(4, 'Inference error', 'What kind of fox is Milo?', ['Clever', 'Lazy', 'Rude'], 0),
    ]),
    Story('en-p2', Pool.p, 'The Red Kite', '💨🧒☁️',
        'Leo had a red kite. The wind was strong, so the kite flew high. Then the string broke, and the kite floated away.', [
      StoryQ(1, 'Wrong detail', 'What colour was the kite?', ['Red', 'Blue', 'Green'], 0),
      StoryQ(2, 'Cause / effect error', 'Why did the kite fly high?', ['The wind was strong', 'It was heavy', 'It was raining'], 0),
      StoryQ(3, 'Sequence error', 'What happened last?', ['The kite floated away', 'Leo got the kite', 'The wind was strong'], 0),
      StoryQ(4, 'Inference error', 'How did Leo feel at the end?', ['Sad', 'Excited', 'Sleepy'], 0),
    ]),
    Story('en-p3', Pool.p, 'Lost Puppy', '🐶🏠🦴',
        'A little puppy got lost. A girl named Anu found him and took him home. She gave him a bone and a bed.', [
      StoryQ(1, 'Wrong detail', 'Who found the puppy?', ['Anu', 'Leo', 'Tia'], 0),
      StoryQ(2, 'Cause / effect error', 'Why did Anu take the puppy home?', ['He was lost', 'He was loud', 'He was fast'], 0),
      StoryQ(3, 'Prediction error', 'What will the puppy do next?', ['Eat and rest', 'Fly a kite', 'Go to school'], 0),
      StoryQ(4, 'Inference error', 'What kind of girl is Anu?', ['Kind', 'Mean', 'Shy'], 0),
    ]),
  ];

  static const _prompts = {
    'firstSound': 'Which one starts like {w}?',
    'rhyme': 'Which one ends like {w}?',
    'blend': 'Put the sounds together!',
    'delete': 'Say {w} without {r}',
    'letter': 'Tap the letter you hear',
    'decode': 'Blend the sounds. Which word?',
    'decodeNon': 'Blend it! How do we say it?',
    'find': 'Find the word you hear',
    'spell': 'Build the word',
    'story': 'Read and answer',
  };

  static const _sayMap = {
    'c': 'kuh', 'k': 'kuh', 'a': 'ah', 'e': 'eh', 'i': 'ih', 'o': 'aw', 'u': 'uh', 'b': 'buh', 'd': 'duh',
    'f': 'fff', 'g': 'guh', 'h': 'huh', 'j': 'juh', 'l': 'lll', 'm': 'mmm', 'n': 'nnn', 'p': 'puh', 'r': 'rrr',
    's': 'sss', 't': 'tuh', 'v': 'vvv', 'w': 'wuh', 'x': 'ks', 'z': 'zzz', 'sh': 'shh', 'ch': 'chuh', 'th': 'thh',
    'ee': 'ee', 'oo': 'oo', 'ai': 'ay', 'ar': 'ar', 'ck': 'kuh', 'ng': 'ng', 'll': 'lll',
  };

  @override
  List<Word> get words => _words;
  @override
  List<Graph> get graphs => _graphs;
  @override
  List<NonWord> get nonWords => _nonWords;
  @override
  List<Deletion> get deletions => _deletions;
  @override
  List<Story> get stories => _stories;
  @override
  Map<String, String> get prompts => _prompts;

  @override
  String firstKey(Word w) {
    final t = w.text;
    for (final d in ['sh', 'ch', 'th']) {
      if (t.startsWith(d)) return d;
    }
    return t[0];
  }

  @override
  List<String> spellUnits(Word w) => w.text.split('');

  @override
  String sayUnit(String u) => _sayMap[u] ?? u;

  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz';
  static const _lookalike = {
    'b': ['d', 'p'], 'd': ['b', 'q'], 'p': ['q', 'b'], 'q': ['p', 'g'], 'm': ['n', 'w'], 'n': ['m', 'h'],
    'a': ['e', 'o'], 'e': ['a', 'i'], 'i': ['l', 'e'], 'o': ['a', 'u'], 'u': ['o', 'n'], 't': ['f', 'l'],
    'f': ['t', 'l'], 'w': ['m', 'v'], 'g': ['q', 'y'],
  };

  @override
  List<String> spellDistractors(Word w, int level, int count) {
    final have = w.text.split('').toSet();
    final out = <String>[];
    if (level >= 2) {
      for (final ch in have) {
        for (final s in _lookalike[ch] ?? const <String>[]) {
          if (!have.contains(s) && !out.contains(s)) out.add(s);
        }
      }
    }
    final rng = Random(w.text.hashCode);
    while (out.length < count) {
      final c = _alphabet[rng.nextInt(26)];
      if (!have.contains(c) && !out.contains(c)) out.add(c);
    }
    return out.take(count).toList();
  }

  @override
  List<String> confusions(Word w) {
    final t = w.text;
    final out = <String>[];
    void add(String s) {
      if (s != t && !out.contains(s)) out.add(s);
    }
    // swap two letters
    if (t.length >= 3) add(t.substring(0, 1) + t[2] + t[1] + t.substring(3));
    // flip b/d/p/q
    const flip = {'b': 'd', 'd': 'b', 'p': 'q', 'q': 'p', 'm': 'n', 'n': 'm'};
    for (var i = 0; i < t.length; i++) {
      if (flip.containsKey(t[i])) {
        add(t.substring(0, i) + flip[t[i]]! + t.substring(i + 1));
        break;
      }
    }
    // change vowel
    const vow = 'aeiou';
    for (var i = 0; i < t.length; i++) {
      final v = vow.indexOf(t[i]);
      if (v >= 0) {
        add(t.substring(0, i) + vow[(v + 1) % 5] + t.substring(i + 1));
        add(t.substring(0, i) + vow[(v + 2) % 5] + t.substring(i + 1));
        break;
      }
    }
    // change last letter
    if (t.length >= 3) add(t.substring(0, t.length - 1) + (t.endsWith('t') ? 'd' : 't'));
    return out;
  }

  @override
  String spellingError(List<String> got, List<String> want) {
    if (got.length < want.length) return 'Missing unit';
    if (got.length > want.length) return 'Extra unit';
    final diff = <int>[for (var i = 0; i < want.length; i++) if (got[i] != want[i]) i];
    if (diff.length == 2 && diff[1] == diff[0] + 1 && got[diff[0]] == want[diff[1]] && got[diff[1]] == want[diff[0]]) {
      return 'Swapped order';
    }
    const vowels = 'aeiou';
    if (diff.isNotEmpty && diff.every((i) => vowels.contains(want[i]) && vowels.contains(got[i]))) {
      return 'Wrong vowel';
    }
    return 'Wrong letter';
  }
}
