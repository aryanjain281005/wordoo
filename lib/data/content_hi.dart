import 'dart:math';
import 'lang.dart';

class HindiPack extends LangPack {
  @override
  String get code => 'hi';
  @override
  String get name => 'Hindi';
  @override
  String get native => 'हिन्दी';
  @override
  String get tts => 'hi-IN';
  // Hindi is a demo: prologue, map, Sound Forest and the screening only (see AppState.hindi).
  @override
  bool get available => true;

  static List<Word> _build(List<List<Object>> rows) {
    final counts = <int, int>{};
    return rows.map((r) {
      final lvl = r[0] as int;
      final i = counts[lvl] = (counts[lvl] ?? -1) + 1;
      final units = (r[3] as String).split('-');
      return Word(r[1] as String, r[2] as String, units, lvl, formFor(i), rime: units.last);
    }).toList();
  }

  static final List<Word> _words = _build([
    // Level 1 — simple aksharas, no matras
    [1, 'कमल', '🌸', 'क-म-ल'],
    [1, 'नल', '🚰', 'न-ल'],
    [1, 'घर', '🏠', 'घ-र'],
    [1, 'फल', '🍎', 'फ-ल'],
    [1, 'जल', '💧', 'ज-ल'],
    [1, 'बस', '🚌', 'ब-स'],
    [1, 'कलम', '🖊️', 'क-ल-म'],
    [1, 'मगर', '🐊', 'म-ग-र'],
    [1, 'पल', '⏱️', 'प-ल'],
    // Level 2 — matras
    [2, 'मोर', '🦚', 'मो-र'],
    [2, 'चूहा', '🐭', 'चू-हा'],
    [2, 'केला', '🍌', 'के-ला'],
    [2, 'सेब', '🍏', 'से-ब'],
    [2, 'भालू', '🐻', 'भा-लू'],
    [2, 'पानी', '🌊', 'पा-नी'],
    [2, 'मूली', '🥕', 'मू-ली'],
    [2, 'गाय', '🐄', 'गा-य'],
    [2, 'मेला', '🎡', 'मे-ला'],
    [2, 'टोपी', '👒', 'टो-पी'],
    // Level 3 — conjuncts and nasal marks
    [3, 'स्कूल', '🏫', 'स्कू-ल'],
    [3, 'पत्ता', '🍃', 'प-त्ता'],
    [3, 'कुत्ता', '🐕', 'कु-त्ता'],
    [3, 'बंदर', '🐒', 'बं-द-र'],
    [3, 'चाँद', '🌙', 'चाँ-द'],
    [3, 'रंग', '🎨', 'रं-ग'],
    [3, 'चम्मच', '🥄', 'च-म्म-च'],
    [3, 'बत्तख', '🦆', 'ब-त्त-ख'],
    // Level 4 — longer words
    [4, 'तितली', '🦋', 'ति-त-ली'],
    [4, 'मछली', '🐟', 'म-छ-ली'],
    [4, 'गुब्बारा', '🎈', 'गु-ब्बा-रा'],
    [4, 'खरगोश', '🐰', 'ख-र-गो-श'],
    [4, 'कंप्यूटर', '💻', 'कं-प्यू-ट-र'],
    [4, 'बिल्ली', '🐱', 'बि-ल्ली'],
    [4, 'हवाईजहाज़', '✈️', 'ह-वा-ई-ज-हा-ज़'],
  ]);

  static final List<Graph> _graphs = () {
    final rows = <List<Object>>[
      [1, 'क', 'क'], [1, 'म', 'म'], [1, 'न', 'न'], [1, 'ल', 'ल'], [1, 'र', 'र'],
      [1, 'प', 'प'], [1, 'स', 'स'], [1, 'ह', 'ह'], [1, 'ज', 'ज'], [1, 'ट', 'ट'],
      [2, 'ब', 'ब', 'व,य'], [2, 'व', 'व', 'ब,य'], [2, 'घ', 'घ', 'ध,भ'], [2, 'ध', 'ध', 'घ,भ'],
      [2, 'म', 'म', 'भ,न'], [2, 'प', 'प', 'फ,य'], [2, 'फ', 'फ', 'प,क'], [2, 'च', 'च', 'ज,व'],
      [3, 'का', 'का'], [3, 'कि', 'कि'], [3, 'की', 'की'], [3, 'कु', 'कु'], [3, 'कू', 'कू'],
      [3, 'के', 'के'], [3, 'को', 'को'],
      [4, 'क्ष', 'क्ष'], [4, 'त्र', 'त्र'], [4, 'ज्ञ', 'ज्ञ'], [4, 'श्र', 'श्र'], [4, 'प्र', 'प्र'],
      [4, 'द्व', 'द्व'], [4, 'स्त', 'स्त'], [4, 'ट्र', 'ट्र'],
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
    NonWord(['क', 'ब', 'ल'], 'कबल', ['कबर', 'कपल'], Pool.a),
    NonWord(['म', 'त', 'ज'], 'मतज', ['मतर', 'मदज'], Pool.b),
    NonWord(['सू', 'क', 'ल'], 'सूकल', ['सूकर', 'सूपल'], Pool.p),
    NonWord(['ग', 'मी', 'र'], 'गमीर', ['गभीर', 'गमार'], Pool.p),
    NonWord(['चि', 'न', 'ट'], 'चिनट', ['चिनर', 'चिपट'], Pool.p),
  ];

  static const _deletions = [
    Deletion('कमल', '🌸', 'क', 'मल', ['कम', 'कल'], Pool.a),
    Deletion('चाँद', '🌙', 'चाँ', 'द', ['चा', 'चाद'], Pool.b),
    Deletion('मछली', '🐟', 'म', 'छली', ['मछ', 'मली'], Pool.p),
    Deletion('तितली', '🦋', 'ति', 'तली', ['तिली', 'तित'], Pool.p),
    Deletion('बंदर', '🐒', 'बं', 'दर', ['बंद', 'बर'], Pool.p),
  ];

  static const _stories = [
    Story('hi-a', Pool.a, 'मीना की टोपी', '👒🌧️🦆',
        'मीना की लाल टोपी पार्क में खो गई। फिर बारिश होने लगी, इसलिए मीना को ठंड लगी। एक बतख को टोपी मिली और उसने लौटा दी।', [
      StoryQ(1, 'Wrong detail', 'मीना ने क्या खोया?', ['लाल टोपी', 'गेंद', 'पतंग'], 0),
      StoryQ(2, 'Cause / effect error', 'मीना को ठंड क्यों लगी?', ['बारिश होने लगी', 'जूते खो गए', 'उसे नींद आई'], 0),
      StoryQ(3, 'Prediction error', 'आगे मीना क्या करेगी?', ['टोपी पहनकर मुस्कुराएगी', 'टोपी फेंक देगी', 'बारिश में सो जाएगी'], 0),
      StoryQ(4, 'Inference error', 'अंत में मीना को कैसा लगा?', ['खुशी', 'गुस्सा', 'डर'], 0),
    ]),
    Story('hi-b', Pool.b, 'रवि का बीज', '🌱💧🌻',
        'रवि ने गमले में बीज बोया। वह रोज़ पानी देता था। कुछ दिनों बाद हरा पौधा निकला।', [
      StoryQ(1, 'Wrong detail', 'रवि ने क्या बोया?', ['बीज', 'जूते', 'पत्थर'], 0),
      StoryQ(2, 'Cause / effect error', 'पौधा क्यों उगा?', ['रवि रोज़ पानी देता था', 'रात हो गई थी', 'चिड़िया बैठी थी'], 0),
      StoryQ(3, 'Prediction error', 'आगे पौधा क्या करेगा?', ['बड़ा होगा', 'उड़ जाएगा', 'पत्थर बन जाएगा'], 0),
      StoryQ(4, 'Inference error', 'रवि को कैसा लगा?', ['गर्व', 'नींद', 'दुख'], 0),
    ]),
    Story('hi-p1', Pool.p, 'प्यासी चिड़िया', '🐦🏺💧',
        'एक चिड़िया को बहुत प्यास लगी। उसे घड़ा दिखा, पर पानी बहुत नीचे था। उसने घड़े में कंकड़ डाले। पानी ऊपर आ गया।', [
      StoryQ(1, 'Wrong detail', 'चिड़िया को क्या लगी थी?', ['प्यास', 'भूख', 'नींद'], 0),
      StoryQ(2, 'Cause / effect error', 'पानी ऊपर क्यों आया?', ['उसने कंकड़ डाले', 'बारिश हुई', 'घड़ा टूट गया'], 0),
      StoryQ(3, 'Prediction error', 'आगे चिड़िया क्या करेगी?', ['पानी पिएगी', 'सो जाएगी', 'घर जाएगी'], 0),
      StoryQ(4, 'Inference error', 'चिड़िया कैसी थी?', ['समझदार', 'आलसी', 'डरपोक'], 0),
    ]),
    Story('hi-p2', Pool.p, 'हाथी और चूहा', '🐘🐭🏡',
        'एक चूहा रास्ता भूल गया। हाथी ने उसे अपनी पीठ पर बैठाया और उसके घर छोड़ दिया।', [
      StoryQ(1, 'Wrong detail', 'हाथी ने चूहे को कहाँ बैठाया?', ['पीठ पर', 'सिर पर', 'नाव में'], 0),
      StoryQ(2, 'Cause / effect error', 'हाथी ने चूहे की मदद क्यों की?', ['वह रास्ता भूल गया था', 'वह भूखा था', 'वह सो रहा था'], 0),
      StoryQ(3, 'Prediction error', 'आगे चूहा क्या कहेगा?', ['धन्यवाद', 'चलो भागो', 'मैं सो रहा हूँ'], 0),
      StoryQ(4, 'Inference error', 'हाथी कैसा था?', ['दयालु', 'गुस्सैल', 'आलसी'], 0),
    ]),
  ];

  static const _prompts = {
    'firstSound': '{w} जैसी पहली आवाज़ किसकी है?',
    'rhyme': '{w} जैसी आख़िरी आवाज़ किसकी है?',
    'blend': 'आवाज़ें जोड़ो!',
    'delete': '{w} में से {r} हटाओ',
    'letter': 'जो आवाज़ सुनी, वह अक्षर चुनो',
    'decode': 'आवाज़ें जोड़ो। कौन सा शब्द बना?',
    'decodeNon': 'जोड़कर पढ़ो! कैसे बोलेंगे?',
    'find': 'जो शब्द सुना, उसे ढूँढो',
    'spell': 'शब्द बनाओ',
    'story': 'पढ़ो और जवाब दो',
  };

  static const _matras = ['ा', 'ि', 'ी', 'ु', 'ू', 'े', 'ै', 'ो', 'ौ', 'ं', 'ँ'];
  static const _matraSwap = {
    'ा': ['ी', 'े'], 'ि': ['ी', 'ा'], 'ी': ['ि', 'ा'], 'ु': ['ू', 'ा'], 'ू': ['ु', 'ी'],
    'े': ['ै', 'ा'], 'ै': ['े', 'ा'], 'ो': ['ौ', 'ा'], 'ौ': ['ो', 'ा'], 'ं': ['ँ'], 'ँ': ['ं'],
  };
  static const _lookalike = {
    'ब': 'व', 'व': 'ब', 'घ': 'ध', 'ध': 'घ', 'म': 'भ', 'भ': 'म', 'प': 'फ', 'फ': 'प', 'च': 'ज', 'ज': 'च',
    'ट': 'ठ', 'ठ': 'ट', 'र': 'ख', 'ख': 'र', 'क': 'फ', 'न': 'त', 'त': 'न', 'ल': 'ला', 'स': 'म', 'ह': 'ड',
  };
  static const _consonants = ['क', 'ख', 'ग', 'च', 'ज', 'त', 'द', 'न', 'प', 'ब', 'म', 'य', 'र', 'ल', 'व', 'स', 'ह'];

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
  String firstKey(Word w) => String.fromCharCode(w.text.runes.first);

  @override
  List<String> spellUnits(Word w) => w.units;

  @override
  String sayUnit(String u) => u;

  /// Variants of one akshara unit with a wrong matra or a look-alike consonant.
  List<String> _variants(String u) {
    final out = <String>[];
    final runes = u.split('');
    final last = runes.last;
    if (_matras.contains(last)) {
      final base = u.substring(0, u.length - last.length);
      for (final m in _matraSwap[last] ?? const <String>[]) {
        out.add(base + m);
      }
    } else if (u.length == 1) {
      out.add('${u}ा');
      out.add('${u}ी');
    }
    final firstCh = runes.first;
    if (_lookalike.containsKey(firstCh) && _lookalike[firstCh]!.length == 1) {
      out.add(_lookalike[firstCh]! + u.substring(firstCh.length));
    }
    return out;
  }

  @override
  List<String> spellDistractors(Word w, int level, int count) {
    final have = w.units.toSet();
    final out = <String>[];
    if (level >= 2) {
      for (final u in w.units) {
        for (final v in _variants(u)) {
          if (!have.contains(v) && !out.contains(v)) out.add(v);
        }
      }
    }
    final rng = Random(w.text.hashCode);
    var guard = 0;
    while (out.length < count && guard++ < 100) {
      final c = _consonants[rng.nextInt(_consonants.length)];
      if (!have.contains(c) && !out.contains(c)) out.add(c);
    }
    out.shuffle(Random(w.text.length));
    return out.take(count).toList();
  }

  @override
  List<String> confusions(Word w) {
    final out = <String>[];
    void add(String s) {
      if (s != w.text && !out.contains(s)) out.add(s);
    }
    for (var i = 0; i < w.units.length; i++) {
      for (final v in _variants(w.units[i])) {
        final copy = [...w.units];
        copy[i] = v;
        add(copy.join());
      }
    }
    if (w.units.length >= 2) {
      final copy = [...w.units];
      final t = copy[0];
      copy[0] = copy[1];
      copy[1] = t;
      add(copy.join());
    }
    return out;
  }

  String _base(String u) => u.runes.isEmpty ? u : String.fromCharCode(u.runes.first);

  @override
  String spellingError(List<String> got, List<String> want) {
    if (got.length < want.length) return 'Missing unit';
    if (got.length > want.length) return 'Extra unit';
    final diff = <int>[for (var i = 0; i < want.length; i++) if (got[i] != want[i]) i];
    if (diff.length == 2 && diff[1] == diff[0] + 1 && got[diff[0]] == want[diff[1]] && got[diff[1]] == want[diff[0]]) {
      return 'Swapped order';
    }
    if (diff.isNotEmpty && diff.every((i) => _base(got[i]) == _base(want[i]))) return 'Wrong matra';
    return 'Wrong akshara';
  }
}
