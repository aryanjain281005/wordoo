import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// The screening question bank as the app sees it.
///
/// The database (MongoDB, behind the Readle server) is the source of truth: seed questions plus the ones the Question Agent
/// (Gemini) has written. The app keeps a copy of the last download on the phone, and falls back to the questions bundled in
/// the code ([ScreenBank.items]) for any station the database has nothing for, so the screening works fully offline.
class QuestionStore {
  static final QuestionStore instance = QuestionStore._();
  QuestionStore._();

  final Map<String, Map<String, SItem>> _cloud = {}; // lang → id → question
  bool get hasCloud => _cloud.values.any((m) => m.isNotEmpty);

  /// Questions the database has for [lang] and [subtest] (empty when the app has not downloaded any).
  List<SItem> forSubtest(String lang, String subtest) => [for (final i in _cloud[lang]?.values ?? const <SItem>[]) if (i.subtest == subtest) i];

  int size(String lang) => _cloud[lang]?.length ?? 0;
  int generated(String lang) => _cloud[lang]?.values.where((i) => i.source == 'gemini').length ?? 0;

  /// Adds / replaces questions (a download, or what the agent just wrote).
  void merge(String lang, Iterable<SItem> items) {
    final m = _cloud.putIfAbsent(lang, () => {});
    for (final i in items) {
      m[i.id] = i;
    }
  }

  /// A fresh download: the database is the truth, so anything it no longer has (removed or switched off) leaves the phone too.
  void replace(String lang, Iterable<SItem> items) {
    _cloud[lang] = {for (final i in items) i.id: i};
  }

  void clear() => _cloud.clear();

  // ---- a copy on the phone ----
  static String _key(String lang) => 'cloud_bank_$lang';

  Future<void> load(String lang) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key(lang));
      if (raw == null) return;
      merge(lang, [for (final j in jsonDecode(raw) as List) SItem.fromJson(Map<String, dynamic>.from(j as Map))]);
    } catch (_) {}
  }

  Future<void> save(String lang) async {
    try {
      final all = _cloud[lang]?.values.toList() ?? const [];
      await (await SharedPreferences.getInstance()).setString(_key(lang), jsonEncode([for (final i in all) i.toJson()]));
    } catch (_) {}
  }
}
