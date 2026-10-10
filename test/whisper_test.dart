import 'package:flutter_test/flutter_test.dart';
import 'package:wordoo/screening/models.dart';
import 'package:wordoo/screening/voxlexi.dart';
import 'package:wordoo/screening/whisper_mapper.dart';

void main() {
  group('Whisper → SpeechMetrics (same fields the scorer already uses)', () {
    test('one word: onset, duration, confidence and a match against the target', () {
      final m = WhisperMapper.toMetrics({
        'text': 'Cat.',
        'confidence': .82,
        'words': [
          {'word': 'Cat', 'start': 0.9, 'end': 1.3},
        ],
      });
      expect(m.transcript, 'Cat.');
      expect(m.latencyMs, 900);
      expect(m.durationMs, 400);
      expect(m.pauses, 0);
      expect(m.confidence, closeTo(.82, 1e-9));
      expect(VoxLexi.bestMatch('cat', m), 1);
      expect(VoxLexi.scoreFromMatch(VoxLexi.bestMatch('cat', m)), 1);
    });

    test('a child’s near-miss still earns partial credit through the existing fuzzy matching', () {
      final m = WhisperMapper.toMetrics({'text': 'kat', 'confidence': .6, 'words': [{'word': 'kat', 'start': .5, 'end': .9}]});
      expect(VoxLexi.scoreFromMatch(VoxLexi.bestMatch('cat', m, phonetic: true)), 1);
      final wrong = WhisperMapper.toMetrics({'text': 'dog', 'confidence': .9, 'words': [{'word': 'dog', 'start': .5, 'end': .9}]});
      expect(VoxLexi.scoreFromMatch(VoxLexi.bestMatch('cat', wrong, phonetic: true)), 0);
    });

    test('pauses are the silences between words (≥ 300 ms)', () {
      final m = WhisperMapper.toMetrics({
        'text': 'the cat sat',
        'confidence': .7,
        'words': [
          {'word': 'the', 'start': 1.0, 'end': 1.2},
          {'word': 'cat', 'start': 1.25, 'end': 1.6}, // 50 ms gap: not a pause
          {'word': 'sat', 'start': 2.8, 'end': 3.1}, // 1.2 s gap: a pause
        ],
      });
      expect(m.latencyMs, 1000);
      expect(m.durationMs, 2100);
      expect(m.pauses, 1);
      expect(m.pauseMs, 1200);
    });

    test('words inside a phrase are alternates, so "it is a cat" still contains cat', () {
      final m = WhisperMapper.toMetrics({
        'text': 'It is a cat.',
        'confidence': .8,
        'words': [
          {'word': 'It', 'start': .5, 'end': .6},
          {'word': 'is', 'start': .65, 'end': .8},
          {'word': 'a', 'start': .85, 'end': .9},
          {'word': 'cat.', 'start': .95, 'end': 1.3},
        ],
      });
      expect(m.alternates, containsAll(['cat', 'It']));
      expect(VoxLexi.bestMatch('cat', m), 1);
    });

    test('silence or a phantom phrase (empty text) is "nothing heard"', () {
      final m = WhisperMapper.toMetrics({'text': '', 'confidence': 0, 'words': []});
      expect(m.transcript, '');
      expect(m.latencyMs, 0);
    });

    test('analyzeWords with no words keeps the transcript and confidence', () {
      final m = VoxLexi.analyzeWords(const [], transcript: 'x', confidence: .4);
      expect(m.transcript, 'x');
      expect(m.confidence, .4);
    });

    test('the adaptive screening reads the same fields: a long wait before speaking is a long pause', () {
      final m = WhisperMapper.toMetrics({'text': 'cat', 'confidence': .9, 'words': [{'word': 'cat', 'start': 5.2, 'end': 5.6}]});
      expect(m.latencyMs > 3500, true);
      expect(SpeechMetrics(latencyMs: m.latencyMs).latencyMs, 5200);
    });
  });
}
