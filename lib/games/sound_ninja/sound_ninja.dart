import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../core/audio.dart';
import '../../core/loc.dart';
import '../../data/hi_text.dart';
import '../../core/theme.dart';
import '../../data/strings.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../game_module.dart';

/// Ninja belt from all sounds heard right (white → black).
String ninjaBelt(int n, {bool hindi = false}) {
  const belts = ['White', 'Yellow', 'Orange', 'Green', 'Blue', 'Purple', 'Brown', 'Black'];
  final i = min(belts.length - 1, n ~/ 12);
  return hindi ? '${HiText.belts[i]}${const Tr(true)(' Belt')}' : '${belts[i]} Belt';
}

const _fruitColors = [Color(0xFFFF7A59), Color(0xFFFFC93C), Color(0xFF8BD450), Color(0xFFB98CFF)];

/// Combo of first-try slices in one quest. A mistake only pauses it (never resets to zero, per design).
class NinjaCombo {
  static int value = 0;
  static void reset() => value = 0;
}

/// Game 2 · Sound Ninja — "Pip and the Sound Fruits".
/// Sound-fruits float calmly in the dojo. Tap a fruit to hear it; swipe through it to slice (choose) it.
/// Syllable rounds: one big fruit — slice it into as many pieces as the word has beats, then ✓.
class SoundNinjaItem extends StatefulWidget {
  final GameCtx ctx;
  final int heardRight; // persistent: for the ninja belt
  const SoundNinjaItem({super.key, required this.ctx, this.heardRight = 0});
  @override
  State<SoundNinjaItem> createState() => _SoundNinjaItemState();
}

class _SoundNinjaItemState extends State<SoundNinjaItem> with TickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  final List<String> _tags = [];
  final Set<int> _sliced = {}; // wrong fruits already cut (they fall away)
  final List<Offset> _trail = []; // last few points, for drawing the blade trail
  final ValueNotifier<int> _trailTick = ValueNotifier(0); // repaints only the trail while swiping (no full rebuild per finger move)
  final List<Offset> _path = []; // the whole swipe, for deciding what was sliced
  final List<double> _cuts = []; // clap mode: cut angles across the big fruit
  Size _size = const Size(360, 420);
  int? _correctCut;
  int? _heard;
  int _attempts = 0;
  bool _resolved = false;
  bool _disposed = false;

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  Tr get tr => Tr(lang == 'hi'); // Hindi demo
  bool get demo => widget.ctx.demo;
  bool get clap => it.id.startsWith('pc:');
  int get n => it.options.length;
  int get beats => int.tryParse(it.options[it.correct].label) ?? 1;
  void _say(String t) => AudioManager.instance.say(t, ttsLocale: widget.ctx.pack.tts);

  @override
  void initState() {
    super.initState();
    if (demo) NinjaCombo.reset();
    AudioManager.instance.preloadSfx(const ['slice_swish', 'fruit_pop', 'bamboo_clack', 'firefly_chime', 'miss_soft']);
    if (widget.ctx.scaffold && n > 2 && !clap) {
      _sliced.add([for (var i = 0; i < n; i++) if (i != it.correct) i].first);
      widget.ctx.feedback(Str.t(lang, 'hint'), true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => demo ? _runDemo() : _say(clap ? (it.stimulus ?? it.say) : it.say));
  }

  @override
  void dispose() {
    _disposed = true;
    _trailTick.dispose();
    _t.dispose();
    super.dispose();
  }

  Future<void> _runDemo() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (_disposed) return;
    if (clap) {
      for (var k = 1; k < beats; k++) {
        setState(() => _cuts.add(.4 * k));
        AudioManager.instance.sfx('slice_swish', volume: .4);
        await Future.delayed(const Duration(milliseconds: 600));
        if (_disposed) return;
      }
      setState(() => _correctCut = it.correct);
    } else {
      AudioManager.instance.sfx('slice_swish', volume: .4);
      setState(() => _correctCut = it.correct);
    }
  }

  // ---------------- geometry ----------------
  double get _r => min(_size.width / (n + .6), _size.height * .26) * .42;

  Offset _fruitAt(int i) {
    final x = _size.width * (i + 1) / (n + 1);
    final y = _size.height * (.42 + (i.isOdd ? .12 : 0)) + sin((_t.value + i * .31) * 2 * pi) * 10;
    return Offset(x, y);
  }

  Offset get _bigCentre => Offset(_size.width / 2, _size.height * .45);
  double get _bigR => min(_size.width, _size.height) * .3;

  int? _fruitHit(Offset p) {
    for (var i = 0; i < n; i++) {
      if (_sliced.contains(i)) continue;
      if ((_fruitAt(i) - p).distance < _r * 1.15) return i;
    }
    return null;
  }

  static double _segDist(Offset a, Offset b, Offset p) {
    final ab = b - a;
    final l2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (l2 == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / l2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  // ---------------- input ----------------
  void _tapAt(Offset p) {
    if (demo || _resolved) return;
    if (clap) {
      if ((p - _bigCentre).distance < _bigR) _say(it.stimulus ?? it.say);
      return;
    }
    final i = _fruitHit(p);
    if (i == null) return;
    AudioManager.instance.sfx('fruit_pop', volume: .5);
    setState(() => _heard = i);
    _say(it.options[i].say ?? it.options[i].label);
  }

  void _swipe(Offset p) {
    if (demo || _resolved) return;
    _path.add(p);
    _trail.add(p);
    if (_trail.length > 14) _trail.removeAt(0);
    _trailTick.value++;
  }

  void _swipeEnd() {
    final path = List.of(_path);
    _path.clear();
    if (demo || _resolved || path.length < 2) {
      setState(() { _trail.clear(); _trailTick.value++; });
      return;
    }
    final a = path.first, b = path.last;
    if ((b - a).distance < 40) {
      setState(() { _trail.clear(); _trailTick.value++; });
      return;
    }
    if (clap) {
      // a cut must pass through the fruit
      if (_segDist(a, b, _bigCentre) < _bigR * .8 && _cuts.length < 4) {
        AudioManager.instance.sfx('slice_swish', volume: .5);
        setState(() => _cuts.add(atan2(b.dy - a.dy, b.dx - a.dx)));
      }
      setState(() { _trail.clear(); _trailTick.value++; });
      return;
    }
    int? hit;
    for (var k = 1; k < path.length && hit == null; k++) {
      for (var i = 0; i < n; i++) {
        if (!_sliced.contains(i) && _segDist(path[k - 1], path[k], _fruitAt(i)) < _r) {
          hit = i;
          break;
        }
      }
    }
    setState(() { _trail.clear(); _trailTick.value++; });
    if (hit != null) _choose(hit);
  }

  void _choose(int i) {
    AudioManager.instance.sfx('slice_swish', volume: .5);
    if (i == it.correct) {
      final first = _attempts == 0;
      setState(() {
        _resolved = true;
        _correctCut = i;
      });
      if (first) NinjaCombo.value++;
      _say(it.options[i].say ?? it.options[i].label);
      AudioManager.instance.sfx('bamboo_clack', volume: .55);
      AudioManager.instance.sfx('firefly_chime', volume: .3);
      widget.ctx.feedback(first ? (NinjaCombo.value >= 3 ? tr.f('Combo ×{n}! Ninja!', {'n': NinjaCombo.value}) : Str.good(lang)) : Str.t(lang, 'good3'), true);
      _finish(first, 1700);
      return;
    }
    _attempts++;
    final t = it.options[i].tag;
    if (t != null) _tags.add(t);
    final canRetry = _attempts < 2 && (n - _sliced.length - 1) > 1;
    setState(() {
      _sliced.add(i);
      if (!canRetry) {
        _resolved = true;
        _correctCut = it.correct;
      }
    });
    AudioManager.instance.sfx('miss_soft');
    if (canRetry) {
      widget.ctx.feedback(it.hint.isEmpty ? Str.t(lang, 'almost') : it.hint, false);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!_disposed) _say(it.say);
      });
    } else {
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      _say(it.options[it.correct].say ?? it.options[it.correct].label);
      _finish(false, 2400);
    }
  }

  void _clapDone() {
    if (_resolved || demo) return; // 0 cuts = 1 piece is a valid answer (one-beat words like "bat")
    final pieces = _cuts.length + 1;
    if (pieces == beats) {
      _choose(it.correct);
      return;
    }
    _attempts++;
    _tags.add('Syllable count error');
    AudioManager.instance.sfx('miss_soft');
    if (_attempts < 2) {
      setState(_cuts.clear);
      widget.ctx.feedback(tr.f('{hint} Say “{w}” slowly.', {'hint': it.hint, 'w': '${it.stimulus}'}), false);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!_disposed) _say(it.stimulus ?? it.say);
      });
    } else {
      setState(() {
        _resolved = true;
        _cuts
          ..clear()
          ..addAll([for (var k = 1; k < beats; k++) .4 * k]);
        _correctCut = it.correct;
      });
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      _finish(false, 2400);
    }
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
              ArtImage('bg.ninja.dojo', fit: BoxFit.cover, fallback: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF14283A), Color(0xFF1F4A3A), Color(0xFF2E6B45)])))),
              const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _BambooPainter()))), // still picture: painted once
              LayoutBuilder(builder: (context, box) {
                _size = Size(box.maxWidth, box.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _tapAt(d.localPosition),
                  onPanStart: (d) => _swipe(d.localPosition),
                  onPanUpdate: (d) => _swipe(d.localPosition),
                  onPanEnd: (_) => _swipeEnd(),
                  child: Stack(children: [
                    // the bobbing fruit and the blade trail are separate layers: neither repaints the dojo or the cards
                    Positioned.fill(child: RepaintBoundary(child: AnimatedBuilder(animation: _t, builder: (_, _) => Stack(children: [if (clap) _bigFruit() else for (var i = 0; i < n; i++) _fruit(i)])))),
                    Positioned.fill(child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _TrailPainter(_trail, _trailTick))))),
                  ]),
                );
              }),
              if (clap && !demo && !_resolved)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    RoundIconButton(icon: Icons.refresh_rounded, label: tr('Start again'), size: 46, onTap: () => setState(_cuts.clear)),
                    const SizedBox(width: 12),
                    Opacity(opacity: 1, child: BigButton(label: '✓', style: BtnStyle.go, width: 90, height: 52, fontSize: 26, onTap: _clapDone)),
                  ]),
                ),
              if (!clap && !demo && !_resolved)
                Positioned(bottom: 10, left: 0, right: 0, child: Center(child: Text(tr('Tap to hear · swipe through to slice'), style: ts(14, color: Colors.white, w: FontWeight.w600).copyWith(shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)])))),
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
          SizedBox(width: 56, height: 58, child: ArtImage('char.pip.happy', fallback: const Center(child: Text('🥷', style: TextStyle(fontSize: 38))))),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(clap ? tr.f('Slice “{w}” into its beats!', {'w': '${it.stimulus}'}) : it.prompt, style: ts(17, color: C.ink)),
              if (!demo) Text('🥋 ${ninjaBelt(widget.heardRight, hindi: tr.hi)}${NinjaCombo.value >= 2 ? '  ·  ${tr.f('combo ×{n}', {'n': NinjaCombo.value})}' : ''}', style: ts(12, color: C.inkSoft, w: FontWeight.w600)),
            ]),
          ),
          if (it.emoji != null && !clap) Text(it.emoji!, style: const TextStyle(fontSize: 36)),
          RoundIconButton(icon: Icons.volume_up_rounded, label: tr('Hear it again'), color: C.gold, size: 44, onTap: demo ? () {} : () => _say(clap ? (it.stimulus ?? it.say) : it.say)),
        ]),
      );

  Widget _fruit(int i) {
    final c = _fruitAt(i);
    final r = _r;
    final o = it.options[i];
    final wrongCut = _sliced.contains(i) && i != it.correct;
    final rightCut = _correctCut == i;
    final col = _fruitColors[i % _fruitColors.length];
    return Positioned(
      left: c.dx - r,
      top: c.dy - r + (wrongCut ? 40 : 0),
      width: r * 2,
      height: r * 2,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: wrongCut ? .25 : 1,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          if (rightCut) ...[
            // two halves flying apart
            Transform.translate(offset: Offset(-r * .35, -r * .2), child: Transform.rotate(angle: -.4, child: _half(col, r, true))),
            Transform.translate(offset: Offset(r * .35, r * .2), child: Transform.rotate(angle: .4, child: _half(col, r, false))),
          ] else
            Container(
              width: r * 2,
              height: r * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(center: const Alignment(-.3, -.4), colors: [Color.lerp(col, Colors.white, .45)!, col]),
                border: Border.all(color: _heard == i ? Colors.white : Colors.black26, width: _heard == i ? 4 : 2),
                boxShadow: [BoxShadow(color: col.withValues(alpha: .5), blurRadius: _heard == i ? 20 : 8)],
              ),
            ),
          Positioned(top: -r * .18, child: Text('🍃', style: TextStyle(fontSize: r * .45))),
          if (!rightCut)
            o.emoji != null
                ? Text(o.emoji!, style: TextStyle(fontSize: r * .95))
                : Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.volume_up_rounded, color: Colors.white, size: r * .55), Text('${i + 1}', style: ts(r * .5, color: Colors.white))]),
          if (rightCut) Text('✨', style: TextStyle(fontSize: r * .8)),
        ]),
      ),
    );
  }

  Widget _half(Color col, double r, bool top) => ClipRect(
        child: Align(
          alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
          heightFactor: .5,
          child: Container(width: r * 2, height: r * 2, decoration: BoxDecoration(shape: BoxShape.circle, color: col, border: Border.all(color: const Color(0xFFFFF3C4), width: 5))),
        ),
      );

  Widget _bigFruit() {
    final c = _bigCentre, r = _bigR;
    final done = _correctCut != null;
    return Positioned(
      left: c.dx - r,
      top: c.dy - r,
      width: r * 2,
      height: r * 2,
      child: CustomPaint(
        painter: _BigFruitPainter(cuts: List.of(_cuts), done: done, hindi: tr.hi),
        child: Center(child: it.emoji != null ? Text(it.emoji!, style: TextStyle(fontSize: r * .7)) : null),
      ),
    );
  }
}

class _BigFruitPainter extends CustomPainter {
  final List<double> cuts;
  final bool done;
  final bool hindi; // Hindi demo
  _BigFruitPainter({required this.cuts, required this.done, this.hindi = false});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..shader = RadialGradient(center: const Alignment(-.3, -.4), colors: done ? const [Color(0xFFCFFFB0), Color(0xFF5DBB63)] : const [Color(0xFFFFE0B0), Color(0xFFFF8A3D)]).createShader(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(c, r, Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    // each cut: a bright slash through the fruit, spaced so the pieces are easy to count
    for (var k = 0; k < cuts.length; k++) {
      final off = (k - (cuts.length - 1) / 2) * r * .5;
      final p1 = c + Offset(off - r * .15, -r * .95), p2 = c + Offset(off + r * .15, r * .95);
      canvas.drawLine(p1, p2, Paint()
        ..color = const Color(0xFFFFF3C4)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round);
    }
    final tp = TextPainter(text: TextSpan(text: hindi ? '${cuts.length + 1} ${cuts.isEmpty ? 'टुकड़ा' : 'टुकड़े'}' : '${cuts.length + 1} ${cuts.isEmpty ? 'piece' : 'pieces'}', style: const TextStyle(fontFamily: 'Fredoka', fontFamilyFallback: ['NotoSansDevanagari'], fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, c + Offset(-tp.width / 2, r + 8));
  }

  @override
  bool shouldRepaint(_BigFruitPainter o) => o.cuts.length != cuts.length || o.done != done;
}

class _TrailPainter extends CustomPainter {
  final List<Offset> pts;
  _TrailPainter(this.pts, Listenable repaint) : super(repaint: repaint);
  @override
  void paint(Canvas canvas, Size size) {
    for (var k = 1; k < pts.length; k++) {
      canvas.drawLine(pts[k - 1], pts[k], Paint()
        ..color = Colors.white.withValues(alpha: k / pts.length)
        ..strokeWidth = 2 + 6 * k / pts.length
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter o) => false; // repaints through the notifier
}

/// Placeholder dojo: bamboo stalks at the sides.
class _BambooPainter extends CustomPainter {
  const _BambooPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF6FBF5A);
    final joint = Paint()..color = const Color(0xFF3F8A3A);
    for (final x in [12.0, 34.0, size.width - 40, size.width - 18]) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 12, size.height), p);
      for (var y = 30.0; y < size.height; y += 70) {
        canvas.drawRect(Rect.fromLTWH(x - 1, y, 14, 4), joint);
      }
    }
  }

  @override
  bool shouldRepaint(_BambooPainter o) => false;
}
