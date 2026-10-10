import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/audio.dart';
import 'props.dart';

/// A touch-reactive living background (map sea + landing sky).
///
/// One ticker drives a single painter (no blur filters, cached emoji, ~60 shapes), so it stays smooth. Taps never steal
/// from buttons: [AmbientTapLayer] uses raw pointer events, so the island under the finger still opens as before.
class AmbientController extends ChangeNotifier {
  AmbientController(TickerProvider vsync) {
    _ticker = vsync.createTicker((d) {
      time = d.inMicroseconds / 1e6;
      _bursts.removeWhere((b) => time - b.t0 > b.life);
      notifyListeners();
    })..start();
  }
  late final Ticker _ticker;
  double time = 0;
  final List<_Burst> _bursts = [];
  final List<_Hit> hits = []; // where the tappable critters are right now (filled by the painter)
  double _lastSfx = -9;

  void burst(Offset p, {String kind = 'ripple', Color? color, int? n}) => _bursts.add(_Burst(p, time, kind, color ?? Colors.white, n ?? 8));

  void sfx(String id, {double volume = .4}) {
    if (time - _lastSfx < .22) return;
    _lastSfx = time;
    AudioManager.instance.sfx(id, volume: volume);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _Burst {
  final Offset p;
  final double t0;
  final String kind; // ripple | stars | confetti | firework | puff
  final Color color;
  final int n;
  double get life => kind == 'firework' ? 1.8 : (kind == 'confetti' ? 1.5 : 1.1);
  const _Burst(this.p, this.t0, this.kind, this.color, this.n);
}

class _Hit {
  final Offset c;
  final double r;
  final String id;
  const _Hit(this.c, this.r, this.id);
}

/// Raw-pointer tap detection: a short touch that barely moves is a "tap".
class AmbientTapLayer extends StatelessWidget {
  final void Function(Offset) onTap;
  const AmbientTapLayer({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    Offset? down;
    var t0 = 0;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        down = e.localPosition;
        t0 = DateTime.now().millisecondsSinceEpoch;
      },
      onPointerUp: (e) {
        final d = down;
        down = null;
        if (d != null && (e.localPosition - d).distance < 14 && DateTime.now().millisecondsSinceEpoch - t0 < 450) onTap(e.localPosition);
      },
      child: const SizedBox.expand(),
    );
  }
}

final _glyphs = <String, TextPainter>{};
TextPainter _glyph(String ch, double size) => _glyphs.putIfAbsent('$ch${size.round()}', () => TextPainter(text: TextSpan(text: ch, style: TextStyle(fontSize: size)), textDirection: TextDirection.ltr)..layout());

void _drawGlyph(Canvas c, String ch, Offset p, double size, {double rot = 0, double alpha = 1, bool flip = false}) {
  final tp = _glyph(ch, size);
  c.save();
  c.translate(p.dx, p.dy);
  if (rot != 0) c.rotate(rot);
  if (flip) c.scale(-1, 1);
  if (alpha < 1) {
    c.saveLayer(Rect.fromCenter(center: Offset.zero, width: size * 2, height: size * 2), Paint()..color = Colors.white.withValues(alpha: alpha));
    tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
    c.restore();
  } else {
    tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
  }
  c.restore();
}

void _paintBursts(Canvas c, AmbientController a) {
  for (final b in a._bursts) {
    final k = ((a.time - b.t0) / b.life).clamp(0.0, 1.0);
    final fade = 1 - k;
    switch (b.kind) {
      case 'ripple':
        for (var i = 0; i < 3; i++) {
          final kk = (k - i * .12).clamp(0.0, 1.0);
          if (kk <= 0) continue;
          c.drawCircle(b.p, 10 + kk * 70, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * (1 - kk)
            ..color = Colors.white.withValues(alpha: .7 * (1 - kk)));
        }
        for (var i = 0; i < b.n; i++) {
          final a2 = i / b.n * 2 * pi;
          final r = 20 + k * 46;
          Props.sparkle(c, b.p.dx + cos(a2) * r, b.p.dy + sin(a2) * r * .6 - k * 10, 3 * fade + 1, color: b.color.withValues(alpha: fade));
        }
      case 'stars':
        for (var i = 0; i < b.n; i++) {
          final a2 = i / b.n * 2 * pi + k;
          final r = 12 + k * 60;
          Props.sparkle(c, b.p.dx + cos(a2) * r, b.p.dy + sin(a2) * r, 5 * fade + 1.5, color: b.color.withValues(alpha: fade));
        }
      case 'confetti':
        const cols = [Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF6BCB77), Color(0xFF4D96FF), Color(0xFFFF9EC4)];
        for (var i = 0; i < 26; i++) {
          final a2 = i * 2.4;
          final v = 40 + (i % 5) * 22;
          final x = b.p.dx + cos(a2) * v * k * 1.6;
          final y = b.p.dy + sin(a2) * v * k - 30 * k + 120 * k * k;
          c.save();
          c.translate(x, y);
          c.rotate(k * 9 + i);
          c.drawRect(const Rect.fromLTWH(-4, -2.5, 8, 5), Paint()..color = cols[i % 5].withValues(alpha: fade));
          c.restore();
        }
      case 'firework':
        for (var i = 0; i < 18; i++) {
          final a2 = i / 18 * 2 * pi;
          final r = 90 * Curves.easeOutCubic.transform(k);
          final p = Offset(b.p.dx + cos(a2) * r, b.p.dy + sin(a2) * r + 40 * k * k);
          c.drawCircle(p, 3.4 * fade + .6, Paint()..color = b.color.withValues(alpha: fade));
          c.drawCircle(Offset(b.p.dx + cos(a2) * r * .6, b.p.dy + sin(a2) * r * .6 + 24 * k * k), 2 * fade, Paint()..color = Colors.white.withValues(alpha: fade * .9));
        }
      case 'puff':
        for (var i = 0; i < 6; i++) {
          final a2 = i / 6 * 2 * pi;
          c.drawCircle(Offset(b.p.dx + cos(a2) * 22 * k, b.p.dy + sin(a2) * 22 * k - 8 * k), 9 * (1 - k * .5), Paint()..color = Colors.white.withValues(alpha: .8 * fade));
        }
    }
  }
}

// ======================================================================================================================
// MAP: a bright tropical sea
// ======================================================================================================================

class SeaBackground extends StatelessWidget {
  final AmbientController a;
  const SeaBackground(this.a, {super.key});
  @override
  Widget build(BuildContext context) => RepaintBoundary(child: CustomPaint(painter: _SeaPainter(a), size: Size.infinite));
}

/// Wires the taps of the sea: critters react with a sound, empty water makes a ripple.
void seaTap(AmbientController a, Offset p) {
  for (final h in a.hits) {
    if ((h.c - p).distance < h.r) {
      switch (h.id) {
        case 'dolphin':
          a.burst(h.c, kind: 'ripple', color: const Color(0xFFBFEFFF));
          a.sfx('bubble', volume: .55);
        case 'balloon':
          a.burst(h.c, kind: 'confetti');
          a.sfx('pop', volume: .55);
        case 'bird':
          a.burst(h.c, kind: 'puff');
          a.sfx('bird_1', volume: .5);
        case 'boat':
          a.burst(h.c, kind: 'stars', color: const Color(0xFFFFE17A));
          a.sfx('market_bell', volume: .4);
        default:
          a.burst(h.c, kind: 'stars', color: Colors.white);
          a.sfx('sparkle', volume: .4);
      }
      return;
    }
  }
  a.burst(p, kind: 'ripple');
  a.sfx('bubble', volume: .3);
}

class _SeaPainter extends CustomPainter {
  final AmbientController a;
  _SeaPainter(this.a) : super(repaint: a);

  static final _crest = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = const Color(0x40FFFFFF);

  @override
  void paint(Canvas c, Size s) {
    final t = a.time, w = s.width, h = s.height;
    final rect = Offset.zero & s;
    // water: bright sky-blue at the top, turquoise lagoon in the middle, deep blue at the bottom
    c.drawRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FE0FF), Color(0xFF3CC4F2), Color(0xFF1FA6E8), Color(0xFF1480D6)], stops: [0, .3, .65, 1]).createShader(rect));
    // lagoon patches (slowly drifting) in warm turquoise / mint
    for (var i = 0; i < 4; i++) {
      final cx = w * (.2 + .6 * ((i * .37 + t * .01) % 1.0)), cy = h * (.18 + i * .22);
      final r = Rect.fromCenter(center: Offset(cx, cy), width: w * 1.1, height: h * .2);
      c.drawOval(r, Paint()..shader = RadialGradient(colors: [(i.isEven ? const Color(0xFF6BF2D8) : const Color(0xFF9BE8FF)).withValues(alpha: .34), Colors.transparent]).createShader(r));
    }
    // a rainbow over the islands and a warm peach glow in the top-left corner
    const rb = [Color(0xFFFF6B6B), Color(0xFFFFA94D), Color(0xFFFFE066), Color(0xFF8CE99A), Color(0xFF74C0FC), Color(0xFFB197FC)];
    for (var i = 0; i < rb.length; i++) {
      c.drawArc(Rect.fromCircle(center: Offset(w * .42, h * .36), radius: w * (.78 - i * .038)), pi * 1.08, pi * .84, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .04
        ..color = rb[i].withValues(alpha: .24 + .05 * sin(t * .6 + i)));
    }
    final peach = Rect.fromCircle(center: Offset(w * .05, h * .02), radius: w * .6);
    c.drawCircle(peach.center, peach.width / 2, Paint()..shader = RadialGradient(colors: [const Color(0xFFFFC9A8).withValues(alpha: .5), const Color(0x00FFC9A8)]).createShader(peach));
    // sun glow + soft rays
    final sun = Offset(w * .84, h * .06);
    c.drawCircle(sun, w * .5, Paint()..shader = RadialGradient(colors: [const Color(0xFFFFF3B0).withValues(alpha: .65), const Color(0x00FFF3B0)]).createShader(Rect.fromCircle(center: sun, radius: w * .5)));
    for (var i = 0; i < 5; i++) {
      final ang = pi * (.62 + i * .07) + sin(t * .15 + i) * .02;
      final path = Path()
        ..moveTo(sun.dx, sun.dy)
        ..lineTo(sun.dx + cos(ang - .03) * h, sun.dy + sin(ang - .03) * h)
        ..lineTo(sun.dx + cos(ang + .03) * h, sun.dy + sin(ang + .03) * h)
        ..close();
      c.drawPath(path, Paint()..color = Colors.white.withValues(alpha: .06));
    }
    // wave crests that scroll sideways
    for (var row = 0; row < 14; row++) {
      final y0 = h * (.04 + row * .07);
      _crest.strokeWidth = 1.6 + (row % 3) * .8;
      final dir = row.isEven ? 1.0 : -1.0;
      final sp = 6 + (row % 4) * 3;
      for (var k = 0; k < 4; k++) {
        final x = ((w * (k / 4 + .1 * (row % 3)) + dir * t * sp) % (w + 80)) - 40;
        final p = Path()
          ..moveTo(x - 22, y0 + sin(t * 1.2 + row) * 2)
          ..quadraticBezierTo(x - 11, y0 - 6, x, y0 + sin(t * 1.2 + row) * 2)
          ..quadraticBezierTo(x + 11, y0 + 6, x + 22, y0 + sin(t * 1.2 + row) * 2);
        c.drawPath(p, _crest);
      }
    }
    // twinkling sunlight on the water
    for (var i = 0; i < 34; i++) {
      final tw = (sin(t * 2.2 + i * 1.7) + 1) / 2;
      if (tw < .55) continue;
      Props.sparkle(c, w * ((i * 53 % 97) / 97), h * ((i * 37 % 89) / 89), 1.6 + tw * 2.2, color: Colors.white.withValues(alpha: .35 + tw * .5));
    }
    // pink and golden petals drifting down across the whole sea
    for (var i = 0; i < 14; i++) {
      final k = (t * (.016 + (i % 4) * .004) + i * .071) % 1.0;
      final x = w * (((i * 47) % 100) / 100) + sin(t * .8 + i * 1.3) * 26;
      c.save();
      c.translate(x, h * (k * 1.1 - .05));
      c.rotate(t * 1.2 + i);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: 11, height: 6), Paint()..color = (i.isEven ? const Color(0xFFFFB6D1) : const Color(0xFFFFE08A)).withValues(alpha: .85));
      c.restore();
    }
    // bubbles drifting up
    for (var i = 0; i < 12; i++) {
      final k = (t * .05 + i * .083) % 1.0;
      c.drawCircle(Offset(w * ((i * 61 % 83) / 83) + sin(t + i) * 8, h * (1 - k)), 2.5 + (i % 3) * 1.5, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: .45 * (1 - (k - .5).abs() * 1.5).clamp(0.0, 1.0)));
    }
    // clouds across the top part of the screen
    for (var i = 0; i < 5; i++) {
      final x = (((t * (.012 + i * .004)) + i * .23) % 1.4 - .2) * w;
      Props.cloud(c, x, h * (.03 + i * .09), w * (.17 + (i % 3) * .05), alpha: .78, color: i.isEven ? Colors.white : const Color(0xFFFFEAF4));
    }

    a.hits.clear();
    // sailboats
    for (var i = 0; i < 2; i++) {
      final sp = .006 + i * .004;
      final x = (((t * sp) + i * .55) % 1.5 - .25) * w;
      final y = h * (.30 + i * .31) + sin(t * .9 + i * 2) * 5;
      c.drawOval(Rect.fromCenter(center: Offset(x, y + 22), width: 62, height: 8), Paint()..color = Colors.white.withValues(alpha: .28));
      _drawGlyph(c, '⛵', Offset(x, y), 56, rot: sin(t * .9 + i * 2) * .06, flip: i == 1);
      a.hits.add(_Hit(Offset(x, y), 42, 'boat'));
    }
    // leaping dolphin (every ~8 s, a 1.6 s arc)
    for (var i = 0; i < 2; i++) {
      final period = 8.0 + i * 3.1;
      final k = ((t + i * 4.2) % period) / 1.7;
      if (k <= 1) {
        final x0 = w * (.18 + .55 * ((((t + i * 4.2) ~/ period) * .37 + i * .3) % 1.0));
        final x = x0 + k * w * .22 * (i.isEven ? 1 : -1);
        final y = h * (.42 + i * .27) - sin(k * pi) * 74;
        _drawGlyph(c, '🐬', Offset(x, y), 52, rot: (i.isEven ? 1 : -1) * (cos(k * pi) * -.7), flip: !i.isEven);
        a.hits.add(_Hit(Offset(x, y), 38, 'dolphin'));
        if (k < .14 || k > .86) {
          final rr = (k < .5 ? k : 1 - k) / .14;
          c.drawCircle(Offset(x0 + (k < .5 ? 0 : w * .22 * (i.isEven ? 1 : -1)), h * (.42 + i * .27) + 16), 8 + rr * 26, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white.withValues(alpha: .6 * (1 - rr * .8)));
        }
      }
    }
    // little fish swimming just under the surface
    for (var i = 0; i < 5; i++) {
      final dir = i.isEven ? 1.0 : -1.0;
      final x = (((t * .02 * (1 + i * .2)) * dir + i * .31) % 1.4 + 1.4) % 1.4 * w - w * .2;
      final y = h * (.12 + i * .17) + sin(t * 2 + i) * 4;
      _drawGlyph(c, i % 2 == 0 ? '🐠' : '🐟', Offset(x, y), 26, alpha: .85, flip: dir < 0);
    }
    // gulls
    for (var i = 0; i < 3; i++) {
      final x = (((t * (.03 + i * .008)) + i * .4) % 1.4 - .2) * w;
      final y = h * (.05 + i * .06) + sin(t * 1.5 + i) * 8;
      final flap = sin(t * 7 + i * 2) * 6;
      final p = Path()
        ..moveTo(x - 10, y - flap)
        ..quadraticBezierTo(x - 4, y - 7, x, y)
        ..quadraticBezierTo(x + 4, y - 7, x + 10, y - flap);
      c.drawPath(p, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white);
      a.hits.add(_Hit(Offset(x, y), 26, 'bird'));
    }
    // a hot-air balloon rising and drifting
    final bk = (t * .012) % 1.0;
    final bp = Offset(w * (.2 + .6 * (.5 + .5 * sin(t * .13))), h * (1.0 - bk * 1.15));
    _drawGlyph(c, '🎈', bp, 54, rot: sin(t * .8) * .1);
    a.hits.add(_Hit(bp, 42, 'balloon'));

    _paintBursts(c, a);
  }

  @override
  bool shouldRepaint(_SeaPainter o) => false; // repaints through the controller
}

// ======================================================================================================================
// LANDING: sky critters, butterflies and fireworks over the hero scene
// ======================================================================================================================

class SkyAmbience extends StatelessWidget {
  final AmbientController a;
  const SkyAmbience(this.a, {super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _SkyPainter(a), size: Size.infinite)));
}

/// Landing taps: critters react, anywhere else a firework of stars.
void skyTap(AmbientController a, Offset p) {
  for (final h in a.hits) {
    if ((h.c - p).distance < h.r) {
      switch (h.id) {
        case 'balloon':
          a.burst(h.c, kind: 'confetti');
          a.sfx('pop', volume: .6);
        case 'bird':
          a.burst(h.c, kind: 'puff');
          a.sfx(['bird_1', 'bird_2'][Random().nextInt(2)], volume: .6);
        case 'butterfly':
          a.burst(h.c, kind: 'stars', color: const Color(0xFFFF9EC4));
          a.sfx('sparkle', volume: .5);
        default:
          a.burst(h.c, kind: 'firework', color: const Color(0xFFFFD34D));
          a.sfx('magic', volume: .5);
      }
      return;
    }
  }
  const cols = [Color(0xFFFFD34D), Color(0xFFFF6FA5), Color(0xFF7FE0FF), Color(0xFFB8FF6A)];
  a.burst(p, kind: 'firework', color: cols[Random().nextInt(cols.length)]);
  a.sfx('sparkle', volume: .45);
}

class _SkyPainter extends CustomPainter {
  final AmbientController a;
  _SkyPainter(this.a) : super(repaint: a);

  @override
  void paint(Canvas c, Size s) {
    final t = a.time, w = s.width, h = s.height;
    a.hits.clear();
    // a soft rainbow behind the castle
    final centre = Offset(w * .5, h * .60);
    const bands = [Color(0xFFFF6B6B), Color(0xFFFFA94D), Color(0xFFFFE066), Color(0xFF8CE99A), Color(0xFF74C0FC), Color(0xFFB197FC)];
    for (var i = 0; i < bands.length; i++) {
      c.drawArc(Rect.fromCircle(center: centre, radius: w * (.52 - i * .028)), pi, pi, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .03
        ..color = bands[i].withValues(alpha: .34 + .06 * sin(t * .8 + i)));
    }
    // hot-air balloons floating up
    for (var i = 0; i < 3; i++) {
      final k = (t * (.011 + i * .003) + i * .33) % 1.0;
      final p = Offset(w * (.15 + i * .33) + sin(t * .7 + i * 2) * 14, h * (.78 - k * .72));
      _drawGlyph(c, '🎈', p, 34 + i * 4, rot: sin(t + i) * .1);
      a.hits.add(_Hit(p, 34, 'balloon'));
    }
    // birds
    for (var i = 0; i < 4; i++) {
      final x = (((t * (.045 + i * .01)) + i * .31) % 1.4 - .2) * w;
      final y = h * (.12 + i * .045) + sin(t * 1.3 + i) * 10;
      final flap = sin(t * 8 + i * 2) * 6;
      final p = Path()
        ..moveTo(x - 11, y - flap)
        ..quadraticBezierTo(x - 5, y - 8, x, y)
        ..quadraticBezierTo(x + 5, y - 8, x + 11, y - flap);
      c.drawPath(p, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3B2A8F));
      a.hits.add(_Hit(Offset(x, y), 28, 'bird'));
    }
    // butterflies fluttering over the flowers
    for (var i = 0; i < 4; i++) {
      final bx = w * (i.isEven ? .14 : .84) + sin(t * .9 + i * 1.9) * w * .1;
      final by = h * (.80 + i * .025) + cos(t * 1.4 + i) * 16;
      _drawGlyph(c, '🦋', Offset(bx, by), 24, rot: sin(t * 6 + i) * .25);
      a.hits.add(_Hit(Offset(bx, by), 28, 'butterfly'));
    }
    // twinkling stars and sparkles drifting around the castle
    for (var i = 0; i < 16; i++) {
      final tw = (sin(t * 2 + i * 1.3) + 1) / 2;
      final ang = i / 16 * 2 * pi + t * .05;
      Props.sparkle(c, centre.dx + cos(ang) * w * (.28 + .08 * (i % 3)), centre.dy - h * .12 + sin(ang) * h * .14, 2 + tw * 3, color: const Color(0xFFFFF3B0).withValues(alpha: .35 + .6 * tw));
    }
    // tap the castle for fireworks
    a.hits.add(_Hit(Offset(w * .5, h * .5), w * .22, 'castle'));
    // every ~6 s a gentle automatic firework so the scene never sits still
    final cycle = (t / 6.0).floor();
    final ph = t - cycle * 6.0;
    if (ph < 1.6) {
      final k = ph / 1.6;
      final p = Offset(w * (.2 + .6 * ((cycle * .37) % 1.0)), h * (.16 + .1 * ((cycle * .53) % 1.0)));
      for (var i = 0; i < 16; i++) {
        final a2 = i / 16 * 2 * pi;
        final r = 60 * Curves.easeOutCubic.transform(k);
        c.drawCircle(Offset(p.dx + cos(a2) * r, p.dy + sin(a2) * r + 24 * k * k), 3 * (1 - k) + .5, Paint()..color = [const Color(0xFFFFD34D), const Color(0xFFFF6FA5), const Color(0xFF7FE0FF)][cycle % 3].withValues(alpha: 1 - k));
      }
    }
    _paintBursts(c, a);
  }

  @override
  bool shouldRepaint(_SkyPainter o) => false;
}
