import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../core/audio.dart';
import '../../core/theme.dart';
import '../../core/tts.dart';
import '../../data/strings.dart';
import '../../models/models.dart';
import '../../story/puppets.dart';
import '../../story/story_book.dart';
import '../../widgets/common.dart';
import '../game_module.dart';

/// Game 11 · Story Quest — "The Living Books of Story Castle".
/// The story becomes a comic book: one panel per sentence, read aloud by Dadi with the words lighting up
/// (any word can be tapped to hear it). Then Kitabu asks the question. A wrong answer turns back to the
/// panel that holds the answer and reads it again; a right answer restores the story (and a castle tower).
class StoryQuestItem extends StatefulWidget {
  final GameCtx ctx;
  final int libraryBooks; // stories already restored (persistent Library)
  const StoryQuestItem({super.key, required this.ctx, this.libraryBooks = 0});
  @override
  State<StoryQuestItem> createState() => _StoryQuestItemState();
}

class _StoryQuestItemState extends State<StoryQuestItem> with SingleTickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  final _narrator = Narrator();
  final _scroll = ScrollController();
  late final List<String> _pages = splitSentences(it.passage ?? it.say);
  late final String _storyId = storyIdOfItem(it.id);
  late final int _qi = int.tryParse(it.id.split(':').last) ?? 0;
  late final AnimationController _restore = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  int _page = 0;
  int _lit = -1;
  int? _glow;
  bool _asked = false;
  bool _reading = false;
  bool _restored = false;
  int _attempts = 0;
  bool _resolved = false;
  int? _correctShown;
  final Set<int> _faded = {};
  final List<String> _tags = [];
  bool _disposed = false;

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  bool get demo => widget.ctx.demo;
  String get tts => widget.ctx.pack.tts;

  /// Read-aloud support fades at the highest steps (the child reads; the button still helps).
  bool get _autoRead => !demo && (it.level <= 7 || widget.ctx.scaffold);

  @override
  void initState() {
    super.initState();
    if (widget.ctx.scaffold && it.options.length > 2) {
      _faded.add([for (var i = 0; i < it.options.length; i++) if (i != it.correct) i].first);
      widget.ctx.feedback(Str.t(lang, 'hint'), true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (demo) {
        _runDemo();
      } else if (_autoRead) {
        _readFrom(0);
      } else if (_pages.length == 1) {
        _ask();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _narrator.stop();
    AudioManager.instance.stopVoice();
    _restore.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------------- reading ----------------
  Future<void> _readFrom(int start, {bool thenAsk = true}) async {
    setState(() => _reading = true);
    for (var p = start; p < _pages.length; p++) {
      if (_disposed || !_reading) return;
      if (p != _page) _turnTo(p);
      await _narrator.read(bookLineId(_storyId, p), _pages[p], (w) {
        if (!_disposed && _lit != w) setState(() => _lit = w);
      }, ttsLocale: tts);
      if (_disposed || !_reading) return;
      await Future.delayed(const Duration(milliseconds: 350));
    }
    if (_disposed) return;
    setState(() => _reading = false);
    if (thenAsk) _ask();
  }

  Future<void> _readPage() async {
    _narrator.stop();
    setState(() => _reading = true);
    await _narrator.read(bookLineId(_storyId, _page), _pages[_page], (w) {
      if (!_disposed && _lit != w) setState(() => _lit = w);
    }, ttsLocale: tts);
    if (!_disposed) setState(() => _reading = false);
  }

  void _stopReading() {
    _narrator.stop();
    AudioManager.instance.stopVoice();
    _reading = false;
    _lit = -1;
  }

  void _turnTo(int p) {
    if (p < 0 || p >= _pages.length) return;
    AudioManager.instance.sfx('page_turn', volume: .5);
    setState(() {
      _page = p;
      _lit = -1;
    });
    if (p == _pages.length - 1 && !_asked && !_reading) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!_disposed && !_reading) _ask();
      });
    }
  }

  void _flip(int dir) {
    if (demo || _resolved) return;
    setState(_stopReading);
    _turnTo(_page + dir);
  }

  Future<void> _ask() async {
    if (_asked || _disposed) return;
    setState(() => _asked = true);
    _showQuestion();
    if (demo) return;
    await Future.delayed(const Duration(milliseconds: 250));
    if (_disposed) return;
    await AudioManager.instance.voice(questionLineId(_storyId, _qi), it.stimulus ?? '', character: 'kitabu', ttsLocale: tts);
  }

  /// Bring the question and answers into view on small phones.
  void _showQuestion() {
    // wait for the picture to shrink (AnimatedContainer) so the full answer list fits the scroll range
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!_disposed && _scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _runDemo() async {
    for (var p = 1; p < _pages.length; p++) {
      await Future.delayed(const Duration(milliseconds: 1100));
      if (_disposed) return;
      _turnTo(p);
    }
    await Future.delayed(const Duration(milliseconds: 900));
    if (_disposed) return;
    setState(() => _asked = true);
    _showQuestion();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (_disposed) return;
    setState(() => _correctShown = it.correct);
  }

  // ---------------- answering ----------------
  void _choose(int i) {
    if (_resolved || demo || _faded.contains(i)) return;
    setState(_stopReading);
    final o = it.options[i];
    if (i == it.correct) {
      final first = _attempts == 0;
      setState(() {
        _resolved = true;
        _correctShown = i;
        _glow = null;
      });
      widget.ctx.feedback(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
      _celebrate(first);
      return;
    }
    _attempts++;
    if (o.tag != null) _tags.add(o.tag!);
    final canRetry = _attempts < 2 && (it.options.length - _faded.length - 1) > 1;
    setState(() {
      _faded.add(i);
      if (!canRetry) {
        _resolved = true;
        _correctShown = it.correct;
      }
    });
    if (canRetry) {
      widget.ctx.feedback('Let’s look back in the story…', false);
      _lookBack();
    } else {
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      Speaker.instance.speak(it.options[it.correct].label, tts);
      _finish(false, 2600);
    }
  }

  /// Error-aware help: turn to the panel that holds the answer, make it glow and read it again.
  Future<void> _lookBack() async {
    final p = _answerPage();
    await Future.delayed(const Duration(milliseconds: 500));
    if (_disposed) return;
    _turnTo(p);
    setState(() => _glow = p);
    await _readPage();
    if (!_disposed) setState(() => _glow = null);
  }

  int _answerPage() {
    final key = it.options[it.correct].label.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 2 && !_stop.contains(w)).toSet();
    var best = 0, bestScore = -1;
    for (var p = 0; p < _pages.length; p++) {
      final words = _pages[p].toLowerCase().split(RegExp(r'\W+')).toSet();
      final score = key.where(words.contains).length;
      if (score > bestScore) {
        best = p;
        bestScore = score;
      }
    }
    return bestScore <= 0 ? 0 : best;
  }

  static const _stop = {'the', 'and', 'his', 'her', 'was', 'she', 'him', 'they', 'with', 'for', 'had'};

  Future<void> _celebrate(bool first) async {
    setState(() => _restored = true);
    AudioManager.instance.sfx('magic', volume: .6);
    _restore.forward();
    _finish(first, 2000);
  }

  void _finish(bool firstTry, int delayMs) {
    final r = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: firstTry, ms: _clock.elapsedMilliseconds, tags: [..._tags]);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_disposed && !demo) widget.ctx.done(r);
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(children: [
          _book(),
          if (_asked) ...[const SizedBox(height: 10), _question()],
        ]),
      ),
      if (_restored) Positioned.fill(child: IgnorePointer(child: _restoreOverlay())),
    ]);
  }

  Widget _book() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD9B98A), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          reverseDuration: const Duration(milliseconds: 120), // the old page leaves quickly, so texts never overlap
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(.12, 0), end: Offset.zero).animate(a), child: c)),
          child: BookPanel(
            key: ValueKey(_page),
            storyId: _storyId,
            emoji: it.emoji ?? '📖',
            sentence: _pages[_page],
            index: _page,
            litWord: _lit,
            glow: _glow == _page,
            pictureHeight: _asked ? 115 : 190,
            ttsLocale: tts,
            storyText: it.passage,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          _navButton(Icons.chevron_left_rounded, _page > 0, () => _flip(-1)),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var p = 0; p < _pages.length; p++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: p == _page ? 20 : 9,
                  height: 9,
                  decoration: BoxDecoration(color: p == _page ? const Color(0xFFE0568A) : const Color(0xFFE3CFAF), borderRadius: BorderRadius.circular(5)),
                ),
            ]),
          ),
          RoundIconButton(
            icon: _reading ? Icons.stop_rounded : Icons.volume_up_rounded,
            label: _reading ? 'Stop reading' : 'Read to me',
            color: C.gold,
            size: 44,
            onTap: () {
              if (demo) return;
              if (_reading) {
                setState(_stopReading);
              } else {
                _readFrom(_page, thenAsk: !_asked);
              }
            },
          ),
          const SizedBox(width: 6),
          _navButton(Icons.chevron_right_rounded, _page < _pages.length - 1, () => _flip(1)),
        ]),
        if (!demo)
          Align(alignment: Alignment.centerRight, child: Text(() {
            final n = widget.libraryBooks + (_restored && isAuthoredStory(_storyId) ? 1 : 0);
            return '📚 $n ${n == 1 ? 'book' : 'books'} restored';
          }(), style: ts(12, color: C.inkSoft, w: FontWeight.w600))),
      ]),
    );
  }

  Widget _navButton(IconData icon, bool on, VoidCallback tap) => Opacity(
        opacity: on ? 1 : .3,
        child: RoundIconButton(icon: icon, label: icon == Icons.chevron_left_rounded ? 'Previous page' : 'Next page', size: 44, onTap: on ? tap : () {}),
      );

  Widget _question() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .95), borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 58, height: 58, child: Puppet(id: 'kitabu', size: 58)),
          const SizedBox(width: 8),
          Expanded(child: Text(it.stimulus ?? '', style: ts(21, color: C.ink))),
          RoundIconButton(icon: Icons.replay_rounded, label: 'Hear the question', size: 40, onTap: () => AudioManager.instance.voice(questionLineId(_storyId, _qi), it.stimulus ?? '', character: 'kitabu', ttsLocale: tts)),
        ]),
        const SizedBox(height: 10),
        for (var i = 0; i < it.options.length; i++) _option(i),
      ]),
    );
  }

  Widget _option(int i) {
    final o = it.options[i];
    final faded = _faded.contains(i);
    final right = _correctShown == i;
    final face = _emotionFace(o.label);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: faded ? .35 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: right ? const Color(0xFFCDEFC4) : const Color(0xFFF4F1FF),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _choose(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: right ? const Color(0xFF4CAF50) : const Color(0xFFD7D0F0), width: right ? 3 : 2)),
              child: Row(children: [
                if (o.emoji != null) Padding(padding: const EdgeInsets.only(right: 10), child: Text(o.emoji!, style: const TextStyle(fontSize: 30))),
                if (o.emoji == null && face != null) Padding(padding: const EdgeInsets.only(right: 10), child: face),
                Expanded(child: Text(o.label, style: ts(20, color: C.ink, w: FontWeight.w600))),
                GestureDetector(
                  onTap: () => Speaker.instance.speak(o.say ?? o.label, tts),
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.volume_up_rounded, color: C.inkSoft, size: 24)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  /// Feeling answers ("How did Leo feel?") get an emotion face, painted when available.
  Widget? _emotionFace(String label) {
    const faces = {'happy': '😊', 'sad': '😢', 'excited': '🤩', 'sleepy': '😴', 'angry': '😠', 'scared': '😨', 'surprised': '😮', 'proud': '😌', 'bored': '😐', 'worried': '😟', 'tired': '😴'};
    const art = {'happy': 'happy', 'excited': 'happy', 'sad': 'sad', 'angry': 'angry', 'scared': 'scared', 'worried': 'scared', 'surprised': 'surprised', 'proud': 'proud'};
    final k = label.toLowerCase().trim();
    final e = faces[k];
    if (e == null) return null;
    final emo = Text(e, style: const TextStyle(fontSize: 30));
    final a = art[k];
    return a == null ? emo : SizedBox(width: 36, height: 36, child: ArtImage('prop.emotion.$a', fallback: emo));
  }

  Widget _restoreOverlay() => AnimatedBuilder(
        animation: _restore,
        builder: (_, _) {
          final t = Curves.elasticOut.transform(_restore.value);
          return Center(
            child: Transform.scale(
              scale: t,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .7), blurRadius: 30)]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(height: 90, width: 90, child: ArtImage('prop.castle.tower_restored', fallback: const Center(child: Text('🏰', style: TextStyle(fontSize: 64))))),
                  Text(demo ? 'Story restored!' : 'Story restored! ✨', style: ts(22, color: const Color(0xFFB0306A))),
                ]),
              ),
            ),
          );
        },
      );
}
