import 'models.dart';
import 'question_store.dart';
import 'bank_en.dart';
import 'bank_hi.dart';

/// A language's screening content. Items are written for the language (akshara/matra aware for Hindi),
/// not translated from English.
abstract class ScreenBank {
  String get code;
  String get tts;
  String get asr; // speech-recognizer locale
  List<SItem> get items;
  Set<String> get animals;
  Set<String> get foods;
  Map<String, String> get ui; // a few child-facing strings

  /// The questions of one station for this form (A/B) and grade band: from the database when the app has downloaded some for
  /// this station, otherwise the questions bundled in the app.
  List<SItem> forSubtest(String id, String pool, GradeBand band) {
    final fromDb = QuestionStore.instance.forSubtest(code, id);
    final source = fromDb.isNotEmpty ? fromDb : items;
    return source.where((i) => i.subtest == id && i.pool == pool && (i.only == null || i.only == band)).toList()..sort((a, b) => a.difficulty.compareTo(b.difficulty));
  }
}

ScreenBank bankFor(String lang) => lang == 'hi' ? HindiScreenBank() : EnglishScreenBank();

ChoiceOpt pic(String label, String emoji) => ChoiceOpt(label, emoji: emoji, say: label);
ChoiceOpt aud(String label) => ChoiceOpt(label, say: label);
