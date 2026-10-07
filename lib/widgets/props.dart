import 'dart:math';
import 'package:flutter/material.dart';

/// Small vector props used to paint illustrated scenes (no image assets needed).
class Props {
  static Paint _p(Color c) => Paint()..color = c;

  static Shader _vg(Rect r, Color a, Color b) => LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]).createShader(r);

  static void pine(Canvas c, double x, double baseY, double s, {Color light = const Color(0xFF3FBF7A), Color dark = const Color(0xFF1F8F5A)}) {
    c.drawRect(Rect.fromLTWH(x - s * .06, baseY - s * .16, s * .12, s * .16), _p(const Color(0xFF7A4E2A)));
    for (var i = 0; i < 3; i++) {
      final w = s * (.5 - i * .1), top = baseY - s * (.42 + i * .27), bot = baseY - s * (.12 + i * .22);
      final path = Path()
        ..moveTo(x, top)
        ..lineTo(x + w * .5, bot)
        ..lineTo(x - w * .5, bot)
        ..close();
      c.drawPath(path, Paint()..shader = _vg(Rect.fromLTWH(x - w / 2, top, w, bot - top), light, dark));
    }
  }

  static void roundTree(Canvas c, double x, double baseY, double s, {Color light = const Color(0xFF6FD66F), Color dark = const Color(0xFF2E9B4F)}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - s * .07, baseY - s * .4, s * .14, s * .4), Radius.circular(s * .05)), _p(const Color(0xFF8A5A30)));
    final r = Rect.fromCircle(center: Offset(x, baseY - s * .62), radius: s * .36);
    c.drawCircle(Offset(x, baseY - s * .62), s * .36, Paint()..shader = RadialGradient(center: const Alignment(-.4, -.5), colors: [light, dark]).createShader(r));
    c.drawCircle(Offset(x - s * .2, baseY - s * .5), s * .2, _p(dark.withValues(alpha: .6)));
    c.drawCircle(Offset(x - s * .12, baseY - s * .76), s * .06, _p(Colors.white.withValues(alpha: .25)));
  }

  static void palm(Canvas c, double x, double baseY, double s) {
    final trunk = Path()
      ..moveTo(x - s * .05, baseY)
      ..quadraticBezierTo(x + s * .12, baseY - s * .4, x + s * .02, baseY - s * .8)
      ..lineTo(x + s * .09, baseY - s * .8)
      ..quadraticBezierTo(x + s * .2, baseY - s * .4, x + s * .06, baseY)
      ..close();
    c.drawPath(trunk, _p(const Color(0xFFA9703A)));
    final top = Offset(x + s * .06, baseY - s * .8);
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + (i - 2.5) * .62;
      final p = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(top.dx + cos(a) * s * .35, top.dy + sin(a) * s * .35 - s * .08, top.dx + cos(a) * s * .5, top.dy + sin(a) * s * .5 + s * .1)
        ..quadraticBezierTo(top.dx + cos(a) * s * .3, top.dy + sin(a) * s * .25 + s * .02, top.dx, top.dy)
        ..close();
      c.drawPath(p, _p(i.isEven ? const Color(0xFF2FAF5F) : const Color(0xFF45C772)));
    }
    c.drawCircle(top + Offset(s * .02, s * .03), s * .035, _p(const Color(0xFF7A4E2A)));
  }

  static void chest(Canvas c, double x, double baseY, double s) {
    final w = s * .5, h = s * .3;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, baseY - h, w, h), Radius.circular(s * .04));
    c.drawRRect(body, Paint()..shader = _vg(body.outerRect, const Color(0xFFB8742E), const Color(0xFF8A4F1C)));
    final lid = Path()
      ..moveTo(x - w / 2, baseY - h)
      ..quadraticBezierTo(x, baseY - h - s * .28, x + w / 2, baseY - h)
      ..close();
    c.drawPath(lid, Paint()..shader = _vg(Rect.fromLTWH(x - w / 2, baseY - h - s * .28, w, s * .28), const Color(0xFFD08A3A), const Color(0xFFA9611F)));
    c.drawRect(Rect.fromLTWH(x - w / 2, baseY - h - s * .01, w, s * .05), _p(const Color(0xFFFFC83D)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, baseY - h + s * .02), width: s * .09, height: s * .12), Radius.circular(s * .02)), _p(const Color(0xFFFFE17A)));
    // gold glow
    for (var i = 0; i < 4; i++) {
      c.drawCircle(Offset(x - s * .12 + i * s * .08, baseY - h - s * .1 - (i.isEven ? 0 : s * .04)), s * .035, _p(const Color(0xFFFFD34D)));
    }
  }

  static void house(Canvas c, double x, double baseY, double s, {Color roof = const Color(0xFFE5584F), Color wall = const Color(0xFFFFF0D2)}) {
    final w = s * .6, h = s * .38;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, baseY - h, w, h), Radius.circular(s * .03)), _p(wall));
    c.drawPath(Path()..moveTo(x - w * .62, baseY - h + s * .02)..lineTo(x, baseY - h - s * .3)..lineTo(x + w * .62, baseY - h + s * .02)..close(), _p(roof));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - s * .06, baseY - s * .22, s * .12, s * .22), Radius.circular(s * .03)), _p(const Color(0xFF8A5A30)));
    c.drawRect(Rect.fromLTWH(x + w * .18, baseY - h * .8, s * .1, s * .1), _p(const Color(0xFF7EC8F0)));
  }

  static void castle(Canvas c, double x, double baseY, double s, {Color wall = const Color(0xFFF4E4F8), Color roof = const Color(0xFFFF6FA5), Color roof2 = const Color(0xFF6C8CFF)}) {
    void tower(double cx, double w, double h, Color r) {
      final rect = Rect.fromLTWH(cx - w / 2, baseY - h, w, h);
      c.drawRect(rect, Paint()..shader = LinearGradient(colors: [wall, const Color(0xFFD9C3E8)]).createShader(rect));
      c.drawPath(Path()..moveTo(cx - w * .65, baseY - h + 1)..lineTo(cx, baseY - h - w * 1.1)..lineTo(cx + w * .65, baseY - h + 1)..close(), _p(r));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, baseY - h * .62), width: w * .22, height: w * .36), Radius.circular(w * .1)), _p(const Color(0xFFFFD34D)));
      c.drawLine(Offset(cx, baseY - h - w * 1.1), Offset(cx, baseY - h - w * 1.5), Paint()..color = const Color(0xFF7A4E2A)..strokeWidth = 2);
      c.drawPath(Path()..moveTo(cx, baseY - h - w * 1.5)..lineTo(cx + w * .4, baseY - h - w * 1.38)..lineTo(cx, baseY - h - w * 1.26)..close(), _p(const Color(0xFFFF4F7A)));
    }

    tower(x - s * .32, s * .2, s * .5, roof2);
    tower(x + s * .32, s * .2, s * .5, roof2);
    c.drawRect(Rect.fromLTWH(x - s * .3, baseY - s * .3, s * .6, s * .3), _p(wall));
    tower(x, s * .3, s * .75, roof);
    c.drawPath(Path()..moveTo(x - s * .09, baseY)..lineTo(x - s * .09, baseY - s * .14)..quadraticBezierTo(x, baseY - s * .27, x + s * .09, baseY - s * .14)..lineTo(x + s * .09, baseY)..close(), _p(const Color(0xFF7A4E2A)));
  }

  static void mountain(Canvas c, double x, double baseY, double s, {Color a = const Color(0xFFB7A4F5), Color b = const Color(0xFF7E68D8)}) {
    final p = Path()
      ..moveTo(x - s * .5, baseY)
      ..lineTo(x - s * .05, baseY - s * .75)
      ..lineTo(x + s * .12, baseY - s * .55)
      ..lineTo(x + s * .25, baseY - s * .68)
      ..lineTo(x + s * .55, baseY)
      ..close();
    c.drawPath(p, Paint()..shader = _vg(Rect.fromLTWH(x - s * .5, baseY - s * .75, s, s * .75), a, b));
    c.drawPath(Path()..moveTo(x - s * .05, baseY - s * .75)..lineTo(x - s * .17, baseY - s * .52)..lineTo(x - s * .08, baseY - s * .56)..lineTo(x, baseY - s * .5)..lineTo(x + s * .06, baseY - s * .58)..close(), _p(Colors.white.withValues(alpha: .9)));
  }

  static void boat(Canvas c, double x, double y, double s) {
    c.drawPath(Path()..moveTo(x - s * .3, y)..lineTo(x + s * .3, y)..lineTo(x + s * .2, y + s * .13)..lineTo(x - s * .2, y + s * .13)..close(), _p(const Color(0xFF9B5E2C)));
    c.drawLine(Offset(x, y), Offset(x, y - s * .55), Paint()..color = const Color(0xFF5A3A1A)..strokeWidth = s * .03);
    c.drawPath(Path()..moveTo(x + s * .02, y - s * .52)..lineTo(x + s * .3, y - s * .06)..lineTo(x + s * .02, y - s * .06)..close(), _p(Colors.white));
    c.drawPath(Path()..moveTo(x - s * .02, y - s * .42)..lineTo(x - s * .22, y - s * .06)..lineTo(x - s * .02, y - s * .06)..close(), _p(const Color(0xFFFF8FB8)));
  }

  static void fish(Canvas c, double x, double y, double s, {Color color = const Color(0xFFFF9A2E)}) {
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: s * .5, height: s * .3), _p(color));
    c.drawPath(Path()..moveTo(x + s * .22, y)..lineTo(x + s * .42, y - s * .14)..lineTo(x + s * .42, y + s * .14)..close(), _p(color));
    c.drawCircle(Offset(x - s * .12, y - s * .03), s * .035, _p(Colors.white));
    c.drawCircle(Offset(x - s * .12, y - s * .03), s * .018, _p(Colors.black87));
    c.drawLine(Offset(x + s * .02, y - s * .12), Offset(x + s * .02, y + s * .12), Paint()..color = Colors.white.withValues(alpha: .8)..strokeWidth = s * .03);
  }

  static void bullseye(Canvas c, double x, double y, double r) {
    final cols = [const Color(0xFFE5483F), Colors.white, const Color(0xFFE5483F), Colors.white, const Color(0xFFFFD34D)];
    for (var i = 0; i < cols.length; i++) {
      c.drawCircle(Offset(x, y), r * (1 - i * .2), _p(cols[i]));
    }
    c.drawLine(Offset(x, y + r), Offset(x, y + r * 1.8), Paint()..color = const Color(0xFF7A4E2A)..strokeWidth = r * .15);
  }

  static void rocket(Canvas c, double x, double y, double s, {double angle = .6}) {
    c.save();
    c.translate(x, y);
    c.rotate(angle);
    c.drawPath(Path()..moveTo(-s * .12, s * .2)..lineTo(0, s * .42 + s * .1)..lineTo(s * .12, s * .2)..close(), _p(const Color(0xFFFFB02E)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * .26, height: s * .55), Radius.circular(s * .13)), _p(Colors.white));
    c.drawPath(Path()..moveTo(-s * .13, -s * .1)..quadraticBezierTo(0, -s * .42, s * .13, -s * .1)..close(), _p(const Color(0xFFE5483F)));
    c.drawCircle(Offset(0, -s * .02), s * .06, _p(const Color(0xFF58B7FF)));
    c.drawPath(Path()..moveTo(-s * .13, s * .12)..lineTo(-s * .24, s * .26)..lineTo(-s * .13, s * .24)..close(), _p(const Color(0xFFE5483F)));
    c.drawPath(Path()..moveTo(s * .13, s * .12)..lineTo(s * .24, s * .26)..lineTo(s * .13, s * .24)..close(), _p(const Color(0xFFE5483F)));
    c.restore();
  }

  static void satellite(Canvas c, double x, double y, double s) {
    c.save();
    c.translate(x, y);
    c.rotate(-.5);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * .2, height: s * .26), Radius.circular(s * .04)), _p(const Color(0xFFE8E8F8)));
    for (final dx in [-1.0, 1.0]) {
      c.drawRect(Rect.fromCenter(center: Offset(dx * s * .26, 0), width: s * .26, height: s * .16), _p(const Color(0xFF4F6BFF)));
      c.drawLine(Offset(dx * s * .26, -s * .08), Offset(dx * s * .26, s * .08), Paint()..color = Colors.white54..strokeWidth = 1);
    }
    c.drawCircle(Offset(0, -s * .17), s * .05, _p(const Color(0xFFFFD34D)));
    c.restore();
  }

  static void book(Canvas c, double x, double baseY, double s) {
    final left = Path()..moveTo(x, baseY)..lineTo(x - s * .32, baseY - s * .06)..lineTo(x - s * .32, baseY - s * .3)..lineTo(x, baseY - s * .24)..close();
    final right = Path()..moveTo(x, baseY)..lineTo(x + s * .32, baseY - s * .06)..lineTo(x + s * .32, baseY - s * .3)..lineTo(x, baseY - s * .24)..close();
    c.drawPath(left, _p(Colors.white));
    c.drawPath(right, _p(const Color(0xFFF1F1FF)));
    c.drawPath(Path()..moveTo(x - s * .36, baseY - s * .03)..lineTo(x, baseY + s * .03)..lineTo(x + s * .36, baseY - s * .03), Paint()..color = const Color(0xFFE0568A)..style = PaintingStyle.stroke..strokeWidth = s * .04);
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(x - s * .26, baseY - s * (.22 - i * .05)), Offset(x - s * .06, baseY - s * (.17 - i * .05)), Paint()..color = Colors.black12..strokeWidth = 1.5);
    }
  }

  static void bush(Canvas c, double x, double baseY, double s, {Color color = const Color(0xFF3FAF5F)}) {
    c.drawCircle(Offset(x - s * .18, baseY - s * .14), s * .2, _p(color));
    c.drawCircle(Offset(x + s * .16, baseY - s * .14), s * .22, _p(Color.lerp(color, Colors.black, .12)!));
    c.drawCircle(Offset(x, baseY - s * .22), s * .25, _p(Color.lerp(color, Colors.white, .12)!));
  }

  static void flower(Canvas c, double x, double y, double r, Color col) {
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5;
      c.drawCircle(Offset(x + cos(a) * r, y + sin(a) * r), r * .75, _p(col));
    }
    c.drawCircle(Offset(x, y), r * .6, _p(const Color(0xFFFFE17A)));
  }

  static void sparkle(Canvas c, double x, double y, double r, {Color color = Colors.white}) {
    final p = Path()
      ..moveTo(x, y - r)
      ..quadraticBezierTo(x, y, x + r, y)
      ..quadraticBezierTo(x, y, x, y + r)
      ..quadraticBezierTo(x, y, x - r, y)
      ..quadraticBezierTo(x, y, x, y - r)
      ..close();
    c.drawPath(p, _p(color));
  }

  static void cloud(Canvas c, double x, double y, double s, {double alpha = .9, Color color = Colors.white}) {
    final p = _p(color.withValues(alpha: alpha));
    c.drawOval(Rect.fromCenter(center: Offset(x, y + s * .12), width: s * 1.5, height: s * .45), p);
    c.drawCircle(Offset(x - s * .3, y), s * .26, p);
    c.drawCircle(Offset(x + s * .08, y - s * .1), s * .34, p);
    c.drawCircle(Offset(x + s * .4, y + s * .02), s * .24, p);
  }
}

/// A floating island with themed props. [kind] decides what lives on it.
class IslandArt extends CustomPainter {
  final String kind; // forest | valley | ocean | village | treasure | castle | sky
  final Color grass, grassDark;
  final bool locked;
  IslandArt(this.kind, this.grass, this.grassDark, {this.locked = false});

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    final g1 = locked ? const Color(0xFFB4BBD3) : grass;
    final g2 = locked ? const Color(0xFF8E96B4) : grassDark;
    // water shadow
    c.drawOval(Rect.fromLTWH(w * .06, h * .78, w * .88, h * .2), Paint()..color = const Color(0x2A0B2A5A));
    // rock underside
    final rock = Path()
      ..moveTo(w * .04, h * .42)
      ..cubicTo(w * .06, h * .72, w * .28, h * .94, w * .5, h * .97)
      ..cubicTo(w * .72, h * .94, w * .94, h * .72, w * .96, h * .42)
      ..close();
    c.drawPath(rock, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: const [Color(0xFFA67C52), Color(0xFF6B4A30)]).createShader(Rect.fromLTWH(0, h * .4, w, h * .6)));
    final strata = Paint()
      ..color = const Color(0xFF5A3C26).withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = h * (.55 + i * .1);
      c.drawArc(Rect.fromLTWH(w * (.14 + i * .07), y, w * (.72 - i * .14), h * .12), 0.2, pi - .4, false, strata);
    }
    // sand rim for water-ish islands
    if (kind == 'treasure' || kind == 'ocean') {
      c.drawOval(Rect.fromLTWH(w * .0, h * .16, w, h * .56), Paint()..color = locked ? const Color(0xFFD3D3DA) : const Color(0xFFFFE8A8));
    }
    // grass lip + top
    final top = Rect.fromLTWH(w * .02, h * .14, w * .96, h * .54);
    c.drawOval(top.shift(Offset(0, h * .04)), Paint()..color = g2);
    c.drawOval(top.deflate(kind == 'treasure' || kind == 'ocean' ? w * .04 : 0), Paint()..shader = RadialGradient(center: const Alignment(-.3, -.5), radius: 1.1, colors: [Color.lerp(g1, Colors.white, .25)!, g1, g2]).createShader(top));
    if (kind == 'ocean') {
      c.drawOval(top.deflate(w * .04), Paint()..shader = RadialGradient(colors: [const Color(0xFF8EE3FF).withValues(alpha: locked ? .3 : 1), const Color(0xFF3FB3E8).withValues(alpha: locked ? .3 : 1)]).createShader(top));
    }
    if (locked) {
      c.drawOval(top, Paint()..color = const Color(0x33202850));
    }
    final op = locked ? .55 : 1.0;
    c.saveLayer(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: op));
    final by = h * .5; // props baseline
    switch (kind) {
      case 'forest':
        Props.pine(c, w * .22, by - h * .02, w * .42);
        Props.roundTree(c, w * .5, by - h * .06, w * .5);
        Props.pine(c, w * .78, by - h * .02, w * .42);
        Props.bush(c, w * .36, by + h * .05, w * .2);
        Props.flower(c, w * .66, by + h * .04, w * .025, const Color(0xFFFF6FA5));
        Props.flower(c, w * .3, by + h * .08, w * .022, const Color(0xFFFFD34D));
        break;
      case 'valley':
        Props.mountain(c, w * .35, by, w * .7);
        Props.mountain(c, w * .7, by + h * .02, w * .5, a: const Color(0xFFC7B6FA), b: const Color(0xFF8C75E0));
        Props.bullseye(c, w * .72, by + h * .02, w * .1);
        Props.flower(c, w * .22, by + h * .08, w * .022, const Color(0xFFFFFFFF));
        break;
      case 'ocean':
        Props.boat(c, w * .42, by - h * .02, w * .55);
        Props.fish(c, w * .72, by + h * .04, w * .3);
        Props.fish(c, w * .25, by + h * .07, w * .22, color: const Color(0xFFFF6FA5));
        final wp = Paint()..color = Colors.white.withValues(alpha: .7)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round;
        c.drawArc(Rect.fromLTWH(w * .3, by + h * .1, w * .2, h * .06), pi, pi, false, wp);
        c.drawArc(Rect.fromLTWH(w * .55, by + h * .13, w * .2, h * .06), pi, pi, false, wp);
        break;
      case 'village':
        Props.house(c, w * .3, by, w * .5);
        Props.house(c, w * .66, by - h * .02, w * .46, roof: const Color(0xFF4F8CFF));
        Props.roundTree(c, w * .88, by + h * .02, w * .3);
        Props.flower(c, w * .5, by + h * .08, w * .025, const Color(0xFFFF6FA5));
        break;
      case 'treasure':
        Props.palm(c, w * .24, by + h * .04, w * .46);
        Props.chest(c, w * .62, by + h * .05, w * .6);
        Props.bush(c, w * .84, by + h * .06, w * .2, color: const Color(0xFF52B86A));
        break;
      case 'castle':
        Props.roundTree(c, w * .14, by + h * .02, w * .3);
        Props.castle(c, w * .5, by + h * .03, w * .66);
        Props.roundTree(c, w * .88, by + h * .03, w * .3, light: const Color(0xFFFFA6C8), dark: const Color(0xFFD9578A));
        break;
      case 'sky':
        Props.satellite(c, w * .3, by - h * .12, w * .46);
        Props.rocket(c, w * .68, by - h * .02, w * .5);
        Props.sparkle(c, w * .5, by - h * .24, w * .05, color: const Color(0xFFFFE17A));
        break;
    }
    c.restore();
  }

  @override
  bool shouldRepaint(IslandArt o) => o.kind != kind || o.locked != locked;
}
