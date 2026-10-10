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
      await t.setVolume(1.0); // full volume: the phone voice used to be much quieter than the recorded voices
      await t.awaitSpeakCompletion(true); // speak() now returns when the sentence has really been said
      t.setErrorHandler((m) => debugPrint('TTS error: $m'));
      _tts = t;
    } catch (e) {
      _failed = true;
      debugPrint('TTS unavailable: $e');
    }
  }

  /// Speaks [text]; the returned future completes when the phone has finished saying it (or after [maxWait]).
  Future<void> speak(String text, String locale, {Duration maxWait = const Duration(seconds: 40)}) async {
    if (!enabled || text.trim().isEmpty) return;
    try {
      await _init();
      final t = _tts;
      if (t == null) return;
      if (locale != _locale) {
        final r = await t.setLanguage(locale);
        if (r != 1) debugPrint('TTS: language $locale not available (result $r)');
        _locale = locale;
      }
      await t.stop();
      final r = await t.speak(text).timeout(maxWait, onTimeout: () => 0);
      if (r != 1) debugPrint('TTS: speak("${text.length > 24 ? '${text.substring(0, 24)}…' : text}") result $r');
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
