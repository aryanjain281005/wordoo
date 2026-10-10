import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/cloud.dart';
import 'models.dart';
import 'voxlexi.dart';
import 'whisper_mapper.dart';

/// Speech recognition for the screening. Two engines, same result type:
///  • OpenAI Whisper (preferred, better with children's voices and mispronunciations): the microphone is recorded here, the
///    recording is sent to the Readle server, and Whisper's word timestamps become the speech onset, duration and pauses.
///  • the phone's own recogniser (Android: Google) when the server or Whisper is not available (offline, no key).
/// Either way the answer is a [SpeechMetrics], analysed by [VoxLexi], so the scorer and the adaptive screening do not change.
class SpeechEngine {
  static final SpeechEngine instance = SpeechEngine._();
  SpeechEngine._();

  final SpeechToText _stt = SpeechToText();
  bool? _available;
  bool _sttOk = false;
  List<String> _locales = [];
  void Function(String status)? _onStatus;
  void Function(String error)? _onError;
  String? lastError;

  bool get available => _available ?? false;

  bool _sttChecked = false;

  Future<bool> init() async {
    if (kIsWeb) return false;
    if (!_sttChecked) {
      _sttChecked = true;
      try {
        _sttOk = await _stt.initialize(
          onStatus: (s) => _onStatus?.call(s),
          onError: (e) {
            lastError = e.errorMsg;
            _onError?.call(e.errorMsg);
          },
        );
        if (_sttOk) _locales = (await _stt.locales()).map((l) => l.localeId).toList();
      } catch (e) {
        debugPrint('speech init failed: $e');
        _sttOk = false;
      }
    }
    // the screening can listen when either engine can: the phone's recogniser or the microphone + Whisper
    return _available = _sttOk || await _whisperReady();
  }

  /// Picks the closest supported locale (e.g. en_IN → en_US if Indian English is missing).
  String resolve(String wanted) {
    if (_locales.isEmpty || _locales.contains(wanted)) return wanted;
    final lang = wanted.split('_').first;
    return _locales.firstWhere((l) => l.startsWith(lang), orElse: () => wanted);
  }

  Future<bool> _whisperReady() async => !kIsWeb && await Cloud.instance.whisperAvailable();

  /// Listens to the child. [hint] describes WHAT is being said ("one English word read aloud by a child") so Whisper expects the
  /// right kind of speech; it never contains the answer, so a wrong reading is not "corrected".
  Future<SpeechMetrics> capture({
    required String locale,
    Duration listenFor = const Duration(seconds: 8),
    Duration pauseFor = const Duration(seconds: 2),
    bool dictation = false,
    String hint = '',
    void Function(String partial)? onPartial,
    void Function(double level)? onLevel,
  }) async {
    if (!await init()) return const SpeechMetrics();
    if (await _whisperReady()) {
      final m = await _captureWhisper(locale: locale, listenFor: listenFor, pauseFor: pauseFor, hint: hint, onLevel: onLevel);
      if (m != null) return m;
      if (!_sttOk) return const SpeechMetrics();
      // Whisper failed (no connection): the phone's recogniser takes over for the next questions
    }
    if (!_sttOk) return const SpeechMetrics();
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

  // ---------------- Whisper path ----------------
  Completer<void>? _recStop;

  /// Records the microphone (16 kHz mono WAV), ends on silence after speech (or at the time limit), sends the recording to the
  /// server and maps Whisper's answer. Returns null when the recording could not be made or transcribed.
  Future<SpeechMetrics?> _captureWhisper({required String locale, required Duration listenFor, required Duration pauseFor, required String hint, void Function(double level)? onLevel}) async {
    final rec = AudioRecorder();
    final path = '${Directory.systemTemp.path}/readle_${DateTime.now().microsecondsSinceEpoch}.wav';
    final levels = <(int, double)>[];
    try {
      if (!await rec.hasPermission()) return null;
      await rec.start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), path: path);
      final sw = Stopwatch()..start();
      final stopped = _recStop = Completer<void>();
      double floor = -60;
      var calibrating = <double>[];
      var spoke = false;
      var lastLoud = 0;
      final sub = rec.onAmplitudeChanged(const Duration(milliseconds: 80)).listen((a) {
        final t = sw.elapsedMilliseconds, db = a.current.isFinite ? a.current : -90.0;
        levels.add((t, db + 60));
        onLevel?.call(((db + 50) / 5).clamp(0.0, 10.0));
        if (t < 500) {
          calibrating.add(db); // the room's own noise, measured before the child speaks
          floor = calibrating.reduce((x, y) => x + y) / calibrating.length;
          return;
        }
        if (db > floor + 11 && db > -45) {
          spoke = true;
          lastLoud = t;
        }
        if (spoke && t - lastLoud > pauseFor.inMilliseconds && !stopped.isCompleted) stopped.complete();
        if (t > listenFor.inMilliseconds && !stopped.isCompleted) stopped.complete();
      });
      await stopped.future.timeout(listenFor + const Duration(seconds: 2), onTimeout: () {});
      await sub.cancel();
      _recStop = null;
      await rec.stop();
      if (!spoke) return SpeechMetrics(latencyMs: sw.elapsedMilliseconds); // nothing was said: no upload, nothing for Whisper to invent
      final f = File(path);
      final bytes = await f.readAsBytes();
      final j = await Cloud.instance.transcribe(bytes, lang: locale.split(RegExp('[_-]')).first, prompt: hint);
      if (j == null) return null;
      final m = WhisperMapper.toMetrics(j);
      if (m.transcript.isEmpty) return VoxLexi.analyzeLevels(levels, confidence: 0);
      return m;
    } catch (e) {
      debugPrint('whisper capture failed: $e');
      return null;
    } finally {
      try {
        await rec.dispose();
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    final r = _recStop;
    if (r != null && !r.isCompleted) r.complete(); // ends a Whisper recording right away (the child tapped Done)
    if (_stt.isListening) await _stt.stop();
  }
}
