import '../engine/campaign.dart';
import '../models/models.dart';

/// Everyday Hindi for the Hindi demo (prologue, map, Sound Forest, screening). Written the way a family talks at home:
/// common words (जंगल, गाँव, चाबी, खेल) instead of formal Hindi. English-mode code never reads this file.
class HiText {
  /// Names under story captions.
  static const characters = <String, String>{
    'milo': 'मिलो',
    'gumsum': 'गुमसुम',
    'dadi': 'दादी कहानी',
    'bhalu': 'उस्ताद भालू',
    'arya': 'आर्या',
    'kachhua': 'कप्तान कछुआ',
    'ullu': 'इंस्पेक्टर उल्लू',
    'madhu': 'रानी मधु',
    'pari': 'परी राजकुमारी',
    'kitabu': 'किताबू',
    'bolt': 'बोल्ट',
    'pip': 'पिप',
    'coral': 'कोरल',
    'jugnu': 'जुगनू',
    'kalam': 'कप्तान कलाम',
    'chuchu': 'चूचू',
    'tinku': 'टिंकू',
    'koyal': 'कोयल',
    'gajju': 'गज्जू',
    'jailer_forest': 'रिमझिम',
    'jailer_valley': 'आँधी',
    'jailer_ocean': 'धुंध',
    'jailer_village': 'धब्बा',
    'jailer_treasure': 'रूठी',
    'jailer_castle': 'चुप्पी',
  };

  static const islands = <IslandId, String>{
    IslandId.forest: 'आवाज़ों का जंगल',
    IslandId.valley: 'अक्षरों की घाटी',
    IslandId.ocean: 'शब्दों का समंदर',
    IslandId.village: 'शब्दों का गाँव',
    IslandId.treasure: 'ख़ज़ाने वाला टापू',
    IslandId.castle: 'कहानी का क़िला',
    IslandId.observatory: 'तूफ़ानी क़िला',
  };

  static const islandTags = <IslandId, String>{
    IslandId.forest: 'आवाज़ें सुनो',
    IslandId.valley: 'अक्षर पहचानो',
    IslandId.ocean: 'जोड़कर पढ़ो',
    IslandId.village: 'शब्द पहचानो',
    IslandId.treasure: 'सही लिखो',
    IslandId.castle: 'कहानी समझो',
    IslandId.observatory: 'तूफ़ान की परीक्षा',
  };

  /// Keepers freed from the cloud cages (the island's guardian).
  static const keepers = <IslandId, String>{
    IslandId.forest: 'उस्ताद भालू',
    IslandId.valley: 'आर्या',
    IslandId.ocean: 'कप्तान कछुआ',
    IslandId.village: 'इंस्पेक्टर उल्लू',
    IslandId.treasure: 'रानी मधु',
    IslandId.castle: 'परी राजकुमारी',
  };

  /// The two Sound Forest games.
  static const gameNames = <GameId, String>{
    GameId.soundOrchestra: 'जंगल का बैंड',
    GameId.soundNinja: 'आवाज़ निंजा',
  };
  static const gameTaglines = <GameId, String>{
    GameId.soundOrchestra: 'सुनो और मिलाओ।',
    GameId.soundNinja: 'आवाज़ों को काटो।',
  };
  static const gameHow = <GameId, String>{
    GameId.soundOrchestra: 'बैंड को सुनो, फिर जिसकी तुक मिले उसे चुनो।',
    GameId.soundNinja: 'शब्द में कितने टुकड़े हैं? फल को उतनी बार काटो।',
  };
  static const gameConcepts = <GameId, String>{
    GameId.soundOrchestra: 'तुक वाला शब्द ढूँढो',
    GameId.soundNinja: 'शब्द को टुकड़ों में काटो',
  };
  static const levelNames = <GameId, List<String>>{
    GameId.soundOrchestra: ['आसान तुक', 'मुश्किल तुक', 'सिर्फ़ सुनो', 'तुक का उस्ताद'],
    GameId.soundNinja: ['2 टुकड़े', '3 टुकड़े', 'लंबे शब्द', 'हर आवाज़'],
  };

  static const belts = ['सफ़ेद', 'पीली', 'नारंगी', 'हरी', 'नीली', 'बैंगनी', 'भूरी', 'काली'];

  static const seasons = <String, String>{
    'The Lost Words': 'खोए हुए शब्द',
  };

  /// Short interface strings, keyed by their English text (see Tr in core/loc.dart).
  static const ui = <String, String>{
    // map page
    'Start here!': 'यहाँ से शुरू करो!',
    '✓ chapter complete': '✓ पूरा हो गया',
    '⚡ won': '⚡ जीत गए',
    '⚡ trial': '⚡ परीक्षा',
    'Free all six Story Keepers to reach Gumsum’s Storm Citadel! ({n}/6 free)': 'पहले छहों कहानी के रखवालों को छुड़ाओ, तभी गुमसुम के तूफ़ानी क़िले तक पहुँचोगे! ({n}/6 छूट गए)',
    '⚡ All six Keepers are free! Gumsum’s Storm Citadel has appeared!': '⚡ छहों रखवाले छूट गए! गुमसुम का तूफ़ानी क़िला दिख गया!',
    'Explorer’s Journal': 'खोजी की डायरी',
    'My treasures': 'मेरे ख़ज़ाने',
    'Grown-up area': 'बड़ों के लिए',
    '🌉 The Star Bridge has appeared!': '🌉 तारों वाला पुल आ गया!',
    'All seven islands played — Gumsum is waiting.': 'सातों टापू खेल लिए — गुमसुम इंतज़ार कर रहा है।',
    'Let’s Go!': 'चलो!',
    '{season} · Quest board': '{season} · मिशन बोर्ड',
    'Level {n}': 'लेवल {n}',
    '{game} · Level {n}': '{game} · लेवल {n}',
    '{game} · Level {n} · Boss': '{game} · लेवल {n} · बॉस',
    // island sheet
    '{n}% restored': '{n}% वापस आ गया',
    'Clear {k} levels of {game} to unlock  ·  {done}/{k} done': '{game} के {k} लेवल पूरे करो, तब यह खुलेगा  ·  {done}/{k} हो गए',
    'Clear level {a} first to open level {b}!': 'पहले लेवल {a} पूरा करो, तब लेवल {b} खुलेगा!',
    'All keys!': 'सारी चाबियाँ!',
    'Replay': 'दोबारा खेलो',
    'Play for keys': 'चाबी के लिए खेलो',
    'Play': 'खेलो',
    'Locked': 'बंद',
    '{name} is free! 🎉': '{name} छूट गए! 🎉',
    'Free {name}!': '{name} को छुड़ाओ!',
    'Every key won on this island.': 'इस टापू की सारी चाबियाँ मिल गईं।',
    'Win every key on this island to open the cage.': 'पिंजरा खोलने के लिए इस टापू की सारी चाबियाँ जीतो।',
    // game screen
    'Back to the map': 'नक़्शे पर वापस',
    'Level {n} of {m}': 'लेवल {n}/{m}',
    ' · Boss': ' · बॉस',
    ' · Replay': ' · दोबारा',
    '👀  Watch how to play · tap to start': '👀  देखो कैसे खेलते हैं · शुरू करने के लिए दबाओ',
    // game bits
    'Tap a band member to hear their word, then ✓': 'बैंड के साथी को दबाकर उसका शब्द सुनो, फिर ✓ दबाओ',
    'Sing it again': 'फिर से सुनाओ',
    'Count again': 'फिर से गिनो',
    'Start again': 'फिर से शुरू करो',
    'Hear it again': 'फिर से सुनो',
    'Tap to hear · swipe through to slice': 'सुनने के लिए दबाओ · काटने के लिए उँगली चलाओ',
    'Combo ×{n}! Ninja!': 'कॉम्बो ×{n}! निंजा!',
    'combo ×{n}': 'कॉम्बो ×{n}',
    '{hint} Say “{w}” slowly.': '{hint} “{w}” को धीरे-धीरे बोलो।',
    ' Belt': ' बेल्ट',
    'Slice “{w}” into its beats!': '“{w}” को टुकड़ों में काटो!',
    'Dev round': 'टेस्ट राउंड',
    // onboarding-to-screening bridge screen
    'Your First Adventure': 'तुम्हारा पहला सफ़र',
    'Your Next Adventure Awaits!': 'तुम्हारा अगला सफ़र तैयार है!',
    'Let’s Fix It!': 'चलो, ठीक करते हैं!',
    '{companion} says: {line}': '{companion} कहता है: {line}',
    'For grown-ups: this adventure is a literacy screening (about 15 minutes). The phone listens to reading-aloud activities and scores them automatically. It is not a diagnosis.':
        'बड़ों के लिए: यह सफ़र पढ़ने-लिखने की एक जाँच है (क़रीब 15 मिनट)। फ़ोन बच्चे को ज़ोर से पढ़ते हुए सुनता है और अपने-आप नंबर देता है। यह कोई बीमारी की जाँच नहीं है।',
    // reward screen
    'You Did It!': 'शाबाश!',
    '+{n} stars': '+{n} सितारे',
    'New treasure': 'नया ख़ज़ाना',
    'Keep going': 'चलते रहो',
    'You’re getting stronger!': 'तुम और मज़बूत हो रहे हो!',
    'Great effort! We’ll practise this together.': 'बहुत मेहनत की! इसे हम मिलकर और सीखेंगे।',
    'Great job, Explorer!': 'शाबाश, खोजी!',
    '{game} got stronger!': '{game} में तुम और मज़बूत हो गए!',
    '{game}: a friendly warm-up next time': '{game}: अगली बार पहले एक आसान वार्म-अप',
    'You found a new treasure!': 'तुम्हें नया ख़ज़ाना मिला!',
    'New game unlocked!': 'नया खेल खुल गया!',
    '{game} is open on this island': '{game} इस टापू पर खुल गया है',
    '{island} restored': '{island} वापस आ रहा है',
    '🏆 Every level on this island is cleared! +5 stars': '🏆 इस टापू के सारे लेवल पूरे हो गए! +5 सितारे',
    'Story Gem!': 'कहानी का नगीना!',
    'Emerald of Sounds': 'आवाज़ों का हरा नगीना',
    'Milo found a gift!': 'मिलो को तोहफ़ा मिला!',
    'Continue': 'आगे बढ़ो',
    'Level {l} cleared! ⭐': 'लेवल {l} पूरा! ⭐',
    'Level {l} played again ⭐': 'लेवल {l} फिर से खेला ⭐',
    'Almost! Play level {l} again to clear it': 'थोड़ा और! लेवल {l} फिर से खेलो, तब पूरा होगा',
    'Get at least half right the first time.': 'पहली बार में कम से कम आधे जवाब सही दो।',
    'All {n} keys on this level!': 'इस लेवल की सारी {n} चाबियाँ!',
    '{won} key · get every answer right for all {n}': '{won} चाबी · सारी {n} चाबियों के लिए हर जवाब सही दो',
    'Island: 🔑 {a} / {b}': 'टापू: 🔑 {a} / {b}',
    'Level {n} is open!': 'लेवल {n} खुल गया!',
  };
}
