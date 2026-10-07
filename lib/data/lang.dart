import 'content_en.dart';
import 'content_hi.dart';

/// Content forms keep assessment items fresh:
///  A = baseline / even-week assessment, B = odd-week reassessment, P = practice only.
enum Pool { a, b, p }

Pool formFor(int index) => index % 4 == 0 ? Pool.a : (index % 4 == 1 ? Pool.b : Pool.p);

class Word {
  final String text, emoji;
  final List<String> units;
  final int level;
  final String? rime;
  final Pool form;
  const Word(this.text, this.emoji, this.units, this.level, this.form, {this.rime});
  String get id => 'w:$text';
}

class Graph {
  final String text, say;
  final int level;
  final List<String> similar;
  final Pool form;
  const Graph(this.text, this.say, this.level, this.form, {this.similar = const []});
  String get id => 'g:$level:$text';
}

class NonWord {
  final List<String> units;
  final String correct;
  final List<String> wrong;
  final Pool form;
  const NonWord(this.units, this.correct, this.wrong, this.form);
}

class Deletion {
  final String word, removed, result;
  final List<String> wrong;
  final String emoji;
  final Pool form;
  const Deletion(this.word, this.emoji, this.removed, this.result, this.wrong, this.form);
}

class StoryQ {
  final int level;
  final String tag;
  final String q;
  final List<String> options;
  final int correct;
  const StoryQ(this.level, this.tag, this.q, this.options, this.correct);
}

class Story {
  final String id, title, emoji, text;
  final Pool form;
  final List<StoryQ> qs;
  const Story(this.id, this.form, this.title, this.emoji, this.text, this.qs);
}

/// Language pack: everything language-specific lives behind this interface.
/// The common engine never contains words, letters, prompts or stories.
abstract class LangPack {
  String get code; // 'en'
  String get name; // 'English'
  String get native; // 'English' / 'हिन्दी'
  String get tts; // 'en-US'
  bool get available;
  List<Word> get words;
  List<Graph> get graphs;
  List<NonWord> get nonWords;
  List<Deletion> get deletions;
  List<Story> get stories;
  Map<String, String> get prompts;

  /// Key used to compare the first sound of a word.
  String firstKey(Word w);

  /// Key used to compare how a word ends (rhyme).
  String? endKey(Word w) => w.rime;

  /// Units used as spelling tiles.
  List<String> spellUnits(Word w);

  /// Extra tiles used as spelling distractors, ranked by difficulty.
  List<String> spellDistractors(Word w, int level, int count);

  /// Visually / orthographically close wrong spellings for word recognition.
  List<String> confusions(Word w);

  /// Spoken form of a sound unit.
  String sayUnit(String u);

  String p(String key, {String w = '', String r = ''}) =>
      (prompts[key] ?? key).replaceAll('{w}', w).replaceAll('{r}', r);

  /// Classifies a wrong build by comparing to the expected unit list.
  String spellingError(List<String> got, List<String> want);
}

class LangRegistry {
  static final List<LangPack> all = [EnglishPack(), HindiPack(), ComingSoonPack('kn', 'Kannada', 'ಕನ್ನಡ')];
  static LangPack byCode(String c) => all.firstWhere((l) => l.code == c, orElse: () => all.first);
  static List<LangPack> get available => all.where((l) => l.available).toList();
}

/// Placeholder showing how further Indian languages plug in later.
class ComingSoonPack extends EnglishPack {
  final String _code, _name, _native;
  ComingSoonPack(this._code, this._name, this._native);
  @override
  String get code => _code;
  @override
  String get name => _name;
  @override
  String get native => _native;
  @override
  bool get available => false;
}
