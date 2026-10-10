import 'dart:convert';
import 'package:flutter/services.dart';

/// All voiced story lines: assets/story/lines_en.json  id → {who, text}.
/// The same file feeds the voice generator (tool/gen_voices.py), so text and audio never drift apart.
/// Hindi (demo) adds assets/story/lines_hi.json with the same ids: when the child chose Hindi, a line that exists there is
/// shown and spoken in Hindi; every other line stays English.
class StoryLines {
  static final StoryLines instance = StoryLines._();
  StoryLines._();
  Map<String, ({String who, String text})> _l = {};
  Map<String, ({String who, String text})> _hi = {};
  bool _loaded = false;

  /// 'en' or 'hi' (set by AppState from the language the child chose).
  String lang = 'en';

  Future<void> load([String lang = 'en']) async {
    if (_loaded) return;
    _l = await _read('assets/story/lines_$lang.json');
    _hi = await _read('assets/story/lines_hi.json');
    _loaded = true;
  }

  static Future<Map<String, ({String who, String text})>> _read(String path) async {
    try {
      final raw = jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, (who: (v as Map)['who'] as String, text: v['text'] as String)));
    } catch (_) {
      return {};
    }
  }

  /// True when [id] is spoken in Hindi right now (Hindi chosen and a Hindi version of the line exists).
  bool isHindi(String id) => lang == 'hi' && _hi.containsKey(id);

  ({String who, String text})? operator [](String id) => (lang == 'hi' ? _hi[id] : null) ?? _l[id];
  String text(String id, [String fallback = '']) => this[id]?.text ?? fallback;
  String who(String id, [String fallback = 'milo']) => this[id]?.who ?? fallback;
}
