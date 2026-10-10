import 'bank.dart';
import 'models.dart';

class HindiScreenBank extends ScreenBank {
  @override
  String get code => 'hi';
  @override
  String get tts => 'hi-IN';
  @override
  String get asr => 'hi_IN';

  @override
  Map<String, String> get ui => const {
        'tapMic': 'माइक दबाओ और बोलो',
        'listening': 'मैं सुन रहा हूँ…',
        'again': 'मुझे सुनाई नहीं दिया। एक बार और बोलो!',
        'nice': 'बढ़िया!',
        'thanks': 'बहुत अच्छा पढ़ा!',
        'go': 'चलो!',
        'done': 'हो गया',
        'next': 'आगे',
        'ready': 'तैयार?',
        'noMic': 'आवाज़ वाले खेल के लिए फ़ोन ऐप और माइक की अनुमति चाहिए।',
      };

  static SItem _rhyme(String id, String pool, int d, String w, String e, List<ChoiceOpt> o) =>
      SItem(id: id, subtest: 'rhyme', pool: pool, difficulty: d, target: w, emoji: e, say: 'कौन सा शब्द $w जैसा खत्म होता है?', options: o);
  static SItem _first(String id, String pool, String s, List<ChoiceOpt> o) =>
      SItem(id: id, subtest: 'firstSound', pool: pool, target: s, say: 'कौन सा शब्द $s से शुरू होता है?', options: o);
  static SItem _manip(String id, String pool, int d, String say, List<String> o) =>
      SItem(id: id, subtest: 'phonemeManip', pool: pool, difficulty: d, say: say, options: o.map(aud).toList());
  static SItem _letter(String id, String pool, int d, String s, List<String> o) =>
      SItem(id: id, subtest: 'letterSound', pool: pool, difficulty: d, say: s, options: o.map((x) => ChoiceOpt(x)).toList());
  static SItem _name(String id, String pool, String e, String w, [List<String> acc = const []]) =>
      SItem(id: id, subtest: 'pictureNaming', pool: pool, emoji: e, target: w, accept: [w, ...acc]);
  static SItem _word(String id, String pool, int d, String w, [GradeBand? only]) =>
      SItem(id: id, subtest: 'wordReading', pool: pool, difficulty: d, target: w, only: only);
  static SItem _non(String id, String pool, int d, String w, [GradeBand? only]) =>
      SItem(id: id, subtest: 'nonwordReading', pool: pool, difficulty: d, target: w, only: only);
  static SItem _spell(String id, String pool, int d, String w, String e, String units, String extra, [GradeBand? only]) =>
      SItem(id: id, subtest: 'spelling', pool: pool, difficulty: d, target: w, emoji: e, answer: units.split('-'), distractors: extra.split('-'), only: only);

  static final _items = <SItem>[
    // ---------- तुकबंदी ----------
    _rhyme('r1', 'A', 1, 'नल', '🚰', [pic('जल', '💧'), pic('घर', '🏠'), pic('सेब', '🍏')]),
    _rhyme('r2', 'A', 1, 'केला', '🍌', [pic('मेला', '🎡'), pic('आम', '🥭'), pic('बस', '🚌')]),
    _rhyme('r3', 'A', 2, 'पानी', '🌊', [pic('रानी', '👸'), pic('पतंग', '🪁'), pic('फल', '🍎')]),
    _rhyme('r4', 'A', 2, 'गाय', '🐄', [pic('चाय', '☕'), pic('गेंद', '⚽'), pic('मोर', '🦚')]),
    _rhyme('r5', 'A', 3, 'मछली', '🐟', [pic('तितली', '🦋'), pic('मटर', '🫛'), pic('मकान', '🏠')]),
    _rhyme('r6', 'B', 1, 'फल', '🍎', [pic('नल', '🚰'), pic('घर', '🏠'), pic('गाय', '🐄')]),
    _rhyme('r7', 'B', 1, 'चाय', '☕', [pic('गाय', '🐄'), pic('चाबी', '🔑'), pic('बस', '🚌')]),
    _rhyme('r8', 'B', 2, 'रानी', '👸', [pic('पानी', '🌊'), pic('राजा', '🤴'), pic('रोटी', '🫓')]),
    _rhyme('r9', 'B', 2, 'मेला', '🎡', [pic('केला', '🍌'), pic('मोर', '🦚'), pic('मेज़', '🪑')]),
    _rhyme('r10', 'B', 3, 'तितली', '🦋', [pic('मछली', '🐟'), pic('तोता', '🦜'), pic('ताला', '🔒')]),
    // ---------- पहली आवाज़ ----------
    _first('f1', 'A', 'म', [pic('मछली', '🐟'), pic('घर', '🏠'), pic('सेब', '🍏')]),
    _first('f2', 'A', 'स', [pic('सेब', '🍏'), pic('नल', '🚰'), pic('गाय', '🐄')]),
    _first('f3', 'A', 'क', [pic('केला', '🍌'), pic('घर', '🏠'), pic('मोर', '🦚')]),
    _first('f4', 'A', 'ग', [pic('गाय', '🐄'), pic('बस', '🚌'), pic('फल', '🍎')]),
    _first('f5', 'A', 'प', [pic('पानी', '🌊'), pic('केला', '🍌'), pic('घर', '🏠')]),
    _first('f6', 'B', 'ब', [pic('बस', '🚌'), pic('गाय', '🐄'), pic('केला', '🍌')]),
    _first('f7', 'B', 'घ', [pic('घर', '🏠'), pic('सेब', '🍏'), pic('मोर', '🦚')]),
    _first('f8', 'B', 'न', [pic('नल', '🚰'), pic('केला', '🍌'), pic('गाय', '🐄')]),
    _first('f9', 'B', 'फ', [pic('फल', '🍎'), pic('घर', '🏠'), pic('मोर', '🦚')]),
    _first('f10', 'B', 'त', [pic('तितली', '🦋'), pic('गाय', '🐄'), pic('नल', '🚰')]),
    // ---------- अक्षर हटाना / बदलना (DALI: syllable replacement) ----------
    _manip('p1', 'A', 1, 'कमल बोलो। अब क हटाओ। क्या बचा?', ['मल', 'कम', 'कल']),
    _manip('p2', 'A', 1, 'नल बोलो। अब न की जगह ज बोलो।', ['जल', 'नज', 'नाल']),
    _manip('p3', 'A', 2, 'मछली बोलो। अब म हटाओ। क्या बचा?', ['छली', 'मछ', 'मली']),
    _manip('p4', 'A', 2, 'घर बोलो। अब घ की जगह प बोलो।', ['पर', 'घप', 'घार']),
    _manip('p5', 'A', 3, 'पतंग बोलो। अब प हटाओ। क्या बचा?', ['तंग', 'पत', 'पंग']),
    _manip('p6', 'A', 3, 'कबूतर बोलो। अब बू हटाओ। क्या बचा?', ['कतर', 'कबू', 'बूतर']),
    _manip('p7', 'B', 1, 'केला बोलो। अब के हटाओ। क्या बचा?', ['ला', 'के', 'कला']),
    _manip('p8', 'B', 1, 'फल बोलो। अब फ की जगह ज बोलो।', ['जल', 'फज', 'फाल']),
    _manip('p9', 'B', 2, 'तितली बोलो। अब ति हटाओ। क्या बचा?', ['तली', 'तित', 'तिली']),
    _manip('p10', 'B', 2, 'मोर बोलो। अब म की जगह च बोलो।', ['चोर', 'मच', 'मोच']),
    _manip('p11', 'B', 3, 'बंदर बोलो। अब बं हटाओ। क्या बचा?', ['दर', 'बंद', 'बर']),
    _manip('p12', 'B', 3, 'गुब्बारा बोलो। अब ब्बा हटाओ। क्या बचा?', ['गुरा', 'गुब्बा', 'बारा']),
    // ---------- अक्षर–आवाज़ (मात्रा, संयुक्त अक्षर) ----------
    _letter('l1', 'A', 1, 'क', ['क', 'फ', 'ख']),
    _letter('l2', 'A', 1, 'म', ['म', 'भ', 'न']),
    _letter('l3', 'A', 2, 'ब', ['ब', 'व', 'प']),
    _letter('l4', 'A', 2, 'की', ['की', 'कि', 'कू']),
    _letter('l5', 'A', 3, 'को', ['को', 'के', 'कौ']),
    _letter('l6', 'A', 3, 'क्ष', ['क्ष', 'ष', 'क्र']),
    _letter('l7', 'B', 1, 'न', ['न', 'म', 'त']),
    _letter('l8', 'B', 1, 'र', ['र', 'ख', 'व']),
    _letter('l9', 'B', 2, 'घ', ['घ', 'ध', 'छ']),
    _letter('l10', 'B', 2, 'मा', ['मा', 'मि', 'मु']),
    _letter('l11', 'B', 3, 'सू', ['सू', 'सु', 'से']),
    _letter('l12', 'B', 3, 'त्र', ['त्र', 'त्य', 'ञ']),
    // ---------- चित्र नाम ----------
    _name('n1', 'A', '🐘', 'हाथी', ['hathi', 'elephant']),
    _name('n2', 'A', '✂️', 'कैंची', ['कैची', 'scissors']),
    _name('n3', 'A', '🦋', 'तितली', ['butterfly']),
    _name('n4', 'A', '🐢', 'कछुआ', ['कछुवा', 'turtle']),
    _name('n5', 'A', '☂️', 'छाता', ['छतरी', 'umbrella']),
    _name('n6', 'A', '🚲', 'साइकिल', ['साइकल', 'cycle']),
    _name('n7', 'A', '🔑', 'चाबी', ['चाभी', 'key']),
    _name('n8', 'B', '🦒', 'जिराफ़', ['जिराफ', 'giraffe']),
    _name('n9', 'B', '🐒', 'बंदर', ['बन्दर', 'monkey']),
    _name('n10', 'B', '🍉', 'तरबूज', ['तरबूज़', 'watermelon']),
    _name('n11', 'B', '🚂', 'रेलगाड़ी', ['ट्रेन', 'रेल', 'train']),
    _name('n12', 'B', '⏰', 'घड़ी', ['घडी', 'clock']),
    _name('n13', 'B', '🥕', 'गाजर', ['carrot']),
    _name('n14', 'B', '🦜', 'तोता', ['parrot']),
    // ---------- फटाफट नाम ----------
    SItem(id: 'ranA', subtest: 'ran', pool: 'A', options: [
      ChoiceOpt('कुत्ता', emoji: '🐶'), ChoiceOpt('सूरज', emoji: '☀️'), ChoiceOpt('सेब', emoji: '🍎'), ChoiceOpt('घर', emoji: '🏠'), ChoiceOpt('तारा', emoji: '⭐'),
    ], accept: ['कुत्ता|कुत्ते|dog', 'सूरज|सूर्य|sun', 'सेब|apple', 'घर|मकान|house', 'तारा|तारे|star']),
    SItem(id: 'ranB', subtest: 'ran', pool: 'B', options: [
      ChoiceOpt('बिल्ली', emoji: '🐱'), ChoiceOpt('गेंद', emoji: '⚽'), ChoiceOpt('पेड़', emoji: '🌳'), ChoiceOpt('गाड़ी', emoji: '🚗'), ChoiceOpt('मछली', emoji: '🐟'),
    ], accept: ['बिल्ली|cat', 'गेंद|बॉल|ball', 'पेड़|पेड|tree', 'गाड़ी|कार|गाडी|car', 'मछली|fish']),
    // ---------- शब्द पढ़ना ----------
    _word('w1', 'A', 1, 'घर'), _word('w2', 'A', 1, 'नल'), _word('w3', 'A', 1, 'कमल'), _word('w4', 'A', 2, 'केला'),
    _word('w5', 'A', 2, 'पानी'), _word('w6', 'A', 2, 'मछली'), _word('w7', 'A', 3, 'बंदर'), _word('w8', 'A', 3, 'किताब'),
    _word('w9', 'A', 3, 'स्कूल', GradeBand.middle), _word('w10', 'A', 3, 'परिवार', GradeBand.middle),
    _word('w11', 'B', 1, 'बस'), _word('w12', 'B', 1, 'फल'), _word('w13', 'B', 1, 'मगर'), _word('w14', 'B', 2, 'टोपी'),
    _word('w15', 'B', 2, 'भालू'), _word('w16', 'B', 2, 'तितली'), _word('w17', 'B', 3, 'पतंग'), _word('w18', 'B', 3, 'कहानी'),
    _word('w19', 'B', 3, 'गुब्बारा', GradeBand.middle), _word('w20', 'B', 3, 'त्योहार', GradeBand.middle),
    // ---------- अजीब शब्द ----------
    _non('x1', 'A', 1, 'कबल'), _non('x2', 'A', 1, 'मतज'), _non('x3', 'A', 1, 'नपर'), _non('x4', 'A', 2, 'सूकल'),
    _non('x5', 'A', 2, 'गमीर'), _non('x6', 'A', 3, 'चिनटा'), _non('x7', 'A', 3, 'पोबारी', GradeBand.middle), _non('x8', 'A', 3, 'किरम्पा', GradeBand.middle),
    _non('x9', 'B', 1, 'बसत'), _non('x10', 'B', 1, 'लपम'), _non('x11', 'B', 1, 'दजर'), _non('x12', 'B', 2, 'रीगम'),
    _non('x13', 'B', 2, 'तोलक'), _non('x14', 'B', 3, 'जिमपा'), _non('x15', 'B', 3, 'सुवरीक', GradeBand.middle), _non('x16', 'B', 3, 'खपोल्ला', GradeBand.middle),
    // ---------- शब्द बनाना (अक्षर + मात्रा) ----------
    _spell('s1', 'A', 1, 'घर', '🏠', 'घ-र', 'ध-प'), _spell('s2', 'A', 1, 'कमल', '🌸', 'क-म-ल', 'फ-न'),
    _spell('s3', 'A', 2, 'पानी', '🌊', 'पा-नी', 'पी-नि'), _spell('s4', 'A', 2, 'केला', '🍌', 'के-ला', 'का-ले'),
    _spell('s5', 'A', 3, 'मछली', '🐟', 'म-छ-ली', 'लि-भ'), _spell('s6', 'A', 3, 'चाँद', '🌙', 'चाँ-द', 'चा-ध', GradeBand.middle),
    _spell('s7', 'B', 1, 'नल', '🚰', 'न-ल', 'म-त'), _spell('s8', 'B', 1, 'मगर', '🐊', 'म-ग-र', 'भ-ख'),
    _spell('s9', 'B', 2, 'भालू', '🐻', 'भा-लू', 'भू-लु'), _spell('s10', 'B', 2, 'टोपी', '👒', 'टो-पी', 'टे-पि'),
    _spell('s11', 'B', 3, 'तितली', '🦋', 'ति-त-ली', 'ती-लि'), _spell('s12', 'B', 3, 'बंदर', '🐒', 'बं-द-र', 'ब-ध', GradeBand.middle),
    // ---------- सुनकर समझना ----------
    SItem(
      id: 'lcA',
      subtest: 'listening',
      pool: 'A',
      passage: 'रिया अपनी माँ के साथ बाज़ार गई। उसने लाल सेब और एक पीला केला खरीदा। घर लौटते समय बारिश होने लगी, इसलिए उन्होंने छाता खोला।',
      questions: [
        Question('रिया किसके साथ गई?', [pic('माँ', '👩'), pic('पापा', '👨'), pic('दादी', '👵')], 0),
        Question('उसने क्या खरीदा?', [pic('सेब और केला', '🍎🍌'), pic('गाजर', '🥕'), pic('ब्रेड', '🍞')], 0),
        Question('छाता क्यों खोला?', [pic('बारिश हो रही थी', '🌧️'), pic('धूप थी', '☀️'), pic('हवा चल रही थी', '💨')], 0, tag: 'Cause / effect error'),
      ],
    ),
    SItem(
      id: 'lcB',
      subtest: 'listening',
      pool: 'B',
      passage: 'अर्जुन का एक कुत्ता है, उसका नाम मोती है। एक दिन मोती गेंद के पीछे बगीचे में भागा और कीचड़ से भर गया। तब अर्जुन ने उसे नहलाया।',
      questions: [
        Question('मोती किसके पीछे भागा?', [pic('गेंद', '⚽'), pic('बिल्ली', '🐱'), pic('तितली', '🦋')], 0),
        Question('मोती कहाँ भागा?', [pic('बगीचे में', '🌳'), pic('स्कूल', '🏫'), pic('समुद्र', '🌊')], 0),
        Question('अर्जुन ने फिर क्या किया?', [pic('नहलाया', '🛁'), pic('खाना दिया', '🍽️'), pic('सो गया', '🛏️')], 0, tag: 'Sequence error'),
      ],
    ),
    // ---------- पढ़कर समझना ----------
    SItem(id: 'rcA1', subtest: 'readingComp', pool: 'A', difficulty: 1, only: GradeBand.junior, passage: 'बिल्ली बिस्तर पर है।', options: [pic('बिल्ली बिस्तर पर', '🐱🛏️'), pic('कुत्ता बिस्तर पर', '🐶🛏️'), pic('बिल्ली पेड़ पर', '🐱🌳')]),
    SItem(id: 'rcA2', subtest: 'readingComp', pool: 'A', difficulty: 2, only: GradeBand.junior, passage: 'मछली पानी में है।', options: [pic('मछली पानी में', '🐟💧'), pic('मछली पेड़ पर', '🐟🌳'), pic('चिड़िया पानी में', '🐦💧')]),
    SItem(id: 'rcA3', subtest: 'readingComp', pool: 'A', difficulty: 3, only: GradeBand.junior, passage: 'मेरे पास लाल गेंद है।', options: [pic('लाल गेंद', '🔴⚽'), pic('नीली गेंद', '🔵⚽'), pic('लाल सेब', '🔴🍎')]),
    SItem(id: 'rcB1', subtest: 'readingComp', pool: 'B', difficulty: 1, only: GradeBand.junior, passage: 'कुत्ता गाड़ी में है।', options: [pic('कुत्ता गाड़ी में', '🐶🚗'), pic('बिल्ली गाड़ी में', '🐱🚗'), pic('कुत्ता घर में', '🐶🏠')]),
    SItem(id: 'rcB2', subtest: 'readingComp', pool: 'B', difficulty: 2, only: GradeBand.junior, passage: 'चिड़िया पेड़ पर है।', options: [pic('चिड़िया पेड़ पर', '🐦🌳'), pic('चिड़िया घर पर', '🐦🏠'), pic('मछली पेड़ पर', '🐟🌳')]),
    SItem(id: 'rcB3', subtest: 'readingComp', pool: 'B', difficulty: 3, only: GradeBand.junior, passage: 'मेरे पास नीला कप है।', options: [pic('नीला कप', '🔵🥤'), pic('लाल कप', '🔴🥤'), pic('नीली गेंद', '🔵⚽')]),
    SItem(
      id: 'rcAm',
      subtest: 'readingComp',
      pool: 'A',
      only: GradeBand.middle,
      passage: 'मीना ने गमले में एक छोटा बीज बोया। वह रोज़ सुबह उसे पानी देती और धूप में रखती। दो हफ़्ते बाद एक छोटी हरी पत्ती निकली। मीना इतनी खुश हुई कि उसने पूरी कक्षा को दिखाया।',
      questions: [
        Question('मीना ने क्या बोया?', [aud('एक बीज'), aud('एक पेड़'), aud('एक फूल')], 0),
        Question('पत्ती क्यों निकली?', [aud('उसने पानी और धूप दी'), aud('बहुत बारिश हुई'), aud('दोस्त ने मदद की')], 0, tag: 'Cause / effect error'),
        Question('मीना को कैसा लगा?', [aud('खुशी'), aud('गुस्सा'), aud('नींद')], 0, tag: 'Inference error'),
      ],
    ),
    SItem(
      id: 'rcBm',
      subtest: 'readingComp',
      pool: 'B',
      only: GradeBand.middle,
      passage: 'रवि ने कागज़ और तीलियों से पतंग बनाई। वह पार्क में तेज़ दौड़ा और हवा ने पतंग को ऊँचा उड़ा दिया। अचानक डोर टूट गई और पतंग पेड़ के ऊपर चली गई। रवि का दोस्त पेड़ पर चढ़ा और पतंग वापस ले आया।',
      questions: [
        Question('रवि ने क्या बनाया?', [aud('पतंग'), aud('नाव'), aud('केक')], 0),
        Question('डोर टूटने पर क्या हुआ?', [aud('पतंग पेड़ पर चली गई'), aud('रवि गिर गया'), aud('बारिश होने लगी')], 0, tag: 'Cause / effect error'),
        Question('पतंग कौन लाया?', [aud('रवि का दोस्त'), aud('उसकी माँ'), aud('एक चिड़िया')], 0),
      ],
    ),
    // ---------- ज़ोर से पढ़ना ----------
    SItem(id: 'orAj', subtest: 'oralReading', pool: 'A', only: GradeBand.junior, passage: 'बिल्ली चटाई पर बैठी है। वह बड़ी और भूरी है। बिल्ली दौड़ सकती है।'),
    SItem(id: 'orBj', subtest: 'oralReading', pool: 'B', only: GradeBand.junior, passage: 'मैं एक कुत्ता देखता हूँ। कुत्ता बड़ा है। कुत्ता तेज़ दौड़ता है।'),
    SItem(
        id: 'orAm',
        subtest: 'oralReading',
        pool: 'A',
        only: GradeBand.middle,
        passage: 'तारा के पास एक छोटा भूरा कुत्ता है जिसका नाम भोलू है। हर शाम वे घर के पास वाले पार्क में जाते हैं। भोलू कबूतरों के पीछे भागता है, पर उन्हें कभी नहीं पकड़ता। घर आकर तारा उसे दूध देती है।'),
    SItem(
        id: 'orBm',
        subtest: 'oralReading',
        pool: 'B',
        only: GradeBand.middle,
        passage: 'सोनू एक बड़ी नदी के पास रहता है। रविवार को वह अपने दादाजी के साथ मछली पकड़ने जाता है। वे किनारे पर चुपचाप बैठकर इंतज़ार करते हैं। कभी कभी वे छोटी मछली पकड़ते हैं, पर उसे वापस पानी में छोड़ देते हैं।'),
    // ---------- शब्द-प्रवाह ----------
    SItem(id: 'flA', subtest: 'fluency', pool: 'A', target: 'animals', say: 'जितने जानवर याद हों, जल्दी जल्दी बोलो!'),
    SItem(id: 'flB', subtest: 'fluency', pool: 'B', target: 'foods', say: 'जितनी खाने की चीज़ें याद हों, जल्दी जल्दी बोलो!'),
  ];

  @override
  List<SItem> get items => _items;

  @override
  Set<String> get animals => const {
        'कुत्ता', 'कुत्ते', 'बिल्ली', 'गाय', 'भैंस', 'बकरी', 'भेड़', 'घोड़ा', 'गधा', 'ऊँट', 'ऊंट', 'हाथी', 'शेर', 'बाघ', 'चीता',
        'भालू', 'बंदर', 'हिरन', 'हिरण', 'खरगोश', 'चूहा', 'गिलहरी', 'लोमड़ी', 'भेड़िया', 'सूअर', 'जिराफ़', 'जिराफ', 'ज़ेबरा',
        'जेबरा', 'गैंडा', 'मगरमच्छ', 'मगर', 'कछुआ', 'साँप', 'सांप', 'मेंढक', 'मछली', 'तोता', 'मोर', 'कबूतर', 'कौआ', 'चिड़िया',
        'बतख', 'मुर्गा', 'मुर्गी', 'उल्लू', 'चील', 'गिद्ध', 'तितली', 'मधुमक्खी', 'मक्खी', 'मच्छर', 'चींटी', 'मकड़ी', 'केकड़ा',
        'डॉल्फिन', 'व्हेल', 'पेंगुइन', 'कंगारू', 'पांडा', 'जंगली', 'बैल', 'सांड', 'याक', 'सियार', 'लकड़बग्घा', 'नेवला', 'हंस',
        'शुतुरमुर्ग', 'छिपकली', 'चमगादड़', 'गोरिल्ला', 'चिंपैंजी', 'कोबरा', 'अजगर', 'डायनासोर', 'गौरैया', 'बुलबुल', 'मैना',
        'dog', 'cat', 'cow', 'lion', 'tiger', 'elephant', 'monkey', 'horse', 'rabbit', 'fish', 'parrot', 'snake',
      };

  @override
  Set<String> get foods => const {
        'सेब', 'केला', 'आम', 'संतरा', 'अंगूर', 'पपीता', 'अमरूद', 'अनानास', 'तरबूज', 'तरबूज़', 'खरबूजा', 'नारियल', 'चीकू',
        'अनार', 'नाशपाती', 'चावल', 'रोटी', 'चपाती', 'दाल', 'इडली', 'डोसा', 'सांभर', 'पराठा', 'पूरी', 'पोहा', 'उपमा', 'बिरयानी',
        'पुलाव', 'खिचड़ी', 'दूध', 'दही', 'पनीर', 'मक्खन', 'घी', 'अंडा', 'मछली', 'आलू', 'टमाटर', 'प्याज़', 'प्याज', 'गाजर', 'मटर',
        'भुट्टा', 'गोभी', 'पालक', 'बैंगन', 'खीरा', 'भिंडी', 'लौकी', 'पिज़्ज़ा', 'पिज्जा', 'बर्गर', 'नूडल्स', 'सैंडविच', 'केक',
        'बिस्कुट', 'चॉकलेट', 'आइसक्रीम', 'लड्डू', 'जलेबी', 'हलवा', 'खीर', 'समोसा', 'पकौड़ा', 'चिप्स', 'जूस', 'चाय', 'शहद',
        'सूप', 'मूँगफली', 'बादाम', 'काजू', 'खजूर', 'मिठाई', 'रसगुल्ला', 'गुलाब जामुन', 'कचौरी', 'छोले', 'राजमा', 'सब्ज़ी',
        'apple', 'banana', 'mango', 'rice', 'pizza', 'cake', 'milk', 'egg',
      };
}
