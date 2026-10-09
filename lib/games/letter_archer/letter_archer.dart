import 'dart:async';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../core/audio.dart';
import '../../core/theme.dart';
import '../../core/tts.dart';
import '../../data/strings.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../game_module.dart';
import 'archery_world.dart';

/// Hits in a row during one quest; 3 first-try hits light the Golden Lantern (fireworks with the child's name).
class ArcheryStreak {
  static int hits = 0;
  static void reset() => hits = 0;
}

/// Game 3 · Letter Archer — "The Festival of Flying Lanterns" (built with the Flame engine).
/// A sound plays; paper lanterns carry letters. Pull back the bow and let go (or tap a lantern for an
/// auto-aimed arrow). The right lantern lights up and floats into the festival sky.
class LetterArcherItem extends StatefulWidget {
  final GameCtx ctx;
  final int lanternsLit; // persistent: lanterns already floating in the valley sky
  final String explorerName;
  const LetterArcherItem({super.key, required this.ctx, this.lanternsLit = 0, this.explorerName = ''});
  @override
  State<LetterArcherItem> createState() => _LetterArcherItemState();
}

class _LetterArcherItemState extends State<LetterArcherItem> {
  final _clock = Stopwatch()..start();
  late final ArcheryWorld world;
  late final _ArcheryGame game;
  final List<String> _tags = [];
  int _attempts = 0;
  bool _resolved = false;
  bool _disposed = false;

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  bool get demo => widget.ctx.demo;
  void _say(String t) => Speaker.instance.speak(t, widget.ctx.pack.tts);

  @override
  void initState() {
    super.initState();
    if (demo) ArcheryStreak.reset();
    final step = it.level;
    final scaffold = widget.ctx.scaffold;
    world = ArcheryWorld(
      lanterns: it.options.length,
      drift: scaffold || step <= 2 ? 0 : (step <= 6 ? 1 : 2),
      aimGuide: scaffold || step <= 2,
      onHit: _onHit,
    );
    if (scaffold && it.options.length > 2) {
      world.dimmed.add([for (var i = 0; i < it.options.length; i++) if (i != it.correct) i].first);
      widget.ctx.feedback(Str.t(lang, 'hint'), true);
    }
    game = _ArcheryGame(world, [for (final o in it.options) o.label], widget.lanternsLit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (demo) {
        _runDemo();
      } else {
        _say(it.say);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _runDemo() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (_disposed) return;
    world.autoFire(it.correct);
    AudioManager.instance.sfx('whoosh', volume: .4);
  }

  void _onHit(int i) {
    if (_resolved) return;
    if (i == it.correct) {
      final first = _attempts == 0;
      _resolved = true;
      world.locked = true;
      world.markLit(i);
      AudioManager.instance.sfx('pop', volume: .7);
      if (demo) return;
      _say(it.say);
      ArcheryStreak.hits = first ? ArcheryStreak.hits + 1 : 0;
      final golden = ArcheryStreak.hits >= 3;
      widget.ctx.feedback(golden ? 'The Golden Lantern! ✨' : (first ? Str.good(lang) : Str.t(lang, 'good3')), true);
      if (golden) {
        ArcheryStreak.reset();
        world.startFireworks(widget.explorerName.isEmpty ? 'WOW!' : widget.explorerName.toUpperCase());
        AudioManager.instance.sfx('reward_fanfare', volume: .6);
      }
      setState(() {});
      _finish(first, golden ? 3200 : 1600);
      return;
    }
    if (demo) return;
    _attempts++;
    ArcheryStreak.reset();
    final tag = it.options[i].tag;
    if (tag != null) _tags.add(tag);
    world.markWrong(i);
    AudioManager.instance.sfx('thud_soft', volume: .7);
    final left = it.options.length - world.dimmed.length;
    if (_attempts < 2 && left > 1) {
      widget.ctx.feedback(it.hint.isEmpty ? Str.t(lang, 'almost') : it.hint, false);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!_disposed) _say(it.say);
      });
    } else {
      _resolved = true;
      world.locked = true;
      world.glow = it.correct;
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      _say(it.say);
      _finish(false, 2400);
    }
    setState(() {});
  }

  void _finish(bool firstTry, int delayMs) {
    final r = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: firstTry, ms: _clock.elapsedMilliseconds, tags: [..._tags]);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_disposed && !demo) widget.ctx.done(r);
    });
  }

  void _shotSound() => AudioManager.instance.sfx('whoosh', volume: .5);

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
              ArtImage('bg.archer.sky', fit: BoxFit.cover, fallback: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B1F4B), Color(0xFF4B3A7A), Color(0xFF8E5A8C)])))),
              LayoutBuilder(builder: (context, box) {
                world.size = Size(box.maxWidth, box.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: demo
                      ? null
                      : (d) {
                          final i = world.lanternAtPoint(d.localPosition);
                          if (i != null && !world.dimmed.contains(i) && world.autoFire(i)) _shotSound();
                        },
                  onPanStart: demo ? null : (_) => world.startAim(),
                  onPanUpdate: demo ? null : (d) => world.dragAim(d.delta),
                  onPanEnd: demo
                      ? null
                      : (_) {
                          if (world.release()) _shotSound();
                        },
                  child: GameWidget(game: game),
                );
              }),
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
          SizedBox(width: 58, height: 64, child: ArtImage('char.arya.happy', fallback: const Center(child: Text('🏹', style: TextStyle(fontSize: 40))))),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.prompt, style: ts(18, color: C.ink)),
              const SizedBox(height: 4),
              Row(children: [
                for (var k = 0; k < 3; k++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Opacity(opacity: k < ArcheryStreak.hits ? 1 : .25, child: const Text('🏮', style: TextStyle(fontSize: 16))),
                  ),
                const SizedBox(width: 6),
                if (!demo) Text('${widget.lanternsLit} in the sky', style: ts(12, color: C.inkSoft, w: FontWeight.w600)),
              ]),
            ]),
          ),
          RoundIconButton(icon: Icons.volume_up_rounded, label: 'Hear the sound', color: C.gold, size: 44, onTap: demo ? () {} : () => _say(it.say)),
        ]),
      );
}

/// Flame game: advances the world every frame and paints it.
class _ArcheryGame extends FlameGame {
  final ArcheryWorld w;
  final List<String> labels;
  final int skyLanterns;
  _ArcheryGame(this.w, this.labels, this.skyLanterns);

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void update(double dt) {
    super.update(dt);
    w.update(min(dt, 1 / 30));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _paintSky(canvas);
    _paintGuide(canvas);
    for (var i = 0; i < w.lanterns; i++) {
      _paintLantern(canvas, i);
    }
    _paintBow(canvas);
    _paintArrow(canvas);
    for (final s in w.sparks) {
      canvas.drawCircle(s.p, 3.2, Paint()..color = s.color.withValues(alpha: (s.life / s.maxLife).clamp(0.0, 1.0)));
    }
    if (w.fireworksText != null) _paintName(canvas);
  }

  /// Lanterns the child already lit on earlier days float high in the sky.
  void _paintSky(Canvas canvas) {
    final n = min(skyLanterns, 40);
    for (var k = 0; k < n; k++) {
      final r = Random(k * 13 + 1);
      final x = r.nextDouble() * w.size.width;
      final y = w.size.height * .05 + r.nextDouble() * w.size.height * .5 + sin(w.t * .4 + k) * 4;
      final glow = .5 + .3 * sin(w.t * 1.3 + k);
      canvas.drawCircle(Offset(x, y), 7, Paint()..color = const Color(0xFFFFB347).withValues(alpha: glow * .35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 6, height: 8), const Radius.circular(2)), Paint()..color = const Color(0xFFFFC56B).withValues(alpha: glow));
    }
  }

  void _paintGuide(Canvas canvas) {
    if (!w.aimGuide && !w.aiming) return;
    final pts = w.guide();
    for (var k = 0; k < pts.length; k++) {
      canvas.drawCircle(pts[k], 3.5, Paint()..color = Colors.white.withValues(alpha: (w.aimGuide ? .8 : .35) * (1 - k / pts.length)));
    }
  }

  void _paintLantern(Canvas canvas, int i) {
    final c = w.lanternAt(i);
    final r = w.radius;
    final lit = w.lit.contains(i);
    final dim = w.dimmed.contains(i) && !lit;
    final wob = w.wobble[i] ?? 0;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(sin(w.t * 2 + i) * .04 + sin(wob * 30) * wob * .3);
    final body = Rect.fromCenter(center: Offset.zero, width: r * 1.7, height: r * 2.0);
    final glow = lit || w.glow == i;
    if (glow) {
      canvas.drawCircle(Offset.zero, r * 1.8, Paint()..color = const Color(0xFFFFC447).withValues(alpha: .45 + .15 * sin(w.t * 5))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
    }
    // string up to the sky
    canvas.drawLine(Offset(0, -r * 1.05), Offset(0, -r * 1.6), Paint()..color = const Color(0x99FFFFFF)..strokeWidth = 1.5);
    final colors = lit ? const [Color(0xFFFFE07A), Color(0xFFFF8A3D)] : (dim ? const [Color(0xFF4A4E6A), Color(0xFF34364D)] : const [Color(0xFFB0465A), Color(0xFF6E2B57)]);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(r * .7)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors).createShader(body),
    );
    // ribs and caps
    final rib = Paint()
      ..color = Colors.black.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final f in [-.45, 0.0, .45]) {
      canvas.drawLine(Offset(body.width * f * .9, body.top + 6), Offset(body.width * f * .9, body.bottom - 6), rib);
    }
    final cap = Paint()..color = const Color(0xFF3B2A1A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, body.top), width: r * .9, height: r * .22), const Radius.circular(4)), cap);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, body.bottom), width: r * .9, height: r * .22), const Radius.circular(4)), cap);
    canvas.drawLine(Offset(0, body.bottom + 2), Offset(0, body.bottom + r * .45), Paint()..color = const Color(0xFFFFD45C)..strokeWidth = 3);
    // the letter
    final tp = TextPainter(
      text: TextSpan(text: labels[i], style: TextStyle(fontFamily: 'Fredoka', fontSize: r * (labels[i].length > 2 ? .75 : .95), fontWeight: FontWeight.w600, color: lit ? const Color(0xFF5A2A00) : (dim ? const Color(0x88FFFFFF) : Colors.white))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _paintBow(Canvas canvas) {
    final b = w.bow;
    final r = 46.0;
    final wood = Paint()
      ..color = const Color(0xFFD9A441)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: b + const Offset(0, 22), radius: r);
    canvas.drawArc(rect, pi * 1.08, pi * .84, false, wood);
    final tipL = b + Offset(-r * cos(pi * .08), 22 - r * sin(pi * .08) - 0);
    final tipR = b + Offset(r * cos(pi * .08), 22 - r * sin(pi * .08) - 0);
    final n = w.nock + const Offset(0, 0);
    final string = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..strokeWidth = 2;
    canvas.drawLine(tipL, n, string);
    canvas.drawLine(tipR, n, string);
    if (w.arrow == null && !w.locked) _arrowAt(canvas, n, w.pull.distance < 1 ? const Offset(0, -1) : -w.pull / w.pull.distance);
  }

  void _paintArrow(Canvas canvas) {
    final a = w.arrow;
    if (a == null) return;
    final dir = w.vel / w.vel.distance;
    for (var k = 1; k <= 6; k++) {
      canvas.drawCircle(a - dir * (k * 9.0), 3.5 - k * .4, Paint()..color = const Color(0xFFFFE9A0).withValues(alpha: .5 - k * .07));
    }
    _arrowAt(canvas, a, dir);
  }

  void _arrowAt(Canvas canvas, Offset tail, Offset dir) {
    final tip = tail + dir * 52;
    canvas.drawLine(tail, tip, Paint()
      ..color = const Color(0xFF8B5A2B)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    final side = Offset(-dir.dy, dir.dx);
    final head = Path()
      ..moveTo(tip.dx + dir.dx * 12, tip.dy + dir.dy * 12)
      ..lineTo(tip.dx + side.dx * 7, tip.dy + side.dy * 7)
      ..lineTo(tip.dx - side.dx * 7, tip.dy - side.dy * 7)
      ..close();
    canvas.drawPath(head, Paint()..color = const Color(0xFFFFD45C));
    final f = Paint()..color = const Color(0xFFE0568A);
    canvas.drawLine(tail, tail - dir * 4 + side * 8, f..strokeWidth = 3);
    canvas.drawLine(tail, tail - dir * 4 - side * 8, f);
  }

  void _paintName(Canvas canvas) {
    final t = w.fireworksT;
    final a = (t < .3 ? t / .3 : (t > 2.6 ? max(0.0, 1 - (t - 2.6) / .5) : 1.0)).clamp(0.0, 1.0);
    final tp = TextPainter(
      text: TextSpan(
        text: w.fireworksText,
        style: TextStyle(fontFamily: 'Fredoka', fontSize: min(56, w.size.width / max(4, w.fireworksText!.length) * 1.4), fontWeight: FontWeight.w700, color: const Color(0xFFFFD45C).withValues(alpha: a), shadows: [Shadow(color: const Color(0xFFFF8A3D).withValues(alpha: a), blurRadius: 18)]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w.size.width - tp.width) / 2, w.size.height * .42 - tp.height / 2 - t * 8));
  }
}
