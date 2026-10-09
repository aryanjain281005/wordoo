import 'dart:async';
import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/audio.dart';
import '../core/theme.dart';
import '../core/tts.dart';
export 'book_text.dart';

/// Shared pieces of the "living books" used by Story Quest and the Library:
/// sentence splitting (must match tool/export_books.dart), narration ids, and the comic panel.

/// Book-world background for a sentence, picked from its words (bg.book.* in ART_PROMPTS.md).
/// A sentence's own PLACE word wins; otherwise the story's setting; only then hints like animals or objects.
String bookSceneFor(String text, {String? story}) =>
    _sceneOf(text, places: true) ?? (story == null ? null : _sceneOf(story, places: true)) ?? _sceneOf(text) ?? (story == null ? null : _sceneOf(story)) ?? 'park';

const _placeWords = {'market', 'shop', 'beach', 'sea', 'island', 'farm', 'field', 'village', 'hill', 'library', 'festival', 'garden', 'home', 'house', 'room', 'park', 'school', 'zoo', 'sky', 'night'};

String? _sceneOf(String text, {bool places = false}) {
  final t = text.toLowerCase();
  const map = [
    (['market', 'shop', 'mango'], 'market'),
    (['beach', 'sea', 'bottle', 'island', 'shell'], 'beach'),
    (['farmer', 'field', 'cow', 'village', 'farm'], 'village'),
    (['hill', 'sunrise', 'sun came up'], 'hill'),
    (['library', 'librarian', 'book'], 'library'),
    (['lantern', 'festival'], 'street'),
    (['night', 'sky', 'cloud', 'star', 'moon'], 'night'),
    (['pot', 'seed', 'plant', 'garden', 'water'], 'garden'),
    (['home', 'house', 'room', 'box', 'sister', 'pencil'], 'home'),
    (['park', 'bench', 'tree', 'kite', 'wind', 'duck', 'zoo', 'school'], 'park'),
  ];
  for (final (words, scene) in map) {
    if (words.where((w) => !places || _placeWords.contains(w)).any(t.contains)) return scene;
  }
  return null;
}

/// Story characters that have painted art, found by name in a sentence.
List<String> bookCastFor(String text) {
  final t = text.toLowerCase();
  return [
    if (t.contains('milo') || t.contains('fox')) 'char.milo.happy',
    if (t.contains('gumsum') || t.contains('cloud')) 'char.gumsum.${t.contains('sad') || t.contains('no one') ? 'sad' : 'happy'}',
    if (t.contains('bolt') || t.contains('robot')) 'char.bolt.happy',
    if (t.contains('arya')) 'char.arya.happy',
  ];
}

/// One comic panel: picture (story cover / book-world background + characters / emoji) and the sentence,
/// with the word being read lit up and every word tappable to hear it alone.
class BookPanel extends StatelessWidget {
  final String storyId;
  final String emoji;
  final String sentence;
  final int index;
  final int litWord; // −1 = none
  final double pictureHeight;
  final String ttsLocale;
  final bool glow; // flashes when the answer is in this panel
  final String? storyText; // whole story: panels with no place word keep the story's setting
  const BookPanel({super.key, required this.storyId, required this.emoji, required this.sentence, required this.index, this.litWord = -1, this.pictureHeight = 190, this.ttsLocale = 'en-IN', this.glow = false, this.storyText});

  @override
  Widget build(BuildContext context) {
    final words = sentence.split(RegExp(r'\s+'));
    final scene = bookSceneFor(sentence, story: storyText);
    final cast = bookCastFor(sentence);
    final cover = index == 0 ? ReadleAssets.instance.art('story.$storyId') : null;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: pictureHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: glow ? C.gold : const Color(0xFF3A2D5C), width: glow ? 5 : 3),
          boxShadow: glow ? [BoxShadow(color: C.gold.withValues(alpha: .7), blurRadius: 18)] : const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: cover != null
              ? Image.asset(cover, fit: BoxFit.cover, width: double.infinity)
              : Stack(fit: StackFit.expand, children: [
                  ArtImage('bg.book.$scene', fit: BoxFit.cover, fallback: _sceneFallback(scene)),
                  Align(
                    alignment: const Alignment(0, .85),
                    child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      for (final c in cast) SizedBox(height: pictureHeight * .62, width: pictureHeight * .55, child: ArtImage(c, fallback: const SizedBox.shrink())),
                      if (cast.isEmpty) Text(emoji, style: TextStyle(fontSize: pictureHeight * .38)),
                    ]),
                  ),
                ]),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 4, children: [
        for (var i = 0; i < words.length; i++)
          GestureDetector(
            onTap: () {
              AudioManager.instance.stopVoice();
              Speaker.instance.speak(words[i].replaceAll(RegExp(r'[^\w’\x27-]'), ''), ttsLocale);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: i == litWord ? const Color(0xFFFFE07A) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Text(words[i], style: ts(23, color: C.ink, w: i == litWord ? FontWeight.w700 : FontWeight.w500)),
            ),
          ),
      ]),
    ]);
  }

  Widget _sceneFallback(String scene) {
    final colors = switch (scene) {
      'beach' => const [Color(0xFF8FD8F5), Color(0xFFF7E3A8)],
      'night' || 'street' => const [Color(0xFF2B2D6B), Color(0xFF6A4C9C)],
      'hill' => const [Color(0xFFFFB38A), Color(0xFF9BD67A)],
      'market' || 'village' => const [Color(0xFFFFD08A), Color(0xFFE59A5B)],
      'library' || 'home' => const [Color(0xFFF7E1C4), Color(0xFFD9A77A)],
      _ => const [Color(0xFFBEE7FF), Color(0xFF9BD67A)],
    };
    return DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors)));
  }
}

/// Reads one sentence aloud (Dadi's recorded voice when it exists, otherwise device TTS) and reports
/// which word is being spoken, for karaoke highlighting. Timing follows the length of each word.
class Narrator {
  Timer? _t;
  bool _stopped = false;

  Future<void> read(String lineId, String sentence, void Function(int word) onWord, {String ttsLocale = 'en-IN'}) async {
    stop();
    _stopped = false;
    final a = AudioManager.instance;
    final words = sentence.split(RegExp(r'\s+'));
    final total = a.voiceLength(lineId)?.inMilliseconds ?? (400 + sentence.length * 62);
    final weights = [for (final w in words) w.length + 2];
    final sum = weights.fold<int>(0, (x, y) => x + y);
    final sw = Stopwatch()..start();
    _t = Timer.periodic(const Duration(milliseconds: 40), (_) {
      final t = sw.elapsedMilliseconds / total * sum;
      var acc = 0, i = 0;
      while (i < weights.length - 1 && acc + weights[i] < t) {
        acc += weights[i];
        i++;
      }
      onWord(sw.elapsedMilliseconds >= total ? -1 : i);
    });
    await a.voice(lineId, sentence, character: 'dadi', ttsLocale: ttsLocale);
    _t?.cancel();
    if (!_stopped) onWord(-1);
  }

  void stop() {
    _stopped = true;
    _t?.cancel();
  }
}
