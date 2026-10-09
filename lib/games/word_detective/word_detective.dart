import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../core/audio.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/strings.dart';
import '../../models/models.dart';
import '../../story/story_lines.dart';
import '../../widgets/common.dart';
import '../game_module.dart';

/// One mini mystery: 3 clues point to one of 3 suspects.
class DetectiveCase {
  final String title;
  final String culprit; // suspect id
  final List<(String emoji, String text)> clues;
  final List<(String id, String emoji, String name)> suspects;
  const DetectiveCase(this.title, this.culprit, this.clues, this.suspects);
}

const detectiveCases = [
  DetectiveCase('Who took the mangoes?', 'goat', [('🐾', 'Hoof prints'), ('📄', 'Chewed paper'), ('🤍', 'White fur')], [('goat', '🐐', 'Goat'), ('monkey', '🐒', 'Monkey'), ('cow', '🐄', 'Cow')]),
  DetectiveCase('Who ate the laddoos?', 'mouse', [('🧀', 'Tiny crumbs'), ('👣', 'Little footprints'), ('〰️', 'A thin tail mark')], [('cat', '🐱', 'Cat'), ('mouse', '🐭', 'Mouse'), ('parrot', '🦜', 'Parrot')]),
  DetectiveCase('Who rang the temple bell?', 'monkey', [('🍌', 'Banana peel'), ('🌿', 'Swinging vine'), ('🤎', 'Brown hair')], [('owl', '🦉', 'Owl'), ('cow', '🐄', 'Cow'), ('monkey', '🐒', 'Monkey')]),
  DetectiveCase('Who hid the kite?', 'parrot', [('💚', 'Green feather'), ('🌶️', 'Chilli seeds'), ('📢', 'A loud squawk')], [('parrot', '🦜', 'Parrot'), ('goat', '🐐', 'Goat'), ('dog', '🐶', 'Dog')]),
  DetectiveCase('Who splashed mud on the wall?', 'pig', [('🟤', 'Mud spots'), ('🐾', 'Small hoof prints'), ('🎵', 'Happy snorts')], [('dog', '🐶', 'Dog'), ('pig', '🐷', 'Piglet'), ('cat', '🐱', 'Cat')]),
  DetectiveCase('Who borrowed the library book?', 'dog', [('🦴', 'A bone bookmark'), ('🐾', 'Paw prints'), ('💤', 'Snoring sounds')], [('goat', '🐐', 'Goat'), ('cat', '🐱', 'Cat'), ('dog', '🐶', 'Puppy')]),
];

/// The case being solved during one quest (a quest of 6 words = 2 cases). Restarts with every quest.
class CaseBoard {
  static int caseIndex = Random().nextInt(detectiveCases.length);
  static int clues = 0;
  static bool introduced = false;
  static void reset() {
    caseIndex = (caseIndex + 1) % detectiveCases.length;
    clues = 0;
    introduced = false;
  }

  static DetectiveCase get current => detectiveCases[caseIndex];
}

/// Detective rank from all clues ever found (3 clues = 1 case).
String detectiveRank(int clues) {
  final cases = clues ~/ 3;
  if (cases >= 10) return 'Chief Inspector';
  if (cases >= 6) return 'Senior Detective';
  if (cases >= 3) return 'Junior Detective';
  return 'Rookie Detective';
}

/// Game 7 · Word Detective — "The Case of the Switched Signs".
/// Gumsum's fog covers the village signs. The voice says a word; the child moves the magnifier to read the
/// signs and taps the one that is spelled right. Each right word is a clue; 3 clues → name the culprit.
class WordDetectiveItem extends StatefulWidget {
  final GameCtx ctx;
  final int cluesEver; // persistent, for the detective rank
  const WordDetectiveItem({super.key, required this.ctx, this.cluesEver = 0});
  @override
  State<WordDetectiveItem> createState() => _WordDetectiveItemState();
}

enum _Phase { search, accuse, solved }

class _WordDetectiveItemState extends State<WordDetectiveItem> with SingleTickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  final Set<int> _revealed = {};
  final Set<int> _faded = {};
  final Map<int, int> _shake = {};
  final List<String> _tags = [];
  Offset? _lens; // magnifier centre in the street panel
  List<Rect> _signRects = const [];
  int _attempts = 0;
  bool _resolved = false;
  int? _correctShown;
  _Phase _phase = _Phase.search;
  ItemResult? _result;
  int? _wrongSuspect;
  bool _disposed = false;
  bool _newClue = false;
  DetectiveCase? _solvedCase; // kept while the reveal plays (the board already moves on to the next case)

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  bool get demo => widget.ctx.demo;
  DetectiveCase get kase => _solvedCase ?? CaseBoard.current;
  int get n => it.options.length;

  /// Levels 1–2 show the signs plainly; Gumsum's fog (and the magnifier) only arrives at levels 3–4.
  bool get _foggy => it.level >= 6;

  @override
  void initState() {
    super.initState();
    if (demo) CaseBoard.reset();
    if (!_foggy) _revealed.addAll(List.generate(n, (i) => i));
    if (widget.ctx.scaffold && n > 2) {
      _faded.add([for (var i = 0; i < n; i++) if (i != it.correct) i].first);
      widget.ctx.feedback(Str.t(lang, 'hint'), true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => demo ? _runDemo() : _open());
  }

  @override
  void dispose() {
    _disposed = true;
    _anim.dispose();
    super.dispose();
  }

  void _say(String t) => AudioManager.instance.say(t, ttsLocale: widget.ctx.pack.tts);

  Future<void> _line(String id) async {
    final l = StoryLines.instance[id];
    if (l != null && !_disposed) await AudioManager.instance.voice(id, l.text, character: l.who);
  }

  Future<void> _open() async {
    if (!CaseBoard.introduced) {
      CaseBoard.introduced = true;
      await _line('det_intro_${CaseBoard.caseIndex}');
      if (_disposed) return;
      if (CaseBoard.caseIndex.isEven) await _line('det_scared');
    }
    if (_disposed) return;
    _say(it.say);
    if (widget.ctx.scaffold) {
      // the magnifier starts glowing next to the right sign; the word is said twice
      if (_signRects.isNotEmpty) setState(() => _moveLens(_signRects[it.correct].center + const Offset(0, 30)));
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!_disposed) _say(it.say);
      });
    }
  }

  Future<void> _runDemo() async {
    await Future.delayed(const Duration(milliseconds: 900));
    for (var i = 0; i < n; i++) {
      if (_disposed || _signRects.length != n) return;
      setState(() => _moveLens(_signRects[i].center + const Offset(0, 70)));
      await Future.delayed(const Duration(milliseconds: 700));
    }
    if (_disposed) return;
    setState(() {
      _moveLens(_signRects[it.correct].center + const Offset(0, 70));
      _correctShown = it.correct;
      _newClue = true;
    });
  }

  // ---------------- magnifier ----------------
  void _moveLens(Offset p) {
    _lens = p;
    for (var i = 0; i < _signRects.length; i++) {
      if ((_signRects[i].center - p).distance < _signRects[i].width * .5 + 50) _revealed.add(i);
    }
  }

  void _tapSign(int i) {
    if (_resolved || demo || _faded.contains(i) || _phase != _Phase.search) return;
    if (!_revealed.contains(i)) {
      // first tap on a foggy sign moves the magnifier there
      AudioManager.instance.sfx('whoosh', volume: .4);
      setState(() => _moveLens(_signRects[i].center + const Offset(0, 70))); // just below, so the word stays readable
      return;
    }
    _choose(i);
  }

  void _choose(int i) {
    final o = it.options[i];
    if (i == it.correct) {
      final first = _attempts == 0;
      final ms = _clock.elapsedMilliseconds;
      final tags = [..._tags];
      if (it.timed && first && ms > Cfg.slowResponseMs) tags.add('Slow response');
      _result = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: first, ms: ms, tags: tags);
      setState(() {
        _resolved = true;
        _correctShown = i;
        _newClue = true;
      });
      _say(it.say);
      widget.ctx.feedback(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
      CaseBoard.clues = min(3, CaseBoard.clues + 1);
      AudioManager.instance.sfx('bell', volume: .6);
      if (CaseBoard.clues >= 3) {
        Future.delayed(const Duration(milliseconds: 1300), () async {
          if (_disposed) return;
          setState(() => _phase = _Phase.accuse);
          await _line('det_accuse');
        });
      } else {
        Future.delayed(const Duration(milliseconds: 600), () => _line('det_clue'));
        _finish(1900);
      }
      return;
    }
    _attempts++;
    if (o.tag != null) _tags.add(o.tag!);
    final canRetry = _attempts < 2 && (n - _faded.length - 1) > 1;
    setState(() {
      _shake[i] = (_shake[i] ?? 0) + 1;
      _faded.add(i);
      if (!canRetry) {
        _resolved = true;
        _correctShown = it.correct;
        _revealed.add(it.correct);
      }
    });
    AudioManager.instance.sfx('miss_soft');
    if (canRetry) {
      widget.ctx.feedback('Hmm… that sign says “${o.label}”. Listen again!', false);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!_disposed) _say(it.say);
      });
    } else {
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      _say(it.say);
      _result = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: false, ms: _clock.elapsedMilliseconds, tags: [..._tags]);
      _finish(2400); // no clue this time — the case waits for the next word
    }
  }

  // ---------------- accusing ----------------
  Future<void> _accuse(String id) async {
    if (_phase != _Phase.accuse || demo) return;
    if (id != kase.culprit) {
      AudioManager.instance.sfx('miss_soft');
      setState(() => _wrongSuspect = kase.suspects.indexWhere((s) => s.$1 == id));
      await _line('det_think');
      return;
    }
    AudioManager.instance.sfx('reward_fanfare', volume: .6);
    final idx = CaseBoard.caseIndex;
    setState(() {
      _solvedCase = CaseBoard.current;
      _phase = _Phase.solved;
    });
    CaseBoard.reset();
    CaseBoard.introduced = false;
    await _line('det_reveal_$idx');
    _finish(600);
  }

  void _finish(int delayMs) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_disposed && !demo && _result != null) widget.ctx.done(_result!);
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(children: [
        _caseHeader(),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: switch (_phase) {
            _Phase.search => KeyedSubtree(key: const ValueKey('search'), child: _street()),
            _Phase.accuse => KeyedSubtree(key: const ValueKey('accuse'), child: _suspects()),
            _Phase.solved => KeyedSubtree(key: const ValueKey('solved'), child: _solved()),
          },
        ),
      ]),
    );
  }

  Widget _caseHeader() {
    final rank = detectiveRank(widget.cluesEver);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        SizedBox(width: 64, height: 64, child: ArtImage('char.ullu.happy', fallback: const Center(child: Text('🦉', style: TextStyle(fontSize: 44))))),
        const SizedBox(width: 6),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🗂️ ${kase.title}', style: ts(17, color: C.ink)),
            const SizedBox(height: 4),
            Row(children: [
              for (var c = 0; c < 3; c++) _clueSlot(c),
            ]),
            if (!demo) Text(rank, style: ts(12, color: C.inkSoft, w: FontWeight.w600)),
          ]),
        ),
        RoundIconButton(icon: Icons.volume_up_rounded, label: 'Hear the word', color: C.gold, size: 44, onTap: demo ? () {} : () => _say(it.say)),
      ]),
    );
  }

  Widget _clueSlot(int c) {
    final got = c < CaseBoard.clues || (demo && _newClue && c == CaseBoard.clues);
    final fresh = _newClue && c == CaseBoard.clues - 1;
    final clue = kase.clues[c];
    return TweenAnimationBuilder<double>(
      key: ValueKey('clue$c$got'),
      tween: Tween(begin: fresh ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: .4 + .6 * v, child: child),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: got ? const Color(0xFFFFF1C2) : const Color(0xFFEDEAF5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: got ? const Color(0xFFE0A100) : const Color(0xFFD7D0F0), width: 2),
        ),
        child: Text(got ? clue.$1 : '?', style: ts(16, color: C.inkSoft)),
      ),
    );
  }

  Widget _street() {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      const h = 330.0;
      // three houses in a row, a hanging sign on each
      final signW = min(130.0, (w - 24) / n - 8);
      final rects = [for (var i = 0; i < n; i++) Rect.fromLTWH(12 + i * ((w - 24) / n) + ((w - 24) / n - signW) / 2, 150, signW, 62)];
      if (_signRects.length != rects.length || _signRects.first != rects.first) {
        _signRects = rects;
        _lens ??= Offset(w / 2, h - 50);
      }
      return GestureDetector(
        onPanUpdate: demo || _resolved ? null : (d) => setState(() => _moveLens(Offset(d.localPosition.dx.clamp(0, w), d.localPosition.dy.clamp(0, h)))),
        child: Container(
          height: h,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 3)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(children: [
              Positioned.fill(child: ArtImage('bg.detective.street', fit: BoxFit.cover, fallback: CustomPaint(painter: _StreetPainter(n)))),
              for (var i = 0; i < n; i++) _sign(i, rects[i]),
              if (_foggy && _lens != null && !_resolved) _magnifier(),
              if (!_resolved && !demo)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        _foggy && _revealed.length < n ? '🔍 Tap a foggy sign (or drag the magnifier) to read it, then tap the word you heard' : '👆 Tap the sign with the word you heard',
                        textAlign: TextAlign.center,
                        style: ts(14, color: C.ink, w: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _sign(int i, Rect r) {
    final o = it.options[i];
    final clear = _revealed.contains(i) || _resolved;
    final right = _correctShown == i;
    final faded = _faded.contains(i);
    return Positioned(
      left: r.left,
      top: r.top - 26,
      width: r.width,
      child: Opacity(
        opacity: faded ? .35 : 1,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('s$i${_shake[i] ?? 0}'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          builder: (_, t, child) => Transform.rotate(angle: (_shake[i] ?? 0) == 0 ? 0 : sin(t * pi * 5) * .08 * (1 - t), child: child),
          child: GestureDetector(
            onTap: () => _tapSign(i),
            child: Column(children: [
              // two ropes
              SizedBox(height: 26, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (var k = 0; k < 2; k++) Container(width: 3, color: const Color(0xFF5E3A17))])),
              Container(
                height: r.height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: right ? const Color(0xFFCDEFC4) : const Color(0xFFF6D9A6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: right ? const Color(0xFF4CAF50) : const Color(0xFF8B5A2B), width: right ? 4 : 3),
                  boxShadow: [BoxShadow(color: right ? const Color(0xFF4CAF50).withValues(alpha: .6) : const Color(0x55000000), blurRadius: right ? 14 : 5, offset: const Offset(0, 3))],
                ),
                child: Stack(alignment: Alignment.center, children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: clear ? 0 : 7, sigmaY: clear ? 0 : 7),
                    child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(o.label, style: ts(26, color: C.ink)))),
                  ),
                  if (!clear) const Text('🌫️', style: TextStyle(fontSize: 26)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _magnifier() {
    final p = _lens!;
    final glow = widget.ctx.scaffold || demo;
    return Positioned(
      left: p.dx - 38,
      top: p.dy - 38,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, _) => Transform.rotate(
            angle: -.5,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .12),
                  border: Border.all(color: const Color(0xFFB98A2E), width: 7),
                  boxShadow: [BoxShadow(color: (glow ? C.gold : Colors.black).withValues(alpha: glow ? .5 + .3 * sin(_anim.value * 2 * pi) : .3), blurRadius: glow ? 18 : 6)],
                ),
              ),
              Container(width: 12, height: 40, decoration: BoxDecoration(color: const Color(0xFF6B3E1E), borderRadius: BorderRadius.circular(6))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _suspects() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .95), borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Text('Who did it?', style: ts(24, color: C.ink)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
          for (final c in kase.clues)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFFF1C2), borderRadius: BorderRadius.circular(14)),
              child: Text('${c.$1}  ${c.$2}', style: ts(15, color: C.ink, w: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < kase.suspects.length; i++)
            Expanded(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('sus$i${_wrongSuspect == i}'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (_, t, child) => Transform.translate(offset: Offset(_wrongSuspect == i ? sin(t * pi * 5) * 7 * (1 - t) : 0, 0), child: child),
                child: GestureDetector(
                  onTap: () => _accuse(kase.suspects[i].$1),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFF4F1FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD7D0F0), width: 2)),
                    child: Column(children: [
                      SizedBox(height: 70, child: ArtImage('char.suspect.${kase.suspects[i].$1}', fallback: Center(child: Text(kase.suspects[i].$2, style: const TextStyle(fontSize: 54))))),
                      Text(kase.suspects[i].$3, style: ts(16, color: C.ink)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _solved() {
    final s = kase.suspects.firstWhere((x) => x.$1 == kase.culprit);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .96), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .6), blurRadius: 24)]),
      child: Column(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: SizedBox(height: 100, child: ArtImage('char.suspect.${s.$1}', fallback: Center(child: Text(s.$2, style: const TextStyle(fontSize: 80))))),
        ),
        const SizedBox(height: 6),
        Text('Case closed! 🗂️', style: ts(26, color: const Color(0xFF6B3FA0))),
        const SizedBox(height: 4),
        Text(StoryLines.instance['det_reveal_${detectiveCases.indexOf(kase)}']?.text ?? 'It was the ${s.$3}!', textAlign: TextAlign.center, style: ts(18, color: C.ink, w: FontWeight.w500)),
      ]),
    );
  }
}

/// Placeholder village street until bg.detective.street exists: sky, three little houses, cobbles.
class _StreetPainter extends CustomPainter {
  final int houses;
  _StreetPainter(this.houses);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7C8FC9), Color(0xFFF2B98A)]).createShader(Offset.zero & size));
    const walls = [Color(0xFFF08A5D), Color(0xFF6CC3D5), Color(0xFFE8A6C8), Color(0xFFB8D86B)];
    final hw = (w - 24) / houses;
    for (var i = 0; i < houses; i++) {
      final x = 12 + i * hw;
      final wall = Rect.fromLTWH(x + 4, 90, hw - 8, h - 150);
      canvas.drawRRect(RRect.fromRectAndRadius(wall, const Radius.circular(8)), Paint()..color = walls[i % walls.length]);
      final roof = Path()
        ..moveTo(x - 2, 96)
        ..lineTo(x + hw / 2, 40)
        ..lineTo(x + hw + 2, 96)
        ..close();
      canvas.drawPath(roof, Paint()..color = const Color(0xFF8B3A2B));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + hw / 2 - 16, h - 110, 32, 50), const Radius.circular(14)), Paint()..color = const Color(0xFF6B3E1E));
    }
    canvas.drawRect(Rect.fromLTWH(0, h - 60, w, 60), Paint()..color = const Color(0xFFB59A7A));
    final cob = Paint()..color = const Color(0xFF9C8264);
    for (var x = 8.0; x < w; x += 26) {
      canvas.drawOval(Rect.fromLTWH(x, h - 44 + (x % 3) * 4, 18, 9), cob);
    }
  }

  @override
  bool shouldRepaint(_StreetPainter o) => o.houses != houses;
}
