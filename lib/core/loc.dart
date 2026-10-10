import '../data/hi_text.dart';

/// Which language the child chose at set-up. Everything Hindi in the app is gated on this, so the English version never changes.
class Loc {
  static String code = 'en';
  static bool get hi => code == 'hi';
}

/// Translates a short interface string into everyday Hindi when [hi] is true; with English it returns the text untouched.
/// The Hindi texts live in lib/data/hi_text.dart and are written the way a family talks at home (no formal Hindi).
class Tr {
  final bool hi;
  const Tr(this.hi);
  static const en = Tr(false);

  /// `tr('Level')` → 'लेवल' in Hindi mode, 'Level' otherwise.
  String call(String text) => hi ? (HiText.ui[text] ?? text) : text;

  /// With values: `tr.f('{n} of {m} levels cleared', {'n': 2, 'm': 4})`.
  String f(String text, Map<String, Object> values) {
    var s = call(text);
    values.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }
}
