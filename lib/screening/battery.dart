import 'models.dart';

/// Provisional reference values per grade band, from published expectations for Indian primary
/// learners. They are deliberately labelled PROVISIONAL and must be replaced by pilot norms.
class Norm {
  final double accMean, accSd;
  final double? rateMean, rateSd;
  final double rateWeight; // 0 = accuracy only, 1 = rate only
  const Norm(this.accMean, this.accSd, {this.rateMean, this.rateSd, this.rateWeight = 0});
}

class SubtestDef {
  final String id;
  final Construct construct;
  final TaskType task;
  final Map<String, String> title; // child-facing, per language
  final Map<String, String> line; // short spoken instruction, per language
  final String parentName;
  final String emoji;
  final int junior, middle; // number of items (0 = not given)
  final int discontinue; // stop after this many misses in a row
  final bool speech;
  final Norm normJunior, normMiddle;
  final String rateLabel;
  const SubtestDef({
    required this.id,
    required this.construct,
    required this.task,
    required this.title,
    required this.line,
    required this.parentName,
    required this.emoji,
    required this.junior,
    required this.middle,
    this.discontinue = 3,
    this.speech = false,
    required this.normJunior,
    required this.normMiddle,
    this.rateLabel = '',
  });
  int count(GradeBand b) => b == GradeBand.junior ? junior : middle;
  Norm norm(GradeBand b) => b == GradeBand.junior ? normJunior : normMiddle;
  String t(String lang) => title[lang] ?? title['en']!;
  String l(String lang) => line[lang] ?? line['en']!;
}

const constructDomain = {
  Construct.phonological: Domain.phonologicalProcessing,
  Construct.rapidNaming: Domain.phonologicalProcessing,
  Construct.gpc: Domain.literacy,
  Construct.decoding: Domain.literacy,
  Construct.wordRecognition: Domain.literacy,
  Construct.spelling: Domain.literacy,
  Construct.comprehension: Domain.literacy,
  Construct.oralLanguage: Domain.semanticRetrieval,
};

const constructNames = {
  Construct.phonological: 'Phonological Awareness',
  Construct.gpc: 'Letter–Sound Knowledge',
  Construct.decoding: 'Decoding (new words)',
  Construct.wordRecognition: 'Word Reading',
  Construct.spelling: 'Spelling',
  Construct.comprehension: 'Reading Comprehension & Fluency',
  Construct.oralLanguage: 'Oral Language',
  Construct.rapidNaming: 'Rapid Naming Speed',
};

const domainNames = {
  Domain.phonologicalProcessing: 'Phonological processing',
  Domain.literacy: 'Literacy',
  Domain.semanticRetrieval: 'Semantic retrieval / oral language',
};

/// The battery, in the order the child meets the stations.
const battery = <SubtestDef>[
  SubtestDef(
    id: 'rhyme',
    construct: Construct.phonological,
    task: TaskType.picture,
    title: {'en': 'Rhyme Time', 'hi': 'तुकबंदी खेल'},
    line: {'en': 'Which one sounds like it?', 'hi': 'कौन सा इसके जैसा सुनाई देता है?'},
    parentName: 'Rhyme recognition',
    emoji: '🎵',
    junior: 5,
    middle: 5,
    normJunior: Norm(.80, .17),
    normMiddle: Norm(.90, .10),
  ),
  SubtestDef(
    id: 'firstSound',
    construct: Construct.phonological,
    task: TaskType.picture,
    title: {'en': 'Sound Detective', 'hi': 'आवाज़ जासूस'},
    line: {'en': 'Find the one that starts with this sound!', 'hi': 'इस आवाज़ से शुरू होने वाला ढूँढो!'},
    parentName: 'Initial sound identification',
    emoji: '🔎',
    junior: 5,
    middle: 0,
    normJunior: Norm(.82, .17),
    normMiddle: Norm(.9, .1),
  ),
  SubtestDef(
    id: 'phonemeManip',
    construct: Construct.phonological,
    task: TaskType.audioChoice,
    title: {'en': 'Sound Magic', 'hi': 'आवाज़ का जादू'},
    line: {'en': 'Listen to the magic trick, then pick what is left!', 'hi': 'जादू सुनो, फिर बचा हुआ चुनो!'},
    parentName: 'Phoneme / syllable deletion and replacement',
    emoji: '🪄',
    junior: 4,
    middle: 6,
    normJunior: Norm(.62, .22),
    normMiddle: Norm(.78, .17),
  ),
  SubtestDef(
    id: 'letterSound',
    construct: Construct.gpc,
    task: TaskType.letterChoice,
    title: {'en': 'Letter Archer', 'hi': 'अक्षर तीरंदाज़'},
    line: {'en': 'Hear the sound and hit the letter!', 'hi': 'आवाज़ सुनो और अक्षर पर निशाना लगाओ!'},
    parentName: 'Letter / akshara–sound identification',
    emoji: '🏹',
    junior: 6,
    middle: 6,
    normJunior: Norm(.78, .18),
    normMiddle: Norm(.88, .12),
  ),
  SubtestDef(
    id: 'pictureNaming',
    construct: Construct.oralLanguage,
    task: TaskType.readAloud,
    title: {'en': 'Picture Talk', 'hi': 'चित्र बोलो'},
    line: {'en': 'Say the name of the picture!', 'hi': 'चित्र का नाम बोलो!'},
    parentName: 'Picture naming (expressive vocabulary)',
    emoji: '🖼️',
    junior: 6,
    middle: 6,
    speech: true,
    normJunior: Norm(.72, .18),
    normMiddle: Norm(.82, .14),
  ),
  SubtestDef(
    id: 'ran',
    construct: Construct.rapidNaming,
    task: TaskType.ran,
    title: {'en': 'Speedy Namer', 'hi': 'फटाफट नाम'},
    line: {'en': 'Say all the pictures as fast as you can!', 'hi': 'सारे चित्र जितनी जल्दी हो सके बोलो!'},
    parentName: 'Rapid automatized naming (objects)',
    emoji: '⚡',
    junior: 1,
    middle: 1,
    discontinue: 99,
    speech: true,
    normJunior: Norm(.85, .15, rateMean: .70, rateSd: .22, rateWeight: .7),
    normMiddle: Norm(.92, .08, rateMean: .95, rateSd: .25, rateWeight: .7),
    rateLabel: 'names per second',
  ),
  SubtestDef(
    id: 'wordReading',
    construct: Construct.wordRecognition,
    task: TaskType.readAloud,
    title: {'en': 'Read the Magic Words', 'hi': 'जादुई शब्द पढ़ो'},
    line: {'en': 'Read the word out loud!', 'hi': 'शब्द ज़ोर से पढ़ो!'},
    parentName: 'Word reading (accuracy and speed)',
    emoji: '📜',
    junior: 8,
    middle: 10,
    speech: true,
    normJunior: Norm(.66, .23),
    normMiddle: Norm(.85, .13),
  ),
  SubtestDef(
    id: 'nonwordReading',
    construct: Construct.decoding,
    task: TaskType.readAloud,
    title: {'en': 'Silly Alien Words', 'hi': 'अजीब एलियन शब्द'},
    line: {'en': 'These are alien words! Sound them out!', 'hi': 'ये एलियन शब्द हैं! जोड़कर पढ़ो!'},
    parentName: 'Nonword reading (decoding)',
    emoji: '👽',
    junior: 6,
    middle: 8,
    speech: true,
    normJunior: Norm(.48, .25),
    normMiddle: Norm(.68, .20),
  ),
  SubtestDef(
    id: 'spelling',
    construct: Construct.spelling,
    task: TaskType.tiles,
    title: {'en': 'Fix the Pirate Map', 'hi': 'समुद्री नक्शा ठीक करो'},
    line: {'en': 'Hear the word and build it!', 'hi': 'शब्द सुनो और बनाओ!'},
    parentName: 'Spelling / dictation',
    emoji: '🗺️',
    junior: 5,
    middle: 6,
    normJunior: Norm(.58, .24),
    normMiddle: Norm(.75, .18),
  ),
  SubtestDef(
    id: 'listening',
    construct: Construct.oralLanguage,
    task: TaskType.listening,
    title: {'en': 'Story Time', 'hi': 'कहानी का समय'},
    line: {'en': 'Listen to the story, then answer!', 'hi': 'कहानी सुनो, फिर जवाब दो!'},
    parentName: 'Listening comprehension',
    emoji: '👂',
    junior: 1,
    middle: 1,
    discontinue: 99,
    normJunior: Norm(.78, .20),
    normMiddle: Norm(.85, .15),
  ),
  SubtestDef(
    id: 'readingComp',
    construct: Construct.comprehension,
    task: TaskType.passage,
    title: {'en': 'Read the Magic Scroll', 'hi': 'जादुई चिट्ठी पढ़ो'},
    line: {'en': 'Read it, then pick the answer!', 'hi': 'पढ़ो, फिर जवाब चुनो!'},
    parentName: 'Reading comprehension',
    emoji: '📖',
    junior: 3,
    middle: 1,
    discontinue: 99,
    normJunior: Norm(.70, .22),
    normMiddle: Norm(.75, .20),
  ),
  SubtestDef(
    id: 'oralReading',
    construct: Construct.comprehension,
    task: TaskType.oralReading,
    title: {'en': 'Read to Milo', 'hi': 'मीलो को पढ़कर सुनाओ'},
    line: {'en': 'Read it out loud to me!', 'hi': 'मुझे ज़ोर से पढ़कर सुनाओ!'},
    parentName: 'Oral reading fluency (words correct per minute)',
    emoji: '🗣️',
    junior: 1,
    middle: 1,
    discontinue: 99,
    speech: true,
    normJunior: Norm(.80, .18, rateMean: 30, rateSd: 15, rateWeight: .5),
    normMiddle: Norm(.90, .09, rateMean: 65, rateSd: 25, rateWeight: .5),
    rateLabel: 'words correct per minute',
  ),
  SubtestDef(
    id: 'fluency',
    construct: Construct.oralLanguage,
    task: TaskType.fluency,
    title: {'en': 'Animal Parade', 'hi': 'जानवरों की परेड'},
    line: {'en': 'Say as many animals as you can!', 'hi': 'जितने जानवर याद हों, बोलो!'},
    parentName: 'Semantic verbal fluency (60 s)',
    emoji: '🦁',
    junior: 1,
    middle: 1,
    discontinue: 99,
    speech: true,
    normJunior: Norm(1, 1, rateMean: 7, rateSd: 3, rateWeight: 1),
    normMiddle: Norm(1, 1, rateMean: 11, rateSd: 4, rateWeight: 1),
    rateLabel: 'different animals',
  ),
];

SubtestDef subtestById(String id) => battery.firstWhere((s) => s.id == id);

GradeBand bandForGrade(String grade) {
  final g = grade.toLowerCase();
  if (g.contains('3') || g.contains('4') || g.contains('5')) return GradeBand.middle;
  return GradeBand.junior;
}
