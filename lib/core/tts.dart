import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin, failure-tolerant wrapper around on-device text to speech.
/// The prototype never depends on audio: every instruction is also visual.
class Speaker {
  static final Speaker instance = Speaker._();
  Speaker._();

  FlutterTts? _tts;
  bool enabled = true;
  String _locale = '';
  bool _failed = false;

  Future<void> _init() async {
    if (_tts != null || _failed) return;
    try {
      final t = FlutterTts();
      await t.setSpeechRate(0.42);
      await t.setPitch(1.1);
      _tts = t;
    } catch (e) {
      _failed = true;
      debugPrint('TTS unavailable: $e');
    }
  }

  Future<void> speak(String text, String locale) async {
    if (!enabled || text.trim().isEmpty) return;
    try {
      await _init();
      final t = _tts;
      if (t == null) return;
      if (locale != _locale) {
        await t.setLanguage(locale);
        _locale = locale;
      }
      await t.stop();
      await t.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
