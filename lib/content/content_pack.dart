import 'en/en_pack.dart';
import 'hi/hi_pack.dart';

/// Language-independent description of a word. The engine only ever reads these features;
/// how they are computed is language-specific (English now, Hindi later).
class WordEntry {
  final String text;
  final String? emoji;
  final List<String> units; // grapheme / sound units (English: sh, ee, igh … ; Hindi later: aksharas)
  final int syllables;
  final int digraphs;
  final int blends;
  final int vowelTeams;
  final bool silentE;
  final bool irregular;
  final bool common;
  final double difficulty; // continuous 1..10
  final bool nonword;
  final String? rime; // last vowel unit + rest (cat → at)
  const WordEntry({
    required this.text,
    this.emoji,
    required this.units,
    required this.syllables,
    required this.digraphs,
    required this.blends,
    required this.vowelTeams,
    required this.silentE,
    required this.irregular,
    required this.common,
    required this.difficulty,
    this.nonword = false,
    this.rime,
  });
  int get step => difficulty.round().clamp(1, 10);
  String get firstUnit => units.first;
  String get id => (nonword ? 'nw:' : 'w:') + text;

}

class GraphemeEntry {
  final String text;
  final String say; // how the sound is spoken by the voice
  final int step; // 1..10 ladder position
  final List<String> confusable;
  const GraphemeEntry(this.text, this.say, this.step, [this.confusable = const []]);
  String get id => 'g:$text';
}

class StoryQuestion {
  final String q;
  final List<(String label, String? emoji)> options; // first option is correct
  final String type; // detail | sequence | cause | inference | prediction
  const StoryQuestion(this.q, this.options, this.type);
}

class StoryEntry {
  final String id;
  final String title;
  final String emoji;
  final String text;
  final int step; // 1..10
  final List<StoryQuestion> questions;
  const StoryEntry(this.id, this.title, this.emoji, this.text, this.step, this.questions);
}

/// Everything a language must provide for the games.
abstract class GameContentPack {
  String get code;
  String get tts;
  List<WordEntry> get words;
  List<GraphemeEntry> get graphemes;
  List<StoryEntry> get stories;
  Map<String, String> get prompts;
  String sayUnit(String unit);

  /// Picture words grouped by how they SOUND at the end (word → family). Only these are used for rhyme
  /// games, so a child is never marked wrong for a real rhyme (spelling alone gives owl/bowl, cow/snow…).
  Map<String, String> get rhymeFamily => const {};

  /// Made-up but pronounceable words at a given step (decoding practice).
  List<WordEntry> nonwords(int step, int count, int seed);

  /// Close wrong spellings (visual / orthographic confusions).
  List<String> confusions(String word, int seed);

  /// Procedurally generated short story for early comprehension steps.
  StoryEntry storyFromTemplate(int step, int seed);

  /// The content the Sound Forest games draw from. English: the pack itself (nothing changes). The Hindi demo swaps in Hindi
  /// words and rhymes for those two games only.
  GameContentPack get phono => this;

  String p(String key, {String w = '', String r = '', String x = ''}) =>
      (prompts[key] ?? key).replaceAll('{w}', w).replaceAll('{r}', r).replaceAll('{x}', x);
}

/// English is the full game. Hindi (demo) is Sound Forest only: [forIsland] gives Hindi content for that island and English
/// for everything else, so no other game changes when a child chooses Hindi.
class GameContent {
  static const enabledLanguages = ['en', 'hi'];
  static final GameContentPack _en = EnglishGameContent();
  static final GameContentPack _hi = HindiGameContent();
  static GameContentPack of(String lang) => _en; // everything outside the Hindi demo
  static GameContentPack forHindiDemo(String lang) => lang == 'hi' ? _hi : _en;
}
