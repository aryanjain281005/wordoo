import 'dart:convert';
import 'package:flutter/services.dart';

/// All voiced story lines (English v1): assets/story/lines_en.json  id → {who, text}.
/// The same file feeds the voice generator (tool/gen_voices.py), so text and audio never drift apart.
class StoryLines {
  static final StoryLines instance = StoryLines._();
  StoryLines._();
  Map<String, ({String who, String text})> _l = {};
  bool _loaded = false;

  Future<void> load([String lang = 'en']) async {
    if (_loaded) return;
    try {
      final raw = jsonDecode(await rootBundle.loadString('assets/story/lines_$lang.json')) as Map<String, dynamic>;
      _l = raw.map((k, v) => MapEntry(k, (who: (v as Map)['who'] as String, text: v['text'] as String)));
    } catch (_) {}
    _loaded = true;
  }

  ({String who, String text})? operator [](String id) => _l[id];
  String text(String id, [String fallback = '']) => _l[id]?.text ?? fallback;
  String who(String id, [String fallback = 'milo']) => _l[id]?.who ?? fallback;
}
