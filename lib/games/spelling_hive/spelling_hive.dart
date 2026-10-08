import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../core/audio.dart';
import '../../core/theme.dart';
import '../../core/tts.dart';
import '../../data/strings.dart';
import '../../models/models.dart';
import '../../story/puppets.dart';
import '../../widgets/common.dart';
import '../game_module.dart';

/// Game 9 · Spelling Hive — "Queen Madhu's Honey Kingdom".
/// The word is spoken and pictured; worker bees carry letter tiles; the child drags (or taps) them into the
/// honeycomb. Correct → honey pours into the cells and a baby bee hatches (the hive keeps growing forever).
/// Wrong → correct cells stay locked in, only the wrong cells turn pale, and Queen Madhu says which sound to listen for.
class SpellingHiveItem extends StatefulWidget {
  final GameCtx ctx;
  final int hiveBees; // bees hatched so far (persistent hive growth)
  const SpellingHiveItem({super.key, required this.ctx, this.hiveBees = 0});
  @override
  State<SpellingHiveItem> createState() => _SpellingHiveItemState();
}

class _SpellingHiveItemState extends State<SpellingHiveItem> with TickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late final List<int?> _slots = List<int?>.filled(it.answer.length, null);
  final Set<int> _locked = {}; // cells confirmed correct (green, cannot be removed)
  final Set<int> _pale = {}; // cells that were wrong on the last try
  final Set<int> _used = {}; // tile indexes sitting in a cell
  final Set<int> _hidden = {}; // distractor tiles removed by the scaffold
  final List<String> _tags = [];
  int _attempts = 0;
  bool _resolved = false;
  bool _hatched = false;
  int _shake = 0;
  int? _hover;

  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final AnimationController _honey = AnimationController(vsync: this, duration: Duration(milliseconds: 260 * max(3, it.answer.length)));
  late final AnimationController _hatch = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  bool get demo => widget.ctx.demo;
  bool get full => !_slots.contains(null);
  void _say(String t) => Speaker.instance.speak(t, widget.ctx.pack.tts);

  @override
  void initState() {
    super.initState();
    if (widget.ctx.scaffold && it.answer.isNotEmpty) {
      // Scaffold: the first letter is already in its cell and all but one distractor fly away.
      final idx = it.tiles.indexOf(it.answer.first);
      _slots[0] = idx;
      _locked.add(0);
      _used.add(idx);
      final need = [...it.answer];
      final extras = <int>[];
      for (var i = 0; i < it.tiles.length; i++) {
        if (!need.remove(it.tiles[i])) extras.add(i);
      }
      _hidden.addAll(extras.skip(1));
      widget.ctx.feedback(Str.t(lang, 'hint'), true);
    }
    if (demo) {
      _runDemo();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _say(it.say));
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _honey.dispose();
    _hatch.dispose();
    super.dispose();
  }

  Future<void> _runDemo() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    for (var i = 0; i < it.answer.length; i++) {
      if (!mounted) return;
      if (_slots[i] != null) continue;
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final k = _tileFor(it.answer[i]);
      if (k != null) _place(k, cell: i, force: true);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _check(force: true);
  }

  int? _tileFor(String letter) {
    for (var k = 0; k < it.tiles.length; k++) {
      if (it.tiles[k] == letter && !_used.contains(k) && !_hidden.contains(k)) return k;
    }
    return null;
  }

  // ---------------- moves ----------------
  void _place(int tile, {int? cell, bool force = false}) {
    if (_resolved || (demo && !force) || _used.contains(tile)) return;
    final target = cell ?? _slots.indexOf(null);
    if (target < 0 || _locked.contains(target)) return;
    AudioManager.instance.sfx('tile_snap');
    if (!demo) _say(it.tiles[tile]);
    setState(() {
      final old = _slots[target];
      if (old != null) _used.remove(old); // dropping onto a filled cell swaps the old tile back to its bee
      _slots[target] = tile;
      _used.add(tile);
      _pale.remove(target);
      _hover = null;
    });
  }

  void _remove(int cell) {
    if (_resolved || demo || _locked.contains(cell) || _slots[cell] == null) return;
    AudioManager.instance.sfx('tile_return');
    setState(() {
      _used.remove(_slots[cell]);
      _slots[cell] = null;
    });
  }

  void _check({bool force = false}) {
    if (_resolved || (demo && !force) || !full) return;
    final got = [for (final s in _slots) it.tiles[s!]];
    final wrong = [for (var i = 0; i < got.length; i++) if (got[i] != it.answer[i]) i];
    if (wrong.isEmpty) {
      _win();
      return;
    }
    _attempts++;
    _tags.add(widget.ctx.pack.spellingError(got, it.answer));
    if (_attempts < 2) {
      AudioManager.instance.sfx('miss_soft');
      setState(() {
        _shake++;
        for (var i = 0; i < got.length; i++) {
          if (wrong.contains(i)) {
            _used.remove(_slots[i]);
            _slots[i] = null;
            _pale.add(i);
          } else {
            _locked.add(i);
          }
        }
      });
      widget.ctx.feedback(_hintFor(wrong.first), false);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _say(it.replaySay ?? it.say);
      });
    } else {
      // Kindly show the right spelling, then move on.
      setState(() {
        _resolved = true;
        _pale.clear();
        _used.clear();
        for (var i = 0; i < it.answer.length; i++) {
          _slots[i] = null;
        }
        for (var i = 0; i < it.answer.length; i++) {
          final k = _tileFor(it.answer[i]) ?? it.tiles.indexOf(it.answer[i]);
          _slots[i] = k;
          _used.add(k);
        }
      });
      _honey.animateTo(.45);
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      _say(it.replaySay ?? it.say);
      _finish(false, 2400);
    }
  }

  /// Error-aware help: name the sound that went wrong (first / vowel / middle / end), never the letter.
  String _hintFor(int cell) {
    final ch = it.answer[cell];
    if ('aeiou'.contains(ch) && cell > 0) return 'Hmm… listen for the vowel sound in the middle.';
    if (cell == 0) return 'Hmm… listen to the very first sound.';
    if (cell == it.answer.length - 1) return 'Hmm… listen to the end sound, little one.';
    return 'Hmm… listen to the middle sound.';
  }

  Future<void> _win() async {
    setState(() {
      _resolved = true;
      _pale.clear();
      _locked.addAll(List.generate(_slots.length, (i) => i));
    });
    final first = _attempts == 0;
    AudioManager.instance.sfx('magic', volume: .6);
    widget.ctx.feedback(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
    await _honey.forward();
    if (!mounted) return;
    setState(() => _hatched = true);
    AudioManager.instance.sfx('pop');
    _say(it.replaySay ?? it.say);
    _hatch.forward();
    if (!demo) _finish(first, 1700);
  }

  void _finish(bool firstTry, int delayMs) {
    final r = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: firstTry, ms: _clock.elapsedMilliseconds, tags: [..._tags]);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted && !demo) widget.ctx.done(r);
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Stack(children: [
        Positioned.fill(child: ArtImage('bg.hive', fit: BoxFit.cover, fallback: const SizedBox.shrink())),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: max(0, c.maxHeight - 16)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _header(),
              const SizedBox(height: 14),
              _comb(w - 24),
              const SizedBox(height: 18),
              _tiles(),
              const SizedBox(height: 14),
              AnimatedOpacity(
                opacity: full && !_resolved ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !full || _resolved,
                  child: BigButton(label: '🍯  ${Str.t(lang, 'check')}', style: BtnStyle.go, width: 220, height: 54, onTap: _check),
                ),
              ),
            ]),
          ),
        ),
        if (_hatched) Positioned.fill(child: IgnorePointer(child: _hatchOverlay())),
      ]);
    });
  }

  Widget _header() {
    final bees = widget.hiveBees + (_hatched && !demo ? 1 : 0);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(width: 64, height: 64, child: Puppet(id: 'madhu', size: 64)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (it.emoji != null) Text(it.emoji!, style: const TextStyle(fontSize: 46)),
          const SizedBox(width: 8),
          RoundIconButton(icon: Icons.volume_up_rounded, label: 'Hear the word', color: C.gold, onTap: () => _say(it.replaySay ?? it.say)),
        ]),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFFFE58A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0A100), width: 2)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🐝 $bees', style: ts(16, color: const Color(0xFF6B4200))),
          Text('floor ${bees ~/ 10 + 1}', style: ts(11, color: const Color(0xFF6B4200), w: FontWeight.w600)),
        ]),
      ),
    ]);
  }

  /// The honeycomb: one hexagon per letter; long words wrap into two staggered rows like a real comb.
  Widget _comb(double maxW) {
    final n = it.answer.length;
    var perRow = n;
    var cw = min(72.0, (maxW - 8) / n);
    if (cw < 50) {
      perRow = (n + 1) ~/ 2;
      cw = min(72.0, (maxW - 8) / (perRow + .5));
    }
    final ch = cw * 1.12;
    final rows = (n / perRow).ceil();
    final width = cw * perRow + (rows > 1 ? cw / 2 : 0);
    final height = ch + (rows - 1) * ch * .78;
    return TweenAnimationBuilder<double>(
      key: ValueKey(_shake),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (_, t, child) => Transform.translate(offset: Offset(_shake == 0 ? 0 : sin(t * pi * 5) * 8 * (1 - t), 0), child: child),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(children: [
          for (var i = 0; i < n; i++)
            Positioned(
              left: (i % perRow) * cw + (i >= perRow ? cw / 2 : 0),
              top: (i ~/ perRow) * ch * .78,
              width: cw,
              height: ch,
              child: _cell(i, cw),
            ),
        ]),
      ),
    );
  }

  Widget _cell(int i, double size) {
    final tile = _slots[i];
    final letter = tile == null ? null : it.tiles[tile];
    final n = it.answer.length;
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) {
        final ok = !_resolved && !demo && !_locked.contains(i);
        if (ok) setState(() => _hover = i);
        return ok;
      },
      onLeave: (_) => setState(() => _hover = null),
      onAcceptWithDetails: (d) => _place(d.data, cell: i),
      builder: (_, _, _) => GestureDetector(
        onTap: () => _remove(i),
        child: AnimatedBuilder(
          animation: Listenable.merge([_honey, _bob]),
          builder: (_, _) {
            // cells fill one after another, left to right
            final f = ((_honey.value * n) - i).clamp(0.0, 1.0);
            return CustomPaint(
              painter: _HexPainter(
                fill: f,
                locked: _locked.contains(i) && !_resolved,
                pale: _pale.contains(i),
                hover: _hover == i,
                wave: _bob.value,
              ),
              child: Center(
                child: letter == null
                    ? null
                    : TweenAnimationBuilder<double>(
                        key: ValueKey('c$i$tile'),
                        tween: Tween(begin: .4, end: 1),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        builder: (_, v, child) => Transform.scale(scale: v, child: child),
                        child: Text(letter, style: ts(size * .5, color: f > .5 ? const Color(0xFF5A3300) : C.ink)),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tiles() {
    final visible = [for (var k = 0; k < it.tiles.length; k++) if (!_hidden.contains(k)) k];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 12,
      children: [
        for (final k in visible) _beeTile(k),
      ],
    );
  }

  Widget _beeTile(int k) {
    final gone = _used.contains(k);
    final tile = _tileFace(it.tiles[k]);
    final phase = (k * .37) % 1.0;
    return AnimatedOpacity(
      opacity: gone ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: gone || _resolved || demo,
        child: AnimatedBuilder(
          animation: _bob,
          builder: (_, child) => Transform.translate(offset: Offset(0, sin((_bob.value + phase) * 2 * pi) * 4), child: child),
          child: Draggable<int>(
            data: k,
            onDragStarted: () => AudioManager.instance.sfx('tile_pick'),
            onDraggableCanceled: (_, _) => setState(() => _hover = null),
            feedback: Material(color: Colors.transparent, child: Transform.scale(scale: 1.12, child: tile)),
            childWhenDragging: Opacity(opacity: .25, child: tile),
            child: GestureDetector(onTap: () => _place(k), child: tile),
          ),
        ),
      ),
    );
  }

  Widget _tileFace(String letter) => SizedBox(
        width: 60,
        height: 80,
        child: Stack(alignment: Alignment.bottomCenter, children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF4D6), Color(0xFFF2C66D)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB9781C), width: 2.5),
              boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Text(letter, style: ts(28, color: C.ink)),
          ),
          const Positioned(top: 0, child: Text('🐝', style: TextStyle(fontSize: 22))),
        ]),
      );

  Widget _hatchOverlay() => AnimatedBuilder(
        animation: _hatch,
        builder: (_, _) {
          final t = Curves.elasticOut.transform(_hatch.value.clamp(0.0, 1.0));
          final rise = Curves.easeOut.transform(_hatch.value);
          return Stack(children: [
            for (var s = 0; s < 8; s++)
              Align(
                alignment: Alignment(cos(s * pi / 4) * .5 * rise, -.15 + sin(s * pi / 4) * .4 * rise),
                child: Opacity(opacity: (1 - _hatch.value).clamp(0.0, 1.0), child: const Text('✨', style: TextStyle(fontSize: 22))),
              ),
            Align(
              alignment: Alignment(0, -.1 - rise * .25),
              child: Transform.scale(
                scale: t,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ArtImage('prop.hive.baby_bee', fallback: const Text('🐝', style: TextStyle(fontSize: 64))),
                  if (!demo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Text('+1 baby bee!', style: ts(16, color: const Color(0xFF6B4200))),
                    ),
                ]),
              ),
            ),
          ]);
        },
      );
}

/// A pointy-top honeycomb cell: wax when empty, golden honey rising with a little wave when filled.
class _HexPainter extends CustomPainter {
  final double fill, wave;
  final bool locked, pale, hover;
  _HexPainter({required this.fill, required this.locked, required this.pale, required this.hover, required this.wave});

  Path _hex(Size s, double inset) {
    final cx = s.width / 2, cy = s.height / 2;
    final r = min(s.width / sqrt(3), s.height / 2) - inset;
    final p = Path();
    for (var k = 0; k < 6; k++) {
      final a = pi / 180 * (60 * k - 90);
      final pt = Offset(cx + r * cos(a), cy + r * sin(a));
      k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _hex(size, 1.5);
    final inner = _hex(size, size.width * .12);
    final wax = pale ? const Color(0xFFF3EFE6) : (locked ? const Color(0xFFCDEFC4) : const Color(0xFFFFE9A8));
    canvas.drawShadow(outer, const Color(0x66000000), 3, false);
    canvas.drawPath(outer, Paint()..color = hover ? const Color(0xFFFFD45C) : const Color(0xFFE8A92A));
    canvas.drawPath(inner, Paint()..color = wax);
    if (fill > 0) {
      canvas.save();
      canvas.clipPath(inner);
      final top = size.height * (1 - fill);
      final honey = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 4) {
        honey.lineTo(x, top + sin(x / size.width * 2 * pi + wave * 2 * pi) * 3 * (fill < 1 ? 1 : .4));
      }
      honey
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
          honey,
          Paint()
            ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFC93C), Color(0xFFE48A00)])
                .createShader(Offset.zero & size));
      canvas.drawCircle(Offset(size.width * .36, top + size.height * .2), size.width * .06, Paint()..color = Colors.white.withValues(alpha: .6 * fill));
      canvas.restore();
    }
    canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = pale ? 3 : 2
          ..color = pale ? const Color(0xFFE3A3A3) : (locked ? const Color(0xFF4CAF50) : const Color(0x88B9781C)));
  }

  @override
  bool shouldRepaint(_HexPainter o) => o.fill != fill || o.locked != locked || o.pale != pale || o.hover != hover || (fill > 0 && o.wave != wave);
}
