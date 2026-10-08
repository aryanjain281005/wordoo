import 'bank.dart';
import 'models.dart';

class EnglishScreenBank extends ScreenBank {
  @override
  String get code => 'en';
  @override
  String get tts => 'en-IN';
  @override
  String get asr => 'en_IN';

  @override
  Map<String, String> get ui => const {
        'tapMic': 'Tap the mic and speak',
        'listening': 'I’m listening…',
        'again': 'I didn’t hear you. Try once more!',
        'nice': 'Nice!',
        'thanks': 'Great reading!',
        'go': 'Go!',
        'done': 'Done',
        'next': 'Next',
        'ready': 'Ready?',
        'noMic': 'Voice games need the phone app with microphone permission.',
      };

  static SItem _rhyme(String id, String pool, int d, String w, String e, List<ChoiceOpt> o) =>
      SItem(id: id, subtest: 'rhyme', pool: pool, difficulty: d, target: w, emoji: e, say: 'Which one rhymes with $w?', options: o);
  static SItem _first(String id, String pool, String sound, String letter, List<ChoiceOpt> o) =>
      SItem(id: id, subtest: 'firstSound', pool: pool, target: letter, say: 'Which one starts with $sound?', options: o);
  static SItem _manip(String id, String pool, int d, String say, List<String> o) =>
      SItem(id: id, subtest: 'phonemeManip', pool: pool, difficulty: d, say: say, options: o.map(aud).toList());
  static SItem _letter(String id, String pool, int d, String sound, List<String> o) =>
      SItem(id: id, subtest: 'letterSound', pool: pool, difficulty: d, say: sound, options: o.map((x) => ChoiceOpt(x)).toList());
  static SItem _name(String id, String pool, String e, String w, [List<String> acc = const []]) =>
      SItem(id: id, subtest: 'pictureNaming', pool: pool, emoji: e, target: w, accept: [w, ...acc]);
  static SItem _word(String id, String pool, int d, String w, [GradeBand? only]) =>
      SItem(id: id, subtest: 'wordReading', pool: pool, difficulty: d, target: w, only: only);
  static SItem _non(String id, String pool, int d, String w, [GradeBand? only]) =>
      SItem(id: id, subtest: 'nonwordReading', pool: pool, difficulty: d, target: w, only: only);
  static SItem _spell(String id, String pool, int d, String w, String e, String extra, [GradeBand? only]) =>
      SItem(id: id, subtest: 'spelling', pool: pool, difficulty: d, target: w, emoji: e, answer: w.split(''), distractors: extra.split(''), only: only);

  static final _items = <SItem>[
    // ---------- Rhyme ----------
    _rhyme('r1', 'A', 1, 'cat', '🐱', [pic('hat', '🎩'), pic('dog', '🐶'), pic('sun', '☀️')]),
    _rhyme('r2', 'A', 1, 'bee', '🐝', [pic('tree', '🌳'), pic('cup', '🥤'), pic('fish', '🐟')]),
    _rhyme('r3', 'A', 2, 'ring', '💍', [pic('king', '👑'), pic('rain', '🌧️'), pic('moon', '🌙')]),
    _rhyme('r4', 'A', 2, 'cake', '🎂', [pic('snake', '🐍'), pic('cap', '🧢'), pic('book', '📖')]),
    _rhyme('r5', 'A', 3, 'star', '⭐', [pic('car', '🚗'), pic('stop', '🛑'), pic('stair', '🪜')]),
    _rhyme('r6', 'B', 1, 'bat', '🦇', [pic('rat', '🐀'), pic('bus', '🚌'), pic('pig', '🐷')]),
    _rhyme('r7', 'B', 1, 'moon', '🌙', [pic('spoon', '🥄'), pic('fox', '🦊'), pic('hat', '🎩')]),
    _rhyme('r8', 'B', 2, 'fish', '🐟', [pic('dish', '🍽️'), pic('pan', '🍳'), pic('bed', '🛏️')]),
    _rhyme('r9', 'B', 2, 'bell', '🔔', [pic('shell', '🐚'), pic('ball', '⚽'), pic('cup', '🥤')]),
    _rhyme('r10', 'B', 3, 'goat', '🐐', [pic('boat', '⛵'), pic('gate', '🚪'), pic('coat', '🧥')]),
    // ---------- First sound (junior) ----------
    _first('f1', 'A', 'mmm', 'm', [pic('moon', '🌙'), pic('sun', '☀️'), pic('car', '🚗')]),
    _first('f2', 'A', 'buh', 'b', [pic('ball', '⚽'), pic('fish', '🐟'), pic('dog', '🐶')]),
    _first('f3', 'A', 'sss', 's', [pic('sun', '☀️'), pic('bed', '🛏️'), pic('pig', '🐷')]),
    _first('f4', 'A', 'fff', 'f', [pic('fish', '🐟'), pic('hat', '🎩'), pic('moon', '🌙')]),
    _first('f5', 'A', 'duh', 'd', [pic('dog', '🐶'), pic('cup', '🥤'), pic('tree', '🌳')]),
    _first('f6', 'B', 'tuh', 't', [pic('tree', '🌳'), pic('bee', '🐝'), pic('car', '🚗')]),
    _first('f7', 'B', 'huh', 'h', [pic('hat', '🎩'), pic('moon', '🌙'), pic('dog', '🐶')]),
    _first('f8', 'B', 'puh', 'p', [pic('pig', '🐷'), pic('fox', '🦊'), pic('sun', '☀️')]),
    _first('f9', 'B', 'rrr', 'r', [pic('rat', '🐀'), pic('bus', '🚌'), pic('fish', '🐟')]),
    _first('f10', 'B', 'nnn', 'n', [pic('nut', '🥜'), pic('dog', '🐶'), pic('cake', '🎂')]),
    // ---------- Phoneme manipulation (answers are heard, not read) ----------
    _manip('p1', 'A', 1, 'Say cat, but take away the k sound.', ['at', 'ca', 'cot']),
    _manip('p2', 'A', 1, 'Say sun, but take away the s sound.', ['un', 'su', 'sat']),
    _manip('p3', 'A', 2, 'Say bat. Now change b to h.', ['hat', 'bit', 'bad']),
    _manip('p4', 'A', 2, 'Say star, but take away the s sound.', ['tar', 'sar', 'stay']),
    _manip('p5', 'A', 3, 'Say stop, but take away the t sound.', ['sop', 'top', 'step']),
    _manip('p6', 'A', 3, 'Say plate, but take away the l sound.', ['pate', 'late', 'plat']),
    _manip('p7', 'B', 1, 'Say hat, but take away the h sound.', ['at', 'ha', 'hot']),
    _manip('p8', 'B', 1, 'Say fish, but take away the f sound.', ['ish', 'fi', 'dish']),
    _manip('p9', 'B', 2, 'Say man. Now change m to p.', ['pan', 'map', 'men']),
    _manip('p10', 'B', 2, 'Say snake, but take away the s sound.', ['nake', 'sake', 'snack']),
    _manip('p11', 'B', 3, 'Say frog, but take away the r sound.', ['fog', 'rog', 'frock']),
    _manip('p12', 'B', 3, 'Say clap, but take away the l sound.', ['cap', 'lap', 'clip']),
    // ---------- Letter–sound ----------
    _letter('l1', 'A', 1, 'mmm', ['m', 'n', 'w']),
    _letter('l2', 'A', 1, 'sss', ['s', 'z', 'c']),
    _letter('l3', 'A', 2, 'buh', ['b', 'd', 'p']),
    _letter('l4', 'A', 2, 'fff', ['f', 't', 'v']),
    _letter('l5', 'A', 3, 'shh', ['sh', 'ch', 'th']),
    _letter('l6', 'A', 3, 'ee, like in tree', ['ee', 'ai', 'oo']),
    _letter('l7', 'B', 1, 'tuh', ['t', 'f', 'l']),
    _letter('l8', 'B', 1, 'nnn', ['n', 'm', 'h']),
    _letter('l9', 'B', 2, 'duh', ['d', 'b', 'q']),
    _letter('l10', 'B', 2, 'puh', ['p', 'q', 'b']),
    _letter('l11', 'B', 3, 'chuh, like in chair', ['ch', 'sh', 'th']),
    _letter('l12', 'B', 3, 'oh, like in boat', ['oa', 'ai', 'ee']),
    // ---------- Picture naming ----------
    _name('n1', 'A', '🐘', 'elephant'),
    _name('n2', 'A', '✂️', 'scissors', ['scissor', 'kainchi']),
    _name('n3', 'A', '🦋', 'butterfly'),
    _name('n4', 'A', '🐢', 'turtle', ['tortoise']),
    _name('n5', 'A', '🌈', 'rainbow'),
    _name('n6', 'A', '🚲', 'bicycle', ['cycle', 'bike']),
    _name('n7', 'A', '🔑', 'key', ['keys']),
    _name('n8', 'B', '🦒', 'giraffe'),
    _name('n9', 'B', '🐒', 'monkey'),
    _name('n10', 'B', '🍉', 'watermelon'),
    _name('n11', 'B', '🚂', 'train', ['engine', 'railway']),
    _name('n12', 'B', '⏰', 'clock', ['alarm', 'alarm clock', 'watch']),
    _name('n13', 'B', '🥕', 'carrot'),
    _name('n14', 'B', '🦜', 'parrot'),
    // ---------- Rapid naming (one grid each pool) ----------
    SItem(id: 'ranA', subtest: 'ran', pool: 'A', options: [
      ChoiceOpt('dog', emoji: '🐶'), ChoiceOpt('sun', emoji: '☀️'), ChoiceOpt('apple', emoji: '🍎'), ChoiceOpt('house', emoji: '🏠'), ChoiceOpt('star', emoji: '⭐'),
    ], accept: ['dog|dogs|doggy', 'sun|son', 'apple|apples', 'house|home|houses', 'star|stars']),
    SItem(id: 'ranB', subtest: 'ran', pool: 'B', options: [
      ChoiceOpt('cat', emoji: '🐱'), ChoiceOpt('ball', emoji: '⚽'), ChoiceOpt('tree', emoji: '🌳'), ChoiceOpt('car', emoji: '🚗'), ChoiceOpt('fish', emoji: '🐟'),
    ], accept: ['cat|cats|kat', 'ball|bowl|balls', 'tree|three|trees', 'car|cars|kar', 'fish|fishes']),
    // ---------- Word reading ----------
    _word('w1', 'A', 1, 'cat'), _word('w2', 'A', 1, 'sun'), _word('w3', 'A', 1, 'bed'), _word('w4', 'A', 2, 'fish'),
    _word('w5', 'A', 2, 'ship'), _word('w6', 'A', 2, 'frog'), _word('w7', 'A', 3, 'rabbit'), _word('w8', 'A', 3, 'garden'),
    _word('w9', 'A', 3, 'mountain', GradeBand.middle), _word('w10', 'A', 3, 'beautiful', GradeBand.middle),
    _word('w11', 'B', 1, 'dog'), _word('w12', 'B', 1, 'hat'), _word('w13', 'B', 1, 'cup'), _word('w14', 'B', 2, 'duck'),
    _word('w15', 'B', 2, 'moon'), _word('w16', 'B', 2, 'star'), _word('w17', 'B', 3, 'basket'), _word('w18', 'B', 3, 'pencil'),
    _word('w19', 'B', 3, 'umbrella', GradeBand.middle), _word('w20', 'B', 3, 'together', GradeBand.middle),
    // ---------- Nonword reading ----------
    _non('x1', 'A', 1, 'fap'), _non('x2', 'A', 1, 'mib'), _non('x3', 'A', 1, 'zug'), _non('x4', 'A', 2, 'blet'),
    _non('x5', 'A', 2, 'shom'), _non('x6', 'A', 3, 'trand'), _non('x7', 'A', 3, 'bimlet', GradeBand.middle), _non('x8', 'A', 3, 'stroggle', GradeBand.middle),
    _non('x9', 'B', 1, 'vop'), _non('x10', 'B', 1, 'tib'), _non('x11', 'B', 1, 'jad'), _non('x12', 'B', 2, 'snig'),
    _non('x13', 'B', 2, 'chab'), _non('x14', 'B', 3, 'glomp'), _non('x15', 'B', 3, 'wempo', GradeBand.middle), _non('x16', 'B', 3, 'frintel', GradeBand.middle),
    // ---------- Spelling ----------
    _spell('s1', 'A', 1, 'cat', '🐱', 'oe'), _spell('s2', 'A', 1, 'sun', '☀️', 'ao'), _spell('s3', 'A', 2, 'fish', '🐟', 'ce'),
    _spell('s4', 'A', 2, 'ship', '🚢', 'ca'), _spell('s5', 'A', 3, 'frog', '🐸', 'la'), _spell('s6', 'A', 3, 'rabbit', '🐰', 'pe', GradeBand.middle),
    _spell('s7', 'B', 1, 'dog', '🐶', 'ba'), _spell('s8', 'B', 1, 'hat', '🎩', 'eo'), _spell('s9', 'B', 2, 'duck', '🦆', 'ao'),
    _spell('s10', 'B', 2, 'chick', '🐤', 'se'), _spell('s11', 'B', 3, 'drum', '🥁', 'ba'), _spell('s12', 'B', 3, 'basket', '🧺', 'pi', GradeBand.middle),
    // ---------- Listening comprehension ----------
    SItem(
      id: 'lcA',
      subtest: 'listening',
      pool: 'A',
      passage: 'Riya went to the market with her mother. She bought red apples and a yellow banana. On the way home it started to rain, so they opened an umbrella.',
      questions: [
        Question('Who went with Riya?', [pic('mother', '👩'), pic('father', '👨'), pic('grandma', '👵')], 0),
        Question('What did she buy?', [pic('apples and a banana', '🍎🍌'), pic('carrots', '🥕'), pic('bread', '🍞')], 0),
        Question('Why did they open the umbrella?', [pic('it was raining', '🌧️'), pic('it was sunny', '☀️'), pic('it was windy', '💨')], 0, tag: 'Cause / effect error'),
      ],
    ),
    SItem(
      id: 'lcB',
      subtest: 'listening',
      pool: 'B',
      passage: 'Arjun has a dog named Moti. One day Moti ran after a ball into the garden and got very muddy. So Arjun gave him a bath.',
      questions: [
        Question('What did Moti run after?', [pic('a ball', '⚽'), pic('a cat', '🐱'), pic('a butterfly', '🦋')], 0),
        Question('Where did Moti run?', [pic('into the garden', '🌳'), pic('to school', '🏫'), pic('to the sea', '🌊')], 0),
        Question('What did Arjun do next?', [pic('gave him a bath', '🛁'), pic('gave him food', '🍽️'), pic('went to sleep', '🛏️')], 0, tag: 'Sequence error'),
      ],
    ),
    // ---------- Reading comprehension: junior = sentence → picture ----------
    SItem(id: 'rcA1', subtest: 'readingComp', pool: 'A', difficulty: 1, only: GradeBand.junior, passage: 'The cat is on the bed.', options: [pic('cat on bed', '🐱🛏️'), pic('dog on bed', '🐶🛏️'), pic('cat in tree', '🐱🌳')]),
    SItem(id: 'rcA2', subtest: 'readingComp', pool: 'A', difficulty: 2, only: GradeBand.junior, passage: 'The fish is in the water.', options: [pic('fish in water', '🐟💧'), pic('fish in tree', '🐟🌳'), pic('bird in water', '🐦💧')]),
    SItem(id: 'rcA3', subtest: 'readingComp', pool: 'A', difficulty: 3, only: GradeBand.junior, passage: 'I have a big red ball.', options: [pic('red ball', '🔴⚽'), pic('blue ball', '🔵⚽'), pic('red apple', '🔴🍎')]),
    SItem(id: 'rcB1', subtest: 'readingComp', pool: 'B', difficulty: 1, only: GradeBand.junior, passage: 'The dog is in the car.', options: [pic('dog in car', '🐶🚗'), pic('cat in car', '🐱🚗'), pic('dog in house', '🐶🏠')]),
    SItem(id: 'rcB2', subtest: 'readingComp', pool: 'B', difficulty: 2, only: GradeBand.junior, passage: 'The bird is on the tree.', options: [pic('bird on tree', '🐦🌳'), pic('bird on house', '🐦🏠'), pic('fish on tree', '🐟🌳')]),
    SItem(id: 'rcB3', subtest: 'readingComp', pool: 'B', difficulty: 3, only: GradeBand.junior, passage: 'I have a little blue cup.', options: [pic('blue cup', '🔵🥤'), pic('red cup', '🔴🥤'), pic('blue ball', '🔵⚽')]),
    // ---------- Reading comprehension: middle = passage + questions ----------
    SItem(
      id: 'rcAm',
      subtest: 'readingComp',
      pool: 'A',
      only: GradeBand.middle,
      passage: 'Meena planted a small seed in a pot. Every morning she gave it water and kept it in the sun. After two weeks, a tiny green leaf came out. Meena was so happy that she showed it to her whole class.',
      questions: [
        Question('What did Meena plant?', [aud('a seed'), aud('a tree'), aud('a flower')], 0),
        Question('Why did the leaf come out?', [aud('She gave it water and sun'), aud('It rained a lot'), aud('Her friend helped')], 0, tag: 'Cause / effect error'),
        Question('How did Meena feel?', [aud('happy'), aud('angry'), aud('sleepy')], 0, tag: 'Inference error'),
      ],
    ),
    SItem(
      id: 'rcBm',
      subtest: 'readingComp',
      pool: 'B',
      only: GradeBand.middle,
      passage: 'Ravi made a kite with paper and sticks. He ran fast in the park, and the wind lifted the kite high. Suddenly the string broke and the kite flew over a tree. Ravi’s friend climbed the tree and brought it back.',
      questions: [
        Question('What did Ravi make?', [aud('a kite'), aud('a boat'), aud('a cake')], 0),
        Question('What happened when the string broke?', [aud('The kite flew over a tree'), aud('Ravi fell down'), aud('It started to rain')], 0, tag: 'Cause / effect error'),
        Question('Who brought the kite back?', [aud('Ravi’s friend'), aud('his mother'), aud('a bird')], 0),
      ],
    ),
    // ---------- Oral reading fluency ----------
    SItem(id: 'orAj', subtest: 'oralReading', pool: 'A', only: GradeBand.junior, passage: 'The cat sat on a mat. It is a big red cat. The cat can run.'),
    SItem(id: 'orBj', subtest: 'oralReading', pool: 'B', only: GradeBand.junior, passage: 'I see a dog. The dog is big. The dog can run very fast.'),
    SItem(
        id: 'orAm',
        subtest: 'oralReading',
        pool: 'A',
        only: GradeBand.middle,
        passage: 'Tara has a little brown dog named Bholu. Every evening they go to the park near their house. Bholu likes to chase the pigeons, but he never catches them. When they come home, Tara gives him a bowl of milk.'),
    SItem(
        id: 'orBm',
        subtest: 'oralReading',
        pool: 'B',
        only: GradeBand.middle,
        passage: 'Sam lives near a big river. On Sundays he goes fishing with his grandfather. They sit on the bank and wait quietly. Sometimes they catch a small fish, but they always let it go back into the water.'),
    // ---------- Semantic fluency ----------
    SItem(id: 'flA', subtest: 'fluency', pool: 'A', target: 'animals', say: 'Say as many animals as you can!'),
    SItem(id: 'flB', subtest: 'fluency', pool: 'B', target: 'foods', say: 'Say as many foods as you can!'),
  ];

  @override
  List<SItem> get items => _items;

  @override
  Set<String> get animals => const {
        'dog', 'cat', 'cow', 'buffalo', 'goat', 'sheep', 'horse', 'donkey', 'camel', 'elephant', 'lion', 'tiger', 'leopard',
        'cheetah', 'bear', 'monkey', 'deer', 'rabbit', 'mouse', 'rat', 'squirrel', 'fox', 'wolf', 'pig', 'giraffe', 'zebra',
        'rhino', 'rhinoceros', 'hippo', 'hippopotamus', 'crocodile', 'alligator', 'turtle', 'tortoise', 'snake', 'frog',
        'fish', 'shark', 'whale', 'dolphin', 'octopus', 'crab', 'parrot', 'peacock', 'pigeon', 'crow', 'sparrow', 'duck',
        'hen', 'chicken', 'rooster', 'owl', 'eagle', 'vulture', 'butterfly', 'bee', 'ant', 'spider', 'mosquito', 'fly',
        'penguin', 'kangaroo', 'koala', 'panda', 'gorilla', 'chimpanzee', 'lizard', 'bat', 'swan', 'ostrich', 'bird',
        'puppy', 'kitten', 'ox', 'bull', 'yak', 'jackal', 'hyena', 'mongoose', 'peahen', 'cobra', 'python', 'dinosaur',
        'unicorn', 'dragon', 'goose', 'turkey', 'worm', 'snail', 'cockroach', 'beetle', 'ladybug', 'seal', 'otter', 'beaver',
      };

  @override
  Set<String> get foods => const {
        'apple', 'banana', 'mango', 'orange', 'grapes', 'grape', 'papaya', 'guava', 'pineapple', 'watermelon', 'melon',
        'strawberry', 'cherry', 'pear', 'peach', 'plum', 'coconut', 'rice', 'roti', 'chapati', 'bread', 'dal', 'idli',
        'dosa', 'sambar', 'paratha', 'puri', 'poha', 'upma', 'biryani', 'pulao', 'khichdi', 'milk', 'curd', 'paneer',
        'cheese', 'butter', 'egg', 'eggs', 'chicken', 'fish', 'potato', 'tomato', 'onion', 'carrot', 'peas', 'corn',
        'cabbage', 'cauliflower', 'spinach', 'brinjal', 'cucumber', 'pizza', 'burger', 'pasta', 'noodles', 'sandwich',
        'cake', 'biscuit', 'cookie', 'chocolate', 'ice cream', 'icecream', 'laddu', 'jalebi', 'halwa', 'kheer', 'samosa',
        'pakora', 'chips', 'juice', 'tea', 'honey', 'jam', 'soup', 'salad', 'nuts', 'peanut', 'almond', 'cashew', 'dates',
      };
}
