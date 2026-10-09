import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../core/audio.dart';
import '../../core/theme.dart';
import '../../data/strings.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../game_module.dart';
import 'recognizer.dart';

/// Letter templates are built once (from the app font) and shared by every Magic Writer round.
class WriterTemplates {
  static Future<LetterRecognizer>? _f;
  static Future<LetterRecognizer> get() => _f ??= LetterRecognizer.build();
}

/// How much help the rune shows, by step (spelling must not become copying at the higher steps):
/// 1–2 trace the dotted letters · 3–5 empty boxes + the letter tiles as hints · 6+ empty boxes only.
enum WriterGuide { trace, tiles, none }

WriterGuide writerGuide(int step) => step <= 2 ? WriterGuide.trace : (step <= 5 ? WriterGuide.tiles : WriterGuide.none);

const writerTreasures = ['💰', '👑', '💎', '🗝️', '🏴‍☠️', '🧭', '📜', '🪙', '🦜', '⚓'];

/// Game 10 · Magic Writer — "Captain Kalam's Treasure Runes".
/// Captain Kalam says a word; the child writes it with a finger, one letter per glowing rune box, and taps ✓.
/// Each box is checked with the on-device letter recogniser. Wrong boxes turn pale and show a ghost letter to
/// trace; right boxes lock with golden ink. The chest opens when every rune is right.
class MagicWriterItem extends StatefulWidget {
  final GameCtx ctx;
  final int runeBook; // persistent: words written so far
  final Future<LetterRecognizer> Function()? recognizer; // tests can inject
  const MagicWriterItem({super.key, required this.ctx, this.runeBook = 0, this.recognizer});
  @override
  State<MagicWriterItem> createState() => _MagicWriterItemState();
}

class _MagicWriterItemState extends State<MagicWriterItem> with SingleTickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final List<String> letters = it.answer.isNotEmpty ? it.answer : it.options[it.correct].label.split('');
  late final List<List<List<Offset>>> _ink = List.generate(letters.length, (_) => []);
  final Set<int> _ok = {};
  final Set<int> _ghost = {}; // show the letter faintly to trace after a miss
  final List<String> _tags = [];
  LetterRecognizer? _rec;
  int _attempts = 0;
  bool _resolved = false;
  bool _open = false;
  bool _disposed = false;

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  bool get demo => widget.ctx.demo;
  String get word => letters.join();
  WriterGuide get guide => widget.ctx.scaffold && writerGuide(it.level) == WriterGuide.none ? WriterGuide.tiles : writerGuide(it.level);
  void _say(String t) => AudioManager.instance.say(t, ttsLocale: widget.ctx.pack.tts);

  @override
  void initState() {
    super.initState();
    (widget.recognizer ?? WriterTemplates.get)().then((r) {
      if (!_disposed) setState(() => _rec = r);
      if (demo && !_disposed) _runDemo();
    });
    if (widget.ctx.scaffold) widget.ctx.feedback(Str.t(lang, 'hint'), true);
    if (!demo) WidgetsBinding.instance.addPostFrameCallback((_) => _say(word));
  }

  @override
  void dispose() {
    _disposed = true;
    _glow.dispose();
    super.dispose();
  }

  Future<void> _runDemo() async {
    for (var i = 0; i < letters.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (_disposed || _rec == null) return;
      setState(() {
        _ink[i] = _rec!.sample(letters[i], scale: 50, at: const Offset(30, 38));
        _ok.add(i);
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_disposed) setState(() => _open = true);
  }

  void _clearBox(int i) {
    if (_resolved || demo || _ok.contains(i)) return;
    setState(() => _ink[i] = []);
  }

  void _check() {
    if (_resolved || demo || _rec == null) return;
    if (_ink.any((s) => s.isEmpty)) {
      widget.ctx.feedback('Write a letter in every rune box.', false);
      return;
    }
    final wrong = <int>[];
    for (var i = 0; i < letters.length; i++) {
      if (_ok.contains(i)) continue;
      if (_rec!.accepts(_ink[i], letters[i])) {
        _ok.add(i);
      } else {
        wrong.add(i);
      }
    }
    if (wrong.isEmpty) {
      _win();
      return;
    }
    _attempts++;
    _tags.add('Letter formation');
    AudioManager.instance.sfx('miss_soft');
    if (_attempts < 2) {
      setState(() {
        for (final i in wrong) {
          _ink[i] = [];
          _ghost.add(i);
        }
      });
      widget.ctx.feedback('Steady, matey! Trace the glowing letter${wrong.length > 1 ? 's' : ''} again.', false);
      _say(word);
    } else {
      setState(() {
        _resolved = true;
        for (var i = 0; i < letters.length; i++) {
          _ghost.add(i);
        }
      });
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      _say(word);
      _finish(false, 2600);
    }
  }

  void _win() {
    final first = _attempts == 0;
    setState(() {
      _resolved = true;
      _open = true;
    });
    AudioManager.instance.sfx('chest_open', volume: .7);
    _say(word);
    widget.ctx.feedback(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
    _finish(first, 2000);
  }

  void _finish(bool first, int delayMs) {
    final r = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: first, ms: _clock.elapsedMilliseconds, tags: [..._tags]);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_disposed && !demo) widget.ctx.done(r);
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(10, 4, 10, 6), child: _header()),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(fit: StackFit.expand, children: [
              ArtImage('bg.writer.cove', fit: BoxFit.cover, fallback: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFB38A), Color(0xFFE0568A), Color(0xFF5A3F86)])))),
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(), // finger strokes must write, never scroll
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                child: Column(children: [
                  _chest(),
                  const SizedBox(height: 10),
                  if (guide == WriterGuide.tiles && !_resolved) _tileHints(),
                  const SizedBox(height: 8),
                  _boxes(),
                  const SizedBox(height: 14),
                  if (!_resolved && !demo)
                    Opacity(
                      opacity: _rec == null ? .4 : 1,
                      child: BigButton(label: '✓  Open the chest', style: BtnStyle.go, width: 260, height: 54, onTap: _check),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _header() => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          SizedBox(width: 56, height: 58, child: ArtImage('char.kalam.happy', fallback: const Center(child: Text('🦜', style: TextStyle(fontSize: 38))))),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(guide == WriterGuide.trace ? 'Trace the glowing runes!' : 'Write the word you hear!', style: ts(17, color: C.ink)),
              if (!demo) Text('📜 Rune Book: ${widget.runeBook} words', style: ts(12, color: C.inkSoft, w: FontWeight.w600)),
            ]),
          ),
          if (it.emoji != null) Text(it.emoji!, style: const TextStyle(fontSize: 34)),
          RoundIconButton(icon: Icons.volume_up_rounded, label: 'Hear the word', color: C.gold, size: 44, onTap: demo ? () {} : () => _say(word)),
        ]),
      );

  Widget _chest() => AnimatedBuilder(
        animation: _glow,
        builder: (_, _) => Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
          if (_open) Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFFFD45C).withValues(alpha: .6 + .3 * sin(_glow.value * 2 * pi)), blurRadius: 40)])),
          SizedBox(width: 110, height: 90, child: ArtImage(_open ? 'prop.writer.chest_open' : 'prop.writer.chest', fallback: Center(child: Text(_open ? '🎁' : '🧰', style: const TextStyle(fontSize: 70))))),
          if (_open && !demo)
            Positioned(top: -18, child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 900), curve: Curves.elasticOut, builder: (_, v, child) => Transform.scale(scale: v, child: child), child: Text(writerTreasures[widget.runeBook % writerTreasures.length], style: const TextStyle(fontSize: 40)))),
        ]),
      );

  Widget _tileHints() {
    final shuffled = [...letters]..shuffle(Random(word.hashCode));
    return Wrap(alignment: WrapAlignment.center, spacing: 6, children: [
      for (final l in shuffled)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(10)),
          child: Text(l, style: ts(20, color: C.ink)),
        ),
    ]);
  }

  Widget _boxes() {
    return LayoutBuilder(builder: (context, c) {
      final perRow = min(letters.length, 5);
      final w = min(96.0, (c.maxWidth - 8) / perRow - 8);
      return Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < letters.length; i++) _box(i, w),
      ]);
    });
  }

  Widget _box(int i, double w) {
    final ok = _ok.contains(i);
    final ghost = guide == WriterGuide.trace || _ghost.contains(i);
    final h = w * 1.25;
    return SizedBox(
      key: ValueKey('rune$i'),
      width: w,
      height: h,
      child: Stack(children: [
        GestureDetector(
          onPanStart: _resolved || demo || ok ? null : (d) => setState(() => _ink[i].add([d.localPosition])),
          onPanUpdate: _resolved || demo || ok ? null : (d) => setState(() => _ink[i].last.add(d.localPosition)),
          child: AnimatedBuilder(
            animation: _glow,
            builder: (_, _) => Container(
              decoration: BoxDecoration(
                color: ok ? const Color(0xCCFFF3C4) : const Color(0xCC2A1B3D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ok ? const Color(0xFFFFD45C) : (_ghost.contains(i) && !_resolved ? const Color(0xFFE3A3A3) : const Color(0xFFB98CFF).withValues(alpha: .6 + .4 * sin(_glow.value * 2 * pi).abs())),
                  width: 3,
                ),
              ),
              child: CustomPaint(
                painter: _InkPainter(_ink[i], gold: ok),
                child: Center(
                  child: ghost && !ok
                      ? Text(letters[i], style: ts(h * .62, color: Colors.white.withValues(alpha: .22)))
                      : null,
                ),
              ),
            ),
          ),
        ),
        if (guide == WriterGuide.trace && !ok && _ink[i].isEmpty)
          Positioned(left: w * .2, top: h * .28, child: IgnorePointer(child: _startDot())), // strokes start ON the dot
        if (!ok && !_resolved && !demo && _ink[i].isNotEmpty)
          Positioned(right: 2, top: 2, child: GestureDetector(onTap: () => _clearBox(i), child: const CircleAvatar(radius: 12, backgroundColor: Colors.white70, child: Icon(Icons.close_rounded, size: 16, color: C.ink)))),
      ]),
    );
  }

  Widget _startDot() => AnimatedBuilder(
        animation: _glow,
        builder: (_, _) => Container(width: 12 + 4 * sin(_glow.value * 2 * pi).abs(), height: 12 + 4 * sin(_glow.value * 2 * pi).abs(), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8CFF9E))),
      );
}

/// Sparkling quill ink.
class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final bool gold;
  _InkPainter(this.strokes, {required this.gold});
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = (gold ? const Color(0xFFFFD45C) : const Color(0xFFB8F0FF)).withValues(alpha: .45)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final core = Paint()
      ..color = gold ? const Color(0xFFFFF3C4) : Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, 3, core..style = PaintingStyle.fill);
        core.style = PaintingStyle.stroke;
        continue;
      }
      final p = Path()..moveTo(s.first.dx, s.first.dy);
      for (final q in s.skip(1)) {
        p.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(p, glow);
      canvas.drawPath(p, core);
    }
  }

  @override
  bool shouldRepaint(_InkPainter o) => true;
}
