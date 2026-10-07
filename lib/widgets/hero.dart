import 'dart:math';
import 'package:flutter/material.dart';
import 'props.dart';

/// Cinematic fantasy landscape used on the launch screen (castle, forest, winding path).
class HeroScene extends StatefulWidget {
  final Widget? child;
  const HeroScene({super.key, this.child});
  @override
  State<HeroScene> createState() => _HeroSceneState();
}

class _HeroSceneState extends State<HeroScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        RepaintBoundary(child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _HeroPainter(_c.value)))),
        if (widget.child != null) widget.child!,
      ]);
}

class _HeroPainter extends CustomPainter {
  final double t;
  _HeroPainter(this.t);
  Paint _p(Color c) => Paint()..color = c;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final rect = Offset.zero & s;
    // sky
    c.drawRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3F5BF0), Color(0xFF8A6BFF), Color(0xFFD99BFF), Color(0xFFFFC2A8)], stops: [0, .32, .6, .85]).createShader(rect));
    // light rays
    final ray = Paint()..color = Colors.white.withValues(alpha: .06);
    for (var i = 0; i < 7; i++) {
      final a = -pi / 2 + (i - 3) * .22;
      c.drawPath(Path()..moveTo(w * .5, h * .34)..lineTo(w * .5 + cos(a - .05) * h, h * .34 + sin(a - .05) * h)..lineTo(w * .5 + cos(a + .05) * h, h * .34 + sin(a + .05) * h)..close(), ray);
    }
    c.drawCircle(Offset(w * .5, h * .36), w * .5, Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: .55), Colors.white.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(w * .5, h * .36), radius: w * .5)));
    // stars
    for (var i = 0; i < 26; i++) {
      final tw = (sin((t * 60 + i) * 1.3) + 1) / 2;
      Props.sparkle(c, w * ((i * 37 % 100) / 100), h * (.02 + .3 * ((i * 53 % 100) / 100)), 1.5 + (i % 3), color: Colors.white.withValues(alpha: .35 + .5 * tw));
    }
    // clouds (drift)
    for (var i = 0; i < 4; i++) {
      final x = ((t * (.5 + i * .15) + i * .27) % 1.3 - .15) * w;
      Props.cloud(c, x, h * (.1 + i * .06), w * (.14 + (i % 2) * .05), alpha: .7, color: i.isEven ? Colors.white : const Color(0xFFFFE3F2));
    }
    // far mountains
    void ridge(double base, double amp, Color a, Color b, double ph, double freq) {
      final p = Path()..moveTo(0, h);
      p.lineTo(0, h * base);
      for (var x = 0.0; x <= w; x += 6) {
        final y = h * base - (sin(x / w * pi * freq + ph).abs() * amp + sin(x / w * pi * freq * 2.3 + ph) * amp * .25) * h;
        p.lineTo(x, y);
      }
      p.lineTo(w, h);
      p.close();
      c.drawPath(p, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]).createShader(Rect.fromLTWH(0, h * (base - amp), w, h * (amp + .3))));
    }

    ridge(.58, .1, const Color(0xFF9C86F2), const Color(0xFF7A66DB), .5, 3.2);
    ridge(.62, .07, const Color(0xFF6F8CF0), const Color(0xFF5A72D8), 2, 4.1);
    // castle on a hill
    final cx = w * .5, cb = h * .60;
    c.drawOval(Rect.fromCenter(center: Offset(cx, cb + h * .02), width: w * .8, height: h * .09), _p(const Color(0xFF5CC27A)));
    Props.castle(c, cx, cb, w * .5);
    for (var i = 0; i < 3; i++) {
      Props.pine(c, cx - w * (.3 + i * .06), cb + h * .02, w * (.12 + i * .02), light: const Color(0xFF7A8CFF), dark: const Color(0xFF4F62D8));
      Props.pine(c, cx + w * (.3 + i * .06), cb + h * .02, w * (.12 + i * .02), light: const Color(0xFF7A8CFF), dark: const Color(0xFF4F62D8));
    }
    // waterfalls glow lines
    // mid hills
    void hill(double base, Color a, Color b, double ph) {
      final p = Path()..moveTo(0, h);
      p.lineTo(0, h * base);
      for (var x = 0.0; x <= w; x += 6) {
        p.lineTo(x, h * base - sin(x / w * pi * 1.6 + ph) * h * .03);
      }
      p.lineTo(w, h);
      p.close();
      c.drawPath(p, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]).createShader(Rect.fromLTWH(0, h * (base - .04), w, h * .5)));
    }

    hill(.68, const Color(0xFF63D17F), const Color(0xFF37A863), 1.2);
    // trees row
    for (var i = 0; i < 7; i++) {
      final x = w * (i / 6);
      if (x > w * .3 && x < w * .7) continue;
      i.isEven ? Props.roundTree(c, x, h * .70, w * .22) : Props.pine(c, x, h * .70, w * .22);
    }
    hill(.76, const Color(0xFF4FC276), const Color(0xFF2E9A5A), 3.4);
    // path to castle
    final path = Path()
      ..moveTo(w * .36, h)
      ..cubicTo(w * .30, h * .90, w * .72, h * .86, w * .55, h * .78)
      ..cubicTo(w * .46, h * .73, w * .58, h * .70, w * .5, h * .64)
      ..lineTo(w * .5, h * .64)
      ..cubicTo(w * .52, h * .70, w * .6, h * .73, w * .66, h * .78)
      ..cubicTo(w * .8, h * .86, w * .46, h * .92, w * .66, h)
      ..close();
    c.drawPath(path, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE9B8), Color(0xFFF2C77A)]).createShader(Rect.fromLTWH(0, h * .62, w, h * .4)));
    // sparkles along path
    for (var i = 0; i < 9; i++) {
      final tw = (sin((t * 80 + i) * 1.1) + 1) / 2;
      Props.sparkle(c, w * (.46 + .08 * sin(i * 1.7)), h * (.68 + i * .033), 2.5 + tw * 2, color: const Color(0xFFFFF7C2).withValues(alpha: .5 + .5 * tw));
    }
    // foreground bushes + flowers
    Props.bush(c, w * .06, h * .96, w * .3, color: const Color(0xFF3FB866));
    Props.bush(c, w * .94, h * .97, w * .32, color: const Color(0xFF38A85E));
    final cols = [const Color(0xFFFF6FA5), const Color(0xFFFFD34D), Colors.white, const Color(0xFF8A6BFF)];
    for (var i = 0; i < 14; i++) {
      final side = i.isEven ? .1 : .9;
      Props.flower(c, w * (side + ((i * 17) % 10 - 5) / 120), h * (.86 + .13 * ((i * 29 % 100) / 100)), 3 + (i % 3), cols[i % 4]);
    }
  }

  @override
  bool shouldRepaint(_HeroPainter o) => o.t != t;
}
