import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../core/audio.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/tts.dart';
import '../../data/strings.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../game_module.dart';

/// How long the fireflies hold the word, by step: 2 s → 0.6 s (GAME_DESIGN Lv 1–4).
int flashMs(int step) => step <= 2 ? 2000 : (step <= 4 ? 1500 : (step <= 7 ? 1000 : 600));

const bazaarStalls = [('☕', 'Chai stall'), ('📿', 'Bangle shop'), ('🪁', 'Kite shop'), ('🍬', 'Sweet shop'), ('🧵', 'Cloth stall'), ('🏮', 'Lamp shop'), ('🌸', 'Flower stall'), ('🥭', 'Mango cart')];

/// Game 8 · Word Flash — "Jugnu's Night Bazaar".
/// A firefly swarm spells the word for a blink, then scatters. The child taps the jar holding the same word
/// among look-alikes. "Flash again" is always free. Every catch lights a stall in the bazaar.
class WordFlashItem extends StatefulWidget {
  final GameCtx ctx;
  final int stallsLit; // persistent: words caught so far
  const WordFlashItem({super.key, required this.ctx, this.stallsLit = 0});
  @override
  State<WordFlashItem> createState() => _WordFlashItemState();
}

class _WordFlashItemState extends State<WordFlashItem> with SingleTickerProviderStateMixin {
  final _clock = Stopwatch();
  late final AnimationController _swarm = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  final List<String> _tags = [];
  final Set<int> _faded = {};
  final Map<int, int> _shake = {};
  bool _showing = false; // word formed in light
  bool _flashedOnce = false;
  int _attempts = 0;
  bool _resolved = false;
  int? _correctShown;
  bool _disposed = false;

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  bool get demo => widget.ctx.demo;
  String get word => it.options[it.correct].label;
  int get _ms => (flashMs(it.level) * (widget.ctx.scaffold ? 1.6 : 1)).round();

  @override
  void initState() {
    super.initState();
    if (widget.ctx.scaffold && it.options.length > 2) {
      _faded.add([for (var i = 0; i < it.options.length; i++) if (i != it.correct) i].first);
      widget.ctx.feedback(Str.t(lang, 'hint'), true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _flash());
  }

  @override
  void dispose() {
    _disposed = true;
    _swarm.dispose();
    super.dispose();
  }

  Future<void> _flash() async {
    if (_disposed || _showing) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (_disposed) return;
    AudioManager.instance.sfx('sparkle', volume: .5);
    setState(() {
      _showing = true;
    });
    await Future.delayed(Duration(milliseconds: _ms));
    if (_disposed) return;
    AudioManager.instance.sfx('whoosh', volume: .35);
    setState(() {
      _showing = false;
      _flashedOnce = true;
    });
    if (!_clock.isRunning) _clock.start(); // response time counts from the first scatter
    if (demo) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!_disposed) setState(() => _correctShown = it.correct);
    }
  }

  void _tap(int i) {
    if (_resolved || demo || !_flashedOnce || _showing || _faded.contains(i)) return;
    if (i == it.correct) {
      final first = _attempts == 0;
      final ms = _clock.elapsedMilliseconds;
      final tags = [..._tags];
      if (first && ms > Cfg.slowResponseMs) tags.add('Slow response');
      setState(() {
        _resolved = true;
        _correctShown = i;
      });
      Speaker.instance.speak(word, widget.ctx.pack.tts);
      AudioManager.instance.sfx('bell', volume: .6);
      widget.ctx.feedback(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
      _finish(ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: first, ms: ms, tags: tags), 1500);
      return;
    }
    _attempts++;
    final t = it.options[i].tag;
    if (t != null) _tags.add(t);
    AudioManager.instance.sfx('miss_soft');
    final canRetry = _attempts < 2 && (it.options.length - _faded.length - 1) > 1;
    setState(() {
      _shake[i] = (_shake[i] ?? 0) + 1;
      _faded.add(i);
      if (!canRetry) {
        _resolved = true;
        _correctShown = it.correct;
      }
    });
    if (canRetry) {
      widget.ctx.feedback('Look closely… let the fireflies show it again!', false);
      _flash();
    } else {
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      Speaker.instance.speak(word, widget.ctx.pack.tts);
      _finish(ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: false, ms: _clock.elapsedMilliseconds, tags: [..._tags]), 2400);
    }
  }

  void _finish(ItemResult r, int delayMs) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_disposed && !demo) widget.ctx.done(r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lit = widget.stallsLit + (_resolved && _attempts == 0 && !demo ? 1 : 0);
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(10, 4, 10, 6), child: _header(lit)),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(fit: StackFit.expand, children: [
              ArtImage('bg.flash.bazaar', fit: BoxFit.cover, fallback: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E1236), Color(0xFF2B1F55), Color(0xFF4A2A55)])))),
              Positioned(left: 0, right: 0, top: 6, child: _stalls(lit)),
              Positioned.fill(child: AnimatedBuilder(animation: _swarm, builder: (_, _) => CustomPaint(painter: _SwarmPainter(_swarm.value, _showing)))),
              Center(
                child: AnimatedOpacity(
                  opacity: _showing ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(word, style: ts(56, color: const Color(0xFFFFF59D)).copyWith(shadows: const [Shadow(color: Color(0xFFFFD45C), blurRadius: 24), Shadow(color: Color(0xFFB8FF6A), blurRadius: 40)])),
                    ),
                  ),
                ),
              ),
              Positioned(left: 0, right: 0, bottom: 12, child: _jars()),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _header(int lit) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          SizedBox(width: 56, height: 56, child: ArtImage('char.jugnu.happy', fallback: const Center(child: Text('✨', style: TextStyle(fontSize: 38))))),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_showing ? 'Look! Remember it…' : (_flashedOnce ? 'Which jar has the same word?' : 'Watch the fireflies!'), style: ts(18, color: C.ink)),
              if (!demo) Text('🏮 $lit ${lit == 1 ? 'stall' : 'stalls'} lit in the bazaar', style: ts(12, color: C.inkSoft, w: FontWeight.w600)),
            ]),
          ),
          RoundIconButton(
            icon: Icons.flash_on_rounded,
            label: 'Flash again',
            color: C.gold,
            size: 44,
            onTap: demo || _resolved || _showing ? () {} : _flash,
          ),
        ]),
      );

  Widget _stalls(int lit) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (var k = 0; k < bazaarStalls.length; k++)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: k < lit ? 1 : .22, // stalls light up one by one and stay lit
            child: Text(bazaarStalls[k].$1, style: const TextStyle(fontSize: 24)),
          ),
      ]);

  Widget _jars() => Row(children: [
        for (var i = 0; i < it.options.length; i++)
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _faded.contains(i) ? .3 : (_flashedOnce && !_showing ? 1 : .55),
              child: TweenAnimationBuilder<double>(
                key: ValueKey('j$i${_shake[i] ?? 0}'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                builder: (_, t, child) => Transform.translate(offset: Offset((_shake[i] ?? 0) == 0 ? 0 : sin(t * pi * 5) * 7 * (1 - t), 0), child: child),
                child: GestureDetector(onTap: () => _tap(i), child: _jar(i)),
              ),
            ),
          ),
      ]);

  Widget _jar(int i) {
    final right = _correctShown == i;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 10, decoration: BoxDecoration(color: const Color(0xFF8B5A2B), borderRadius: BorderRadius.circular(4))),
      Container(
        height: 96,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: right ? const Color(0xCCFFF59D) : const Color(0x55BFF3FF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18), bottom: Radius.circular(26)),
          border: Border.all(color: right ? const Color(0xFFFFD45C) : Colors.white70, width: right ? 4 : 2.5),
          boxShadow: right ? const [BoxShadow(color: Color(0xAAFFE07A), blurRadius: 22)] : const [],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(it.options[i].label, style: ts(24, color: right ? C.ink : Colors.white))),
        ),
      ),
    ]);
  }
}

/// Fireflies: drifting softly, then gathering into a bright band while the word shows.
class _SwarmPainter extends CustomPainter {
  final double t;
  final bool gathered;
  _SwarmPainter(this.t, this.gathered);
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 46; i++) {
      final r = Random(i * 7 + 1);
      final home = Offset(r.nextDouble() * size.width, size.height * (.15 + r.nextDouble() * .55));
      final wander = Offset(sin((t + r.nextDouble()) * 2 * pi) * 26, cos((t * 1.3 + r.nextDouble()) * 2 * pi) * 18);
      final band = Offset(size.width * (.1 + r.nextDouble() * .8), size.height * .45 + (r.nextDouble() - .5) * 70);
      final p = gathered ? band + wander * .2 : home + wander;
      final a = .4 + .5 * sin((t * 3 + r.nextDouble()) * pi).abs();
      canvas.drawCircle(p, 8, Paint()..color = const Color(0xFFDFFF7A).withValues(alpha: a * .3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(p, 2.4, Paint()..color = const Color(0xFFFFFDE0).withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_SwarmPainter o) => true;
}
