import 'dart:math';

/// App-level UI strings, separated from learning content.
/// Add a language by adding a column here + a LangPack in data/.
class Brand {
  static const name = 'Wordoo';
  static const tagline = 'A Reading Adventure Just for You';
  static const companion = 'Milo';
}

class Str {
  static final _rng = Random();

  static const Map<String, Map<String, String>> _t = {
    'en': {
      'good1': 'Great job!',
      'good2': 'Awesome!',
      'good3': 'You got it!',
      'almost': 'Almost! Let’s try again.',
      'another': 'Good try! Let’s try another one.',
      'moveOn': 'Good try!',
      'ready': 'Ready, Explorer?',
      'together': 'Let’s solve this together!',
      'stronger': 'You’re getting stronger!',
      'listen': 'Listen carefully!',
      'letsGo': 'Let’s go!',
      'check': 'Check',
      'whereToday': 'Where shall we go today?',
      'powerUp': 'Power up!',
      'warmUp': 'Let’s try a warm-up one.',
      'hint': 'Here’s a little help!',
      'bridge': 'Oh no! The bridge to the Magic Forest is broken! Help me fix it!',
      'skyBridge': 'The Cloud Bridge to the Sky Station lost some planks! Can you help me fix it?',
      'tryDemo': 'Watch me first!',
      'yourTurn': 'Now it’s your turn!',
    },
    'hi': {
      'good1': 'शाबाश!',
      'good2': 'बहुत बढ़िया!',
      'good3': 'वाह, सही!',
      'almost': 'लगभग! फिर से कोशिश करें।',
      'another': 'अच्छी कोशिश! चलो अगला करें।',
      'moveOn': 'अच्छी कोशिश!',
      'ready': 'तैयार हो, खोजी?',
      'together': 'चलो मिलकर करते हैं!',
      'stronger': 'तुम और मज़बूत हो रहे हो!',
      'listen': 'ध्यान से सुनो!',
      'letsGo': 'चलो!',
      'check': 'जाँचो',
      'whereToday': 'आज कहाँ चलें?',
      'powerUp': 'पावर अप!',
      'warmUp': 'चलो, एक आसान से शुरू करें।',
      'hint': 'थोड़ी मदद लो!',
      'bridge': 'अरे! जादुई जंगल का पुल टूट गया है! इसे ठीक करने में मदद करो!',
      'skyBridge': 'बादलों के पुल की कुछ तख़्तियाँ खो गई हैं! क्या तुम मदद करोगे?',
      'tryDemo': 'पहले मुझे देखो!',
      'yourTurn': 'अब तुम्हारी बारी!',
    },
  };

  static Iterable<String> get keys => _t['en']!.keys;
  static String t(String lang, String key) => _t[lang]?[key] ?? _t['en']![key] ?? key;
  static String good(String lang) => t(lang, 'good${1 + _rng.nextInt(3)}');
}
