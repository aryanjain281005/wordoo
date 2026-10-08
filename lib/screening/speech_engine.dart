import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'models.dart';
import 'voxlexi.dart';

/// Thin wrapper around the device speech recognizer (Android: Google on-device / online recognizer).
/// Captures transcript + alternates + the sound-level stream, then hands them to [VoxLexi] for analysis.
class SpeechEngine {
  static final SpeechEngine instance = SpeechEngine._();
  SpeechEngine._();

  final SpeechToText _stt = SpeechToText();
  bool? _available;
  List<String> _locales = [];
  void Function(String status)? _onStatus;
  void Function(String error)? _onError;
  String? lastError;

  bool get available => _available ?? false;

  Future<bool> init() async {
    if (_available != null) return _available!;
    if (kIsWeb) return _available = false;
    try {
      _available = await _stt.initialize(
        onStatus: (s) => _onStatus?.call(s),
        onError: (e) {
          lastError = e.errorMsg;
          _onError?.call(e.errorMsg);
        },
      );
      if (_available!) {
        _locales = (await _stt.locales()).map((l) => l.localeId).toList();
      }
    } catch (e) {
      debugPrint('speech init failed: $e');
      _available = false;
    }
    return _available!;
  }

  /// Picks the closest supported locale (e.g. en_IN → en_US if Indian English is missing).
  String resolve(String wanted) {
    if (_locales.isEmpty || _locales.contains(wanted)) return wanted;
    final lang = wanted.split('_').first;
    return _locales.firstWhere((l) => l.startsWith(lang), orElse: () => wanted);
  }

  Future<SpeechMetrics> capture({
    required String locale,
    Duration listenFor = const Duration(seconds: 8),
    Duration pauseFor = const Duration(seconds: 2),
    bool dictation = false,
    void Function(String partial)? onPartial,
    void Function(double level)? onLevel,
  }) async {
    if (!await init()) return const SpeechMetrics();
    final levels = <(int, double)>[];
    final sw = Stopwatch()..start();
    var transcript = '';
    var alternates = <String>[];
    var confidence = 0.0;
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    _onStatus = (s) {
      if (s == 'done' || s == 'notListening') {
        Future.delayed(const Duration(milliseconds: 350), finish);
      }
    };
    _onError = (_) => finish();
    try {
      await _stt.listen(
        onResult: (SpeechRecognitionResult r) {
          transcript = r.recognizedWords;
          alternates = r.alternates.map((a) => a.recognizedWords).toList();
          confidence = r.confidence;
          onPartial?.call(transcript);
          if (r.finalResult) finish();
        },
        onSoundLevelChange: (l) {
          levels.add((sw.elapsedMilliseconds, l));
          onLevel?.call(l);
        },
        listenOptions: SpeechListenOptions(
          listenFor: listenFor,
          pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: true,
          listenMode: dictation ? ListenMode.dictation : ListenMode.confirmation,
          localeId: resolve(locale),
        ),
      );
    } catch (e) {
      debugPrint('listen failed: $e');
      finish();
    }
    await done.future.timeout(listenFor + const Duration(seconds: 4), onTimeout: () {});
    if (_stt.isListening) await _stt.stop();
    _onStatus = null;
    _onError = null;
    return VoxLexi.analyzeLevels(levels, transcript: transcript, alternates: alternates, confidence: confidence);
  }

  Future<void> stop() async {
    if (_stt.isListening) await _stt.stop();
  }
}
