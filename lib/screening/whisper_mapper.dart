import 'models.dart';
import 'voxlexi.dart';

/// Turns the Wordoo server's /transcribe answer (OpenAI Whisper) into the [SpeechMetrics] the screening already understands.
class WhisperMapper {
  static SpeechMetrics toMetrics(Map<String, dynamic> j) {
    final text = (j['text'] as String? ?? '').trim();
    final words = <({String word, int startMs, int endMs})>[
      for (final w in (j['words'] as List? ?? const []))
        (word: (w as Map)['word'] as String, startMs: (((w['start'] as num?) ?? 0) * 1000).round(), endMs: (((w['end'] as num?) ?? 0) * 1000).round()),
    ];
    if (text.isEmpty) return const SpeechMetrics();
    // Whisper gives one best reading; the individual words are offered as alternates so a single right word inside a longer
    // phrase ("it is a cat") still matches.
    final alternates = [for (final w in words) w.word.replaceAll(RegExp(r'[^\p{L}\p{N}’\x27-]', unicode: true), '')].where((w) => w.isNotEmpty).toList();
    return VoxLexi.analyzeWords(words, transcript: text, confidence: ((j['confidence'] as num?) ?? 0).toDouble(), alternates: alternates);
  }
}
