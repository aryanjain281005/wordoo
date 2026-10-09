import 'dart:math';
import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/theme.dart';
import 'props.dart';

// ======================================================================
// Companion creature (fox / panda / dragon) — one consistent vector style
// ======================================================================
class CreaturePainter extends CustomPainter {
  final int type; // 0 fox, 1 panda, 2 dragon
  final double wag; // -1..1
  final bool blink;
  final bool happy;
  final double mouth; // 0 closed … 1 wide open (lip-sync)
  final String mood; // happy | sad | surprised | thinking
  CreaturePainter(this.type, {this.wag = 0, this.blink = false, this.happy = true, this.mouth = 0, this.mood = 'happy'});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    final o = switch (type) { 1 => _Pal(Colors.white, const Color(0xFF2B2B33), const Color(0xFFEFEFF4)), 2 => _Pal(const Color(0xFF4CC37E), const Color(0xFF2A8F5A), const Color(0xFFD8F6C9)), _ => _Pal(C.fox, const Color(0xFF9B4A12), Colors.white) };
    final fill = Paint()..style = PaintingStyle.fill;
    Shader shade(Rect r, Color base) => RadialGradient(center: const Alignment(-.35, -.5), radius: 1.1, colors: [Color.lerp(base, Colors.white, .28)!, base, Color.lerp(base, Colors.black, .16)!]).createShader(r);

    // shadow
    fill.color = const Color(0x22000000);
    canvas.drawOval(Rect.fromCenter(center: Offset(s * .5, s * .96), width: s * .56, height: s * .08), fill);

    // tail
    canvas.save();
    canvas.translate(s * .78, s * .74);
    canvas.rotate(wag * .22 - .35);
    final tail = Path()
      ..moveTo(0, 0)
      ..cubicTo(s * .22, -s * .06, s * .3, -s * .34, s * .12, -s * .46)
      ..cubicTo(s * .06, -s * .30, -s * .04, -s * .16, -s * .06, -s * .02)
      ..close();
    fill.shader = shade(Rect.fromLTWH(-s * .06, -s * .46, s * .36, s * .5), type == 1 ? const Color(0xFF2B2B33) : o.main);
    canvas.drawPath(tail, fill);
    fill.shader = null;
    if (type == 0) {
      fill.color = Colors.white;
      final tip = Path()
        ..moveTo(s * .12, -s * .46)
        ..cubicTo(s * .22, -s * .40, s * .27, -s * .34, s * .27, -s * .27)
        ..cubicTo(s * .17, -s * .30, s * .08, -s * .30, s * .03, -s * .33)
        ..close();
      canvas.drawPath(tip, fill);
    }
    canvas.restore();

    // dragon wings
    if (type == 2) {
      fill.color = const Color(0xFFFFC83D);
      final w = Path()
        ..moveTo(s * .28, s * .66)
        ..quadraticBezierTo(s * .02, s * .5, s * .1, s * .34)
        ..quadraticBezierTo(s * .2, s * .46, s * .34, s * .54)
        ..close();
      canvas.drawPath(w, fill);
    }

    // body
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(s * .26, s * .56, s * .48, s * .38), Radius.circular(s * .2));
    fill.shader = shade(body.outerRect, type == 1 ? Colors.white : o.main);
    canvas.drawRRect(body, fill);
    fill.shader = null;
    fill.color = o.belly;
    canvas.drawOval(Rect.fromLTWH(s * .35, s * .62, s * .30, s * .30), fill);
    // feet
    fill.color = type == 1 ? const Color(0xFF2B2B33) : o.dark;
    canvas.drawOval(Rect.fromLTWH(s * .27, s * .88, s * .18, s * .09), fill);
    canvas.drawOval(Rect.fromLTWH(s * .55, s * .88, s * .18, s * .09), fill);

    // ears
    void ear(double cx, bool left) {
      final p = Path();
      final dir = left ? -1.0 : 1.0;
      if (type == 1) {
        fill.color = const Color(0xFF2B2B33);
        canvas.drawCircle(Offset(s * cx, s * .22), s * .09, fill);
        return;
      }
      p.moveTo(s * (cx - .09 * dir * -1), s * .38);
      p.lineTo(s * (cx + .02 * dir), s * .08);
      p.lineTo(s * (cx + .17 * dir), s * .36);
      p.close();
      fill.color = type == 2 ? o.dark : o.main;
      canvas.drawPath(p, fill);
      if (type == 0) {
        final inner = Path()
          ..moveTo(s * (cx + .02 * dir + .01 * dir * -1), s * .33)
          ..lineTo(s * (cx + .03 * dir), s * .16)
          ..lineTo(s * (cx + .12 * dir), s * .33)
          ..close();
        fill.color = o.dark;
        canvas.drawPath(inner, fill);
      }
    }

    ear(.30, true);
    ear(.70, false);
    // dragon horns
    if (type == 2) {
      fill.color = const Color(0xFFFFC83D);
      canvas.drawPath(Path()..moveTo(s * .38, s * .22)..lineTo(s * .34, s * .08)..lineTo(s * .45, s * .2)..close(), fill);
      canvas.drawPath(Path()..moveTo(s * .62, s * .22)..lineTo(s * .66, s * .08)..lineTo(s * .55, s * .2)..close(), fill);
    }

    // head
    fill.color = type == 1 ? Colors.white : o.main;
    final head = Path()
      ..moveTo(s * .13, s * .46)
      ..cubicTo(s * .13, s * .24, s * .30, s * .18, s * .5, s * .18)
      ..cubicTo(s * .70, s * .18, s * .87, s * .24, s * .87, s * .46)
      ..cubicTo(s * .87, s * .64, s * .70, s * .70, s * .5, s * .70)
      ..cubicTo(s * .30, s * .70, s * .13, s * .64, s * .13, s * .46)
      ..close();
    fill.shader = shade(Rect.fromLTWH(s * .13, s * .18, s * .74, s * .52), type == 1 ? Colors.white : o.main);
    canvas.drawPath(head, fill);
    fill.shader = null;
    if (type == 0) {
      fill.color = Colors.white;
      canvas.drawOval(Rect.fromLTWH(s * .13, s * .46, s * .34, s * .20), fill);
      canvas.drawOval(Rect.fromLTWH(s * .53, s * .46, s * .34, s * .20), fill);
      // fluffy cheek tufts
      canvas.drawPath(Path()..moveTo(s * .13, s * .5)..lineTo(s * .04, s * .56)..lineTo(s * .14, s * .59)..lineTo(s * .06, s * .66)..lineTo(s * .2, s * .64)..close(), fill);
      canvas.drawPath(Path()..moveTo(s * .87, s * .5)..lineTo(s * .96, s * .56)..lineTo(s * .86, s * .59)..lineTo(s * .94, s * .66)..lineTo(s * .8, s * .64)..close(), fill);
    }
    if (type == 1) {
      fill.color = const Color(0xFF2B2B33);
      canvas.save();
      canvas.translate(s * .33, s * .45);
      canvas.rotate(.5);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * .17, height: s * .22), fill);
      canvas.restore();
      canvas.save();
      canvas.translate(s * .67, s * .45);
      canvas.rotate(-.5);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * .17, height: s * .22), fill);
      canvas.restore();
    }
    // snout
    fill.color = type == 0 ? Colors.white : (type == 1 ? const Color(0xFFEDEDF2) : const Color(0xFFBFF0A8));
    canvas.drawOval(Rect.fromCenter(center: Offset(s * .5, s * .55), width: s * .30, height: s * .20), fill);
    // eyes
    final eyeY = s * .44;
    if (blink) {
      final p = Paint()
        ..color = const Color(0xFF20263D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .018
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: Offset(s * .35, eyeY), width: s * .08, height: s * .05), 0, pi, false, p);
      canvas.drawArc(Rect.fromCenter(center: Offset(s * .65, eyeY), width: s * .08, height: s * .05), 0, pi, false, p);
    } else {
      fill.color = const Color(0xFF20263D);
      canvas.drawOval(Rect.fromCenter(center: Offset(s * .35, eyeY), width: s * .1, height: s * .13), fill);
      canvas.drawOval(Rect.fromCenter(center: Offset(s * .65, eyeY), width: s * .1, height: s * .13), fill);
      fill.color = Colors.white;
      canvas.drawCircle(Offset(s * .36, eyeY - s * .03), s * .022, fill);
      canvas.drawCircle(Offset(s * .66, eyeY - s * .03), s * .022, fill);
      canvas.drawCircle(Offset(s * .335, eyeY + s * .025), s * .01, fill);
      canvas.drawCircle(Offset(s * .635, eyeY + s * .025), s * .01, fill);
    }
    // nose + mouth
    fill.color = const Color(0xFF20263D);
    canvas.drawOval(Rect.fromCenter(center: Offset(s * .5, s * .52), width: s * .07, height: s * .05), fill);
    final mp = Paint()
      ..color = const Color(0xFF20263D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .014
      ..strokeCap = StrokeCap.round;
    final sad = mood == 'sad' || !happy;
    if (mouth > .06 || mood == 'surprised') {
      // open mouth for speaking / surprise
      final open = mood == 'surprised' ? max(.6, mouth) : mouth;
      final r = Rect.fromCenter(center: Offset(s * .5, s * .6), width: s * (.09 + .05 * open), height: s * (.03 + .08 * open));
      fill.color = const Color(0xFF6B1F2A);
      canvas.drawOval(r, fill);
      fill.color = const Color(0xFFFF8FA3);
      canvas.drawOval(Rect.fromCenter(center: Offset(s * .5, r.bottom - r.height * .25), width: r.width * .6, height: r.height * .35), fill);
    } else {
      final mpath = Path()
        ..moveTo(s * .5, s * .545)
        ..lineTo(s * .5, s * .575)
        ..moveTo(s * .43, sad ? s * .61 : s * .585)
        ..quadraticBezierTo(s * .5, sad ? s * .57 : s * .64, s * .57, sad ? s * .61 : s * .585);
      canvas.drawPath(mpath, mp);
    }
    if (mood == 'sad' || mood == 'thinking' || mood == 'surprised') {
      // eyebrows show the feeling
      final b = Paint()
        ..color = const Color(0xFF20263D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .016
        ..strokeCap = StrokeCap.round;
      final up = mood == 'surprised' ? -s * .03 : 0.0;
      if (mood == 'sad') {
        canvas.drawLine(Offset(s * .29, s * .36), Offset(s * .39, s * .33), b);
        canvas.drawLine(Offset(s * .71, s * .36), Offset(s * .61, s * .33), b);
      } else {
        canvas.drawLine(Offset(s * .29, s * .35 + up), Offset(s * .4, s * .34 + up), b);
        canvas.drawLine(Offset(s * .6, s * .34 + up + (mood == 'thinking' ? -s * .02 : 0)), Offset(s * .71, s * .35 + up), b);
      }
    }
    if (happy && mood != 'sad') {
      fill.color = const Color(0x55FF6FA5);
      canvas.drawCircle(Offset(s * .25, s * .55), s * .04, fill);
      canvas.drawCircle(Offset(s * .75, s * .55), s * .04, fill);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CreaturePainter o) => o.wag != wag || o.blink != blink || o.type != type || o.happy != happy || o.mouth != mouth || o.mood != mood;
}

class _Pal {
  final Color main, dark, belly;
  _Pal(this.main, this.dark, this.belly);
}

// ======================================================================
// Child explorer avatar
// ======================================================================
class AvatarPainter extends CustomPainter {
  final int hair; // 0..3
  final int outfit; // 0..3
  AvatarPainter(this.hair, this.outfit);

  static const hairColors = [Color(0xFF4A2C17), Color(0xFF1B1B22), Color(0xFF2B1B14), Color(0xFFB8561A)];
  static const outfitMain = [Color(0xFF3FA66B), Color(0xFF3F7FE0), Color(0xFFE0524C), Color(0xFF8E5BE0)];
  static const outfitShirt = [Color(0xFF5BA4E6), Color(0xFFF2C94C), Color(0xFFFFF1D0), Color(0xFFFF9FC4)];
  static const skin = Color(0xFFF5C9A0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint();
    // ground shadow
    p.color = const Color(0x22000000);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .5, h * .975), width: w * .6, height: h * .05), p);
    // backpack
    p.color = const Color(0xFF9B6B3A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .62, h * .46, w * .26, h * .30), Radius.circular(w * .08)), p);
    p.color = const Color(0xFF7A5028);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .66, h * .56, w * .18, h * .1), Radius.circular(w * .04)), p);
    // legs
    p.color = const Color(0xFF5B4B8A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .33, h * .78, w * .13, h * .16), Radius.circular(w * .05)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .54, h * .78, w * .13, h * .16), Radius.circular(w * .05)), p);
    p.color = const Color(0xFF3B2A1E);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .30, h * .92, w * .18, h * .07), Radius.circular(w * .04)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .52, h * .92, w * .18, h * .07), Radius.circular(w * .04)), p);
    // arms
    p.color = skin;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .17, h * .52, w * .10, h * .22), Radius.circular(w * .05)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .73, h * .52, w * .10, h * .22), Radius.circular(w * .05)), p);
    // torso
    p.color = outfitShirt[outfit];
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .26, h * .5, w * .48, h * .32), Radius.circular(w * .1)), p);
    // vest / jacket
    p.color = outfitMain[outfit];
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .26, h * .5, w * .16, h * .32), Radius.circular(w * .06)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .58, h * .5, w * .16, h * .32), Radius.circular(w * .06)), p);
    // sleeves
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .16, h * .5, w * .12, h * .12), Radius.circular(w * .05)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .72, h * .5, w * .12, h * .12), Radius.circular(w * .05)), p);
    // neck + head
    p.color = skin;
    canvas.drawRect(Rect.fromLTWH(w * .44, h * .44, w * .12, h * .08), p);
    final headC = Offset(w * .5, h * .30);
    final hr = w * .26;
    // hair behind
    p.color = hairColors[hair];
    if (hair == 2) {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * .26, h * .42), width: w * .16, height: h * .2), p);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * .74, h * .42), width: w * .16, height: h * .2), p);
    }
    if (hair == 3) {
      canvas.drawCircle(Offset(w * .25, h * .27), w * .1, p);
      canvas.drawCircle(Offset(w * .75, h * .27), w * .1, p);
    }
    p.color = skin;
    canvas.drawCircle(Offset(w * .25, h * .32), w * .045, p);
    canvas.drawCircle(Offset(w * .75, h * .32), w * .045, p);
    final headR = Rect.fromCenter(center: headC, width: hr * 2, height: hr * 2.05);
    p.shader = RadialGradient(center: const Alignment(-.3, -.4), colors: [const Color(0xFFFFDDB8), skin, const Color(0xFFEBB487)]).createShader(headR);
    canvas.drawOval(headR, p);
    p.shader = null;
    // hair front
    p.color = hairColors[hair];
    switch (hair) {
      case 0:
        canvas.drawPath(
            Path()
              ..moveTo(w * .24, h * .30)
              ..quadraticBezierTo(w * .22, h * .12, w * .5, h * .11)
              ..quadraticBezierTo(w * .78, h * .12, w * .76, h * .30)
              ..quadraticBezierTo(w * .66, h * .20, w * .5, h * .22)
              ..quadraticBezierTo(w * .36, h * .2, w * .24, h * .30)
              ..close(),
            p);
        break;
      case 1:
        final path = Path()..moveTo(w * .24, h * .31);
        const spikes = 6;
        for (var i = 0; i <= spikes; i++) {
          final x = w * (.24 + .52 * i / spikes);
          path.lineTo(x - w * .03, h * (i.isEven ? .12 : .17));
          path.lineTo(x, h * .08 + (i.isEven ? 0 : h * .02));
        }
        path.lineTo(w * .76, h * .31);
        path.quadraticBezierTo(w * .66, h * .21, w * .5, h * .22);
        path.quadraticBezierTo(w * .36, h * .21, w * .24, h * .31);
        canvas.drawPath(path, p);
        break;
      case 2:
        canvas.drawPath(
            Path()
              ..moveTo(w * .23, h * .34)
              ..quadraticBezierTo(w * .2, h * .1, w * .5, h * .09)
              ..quadraticBezierTo(w * .8, h * .1, w * .77, h * .34)
              ..quadraticBezierTo(w * .7, h * .18, w * .5, h * .2)
              ..quadraticBezierTo(w * .3, h * .18, w * .23, h * .34)
              ..close(),
            p);
        break;
      default:
        for (final dx in [.3, .42, .54, .66]) {
          canvas.drawCircle(Offset(w * dx, h * .15), w * .085, p);
        }
        canvas.drawPath(
            Path()
              ..moveTo(w * .26, h * .26)
              ..quadraticBezierTo(w * .5, h * .14, w * .74, h * .26)
              ..quadraticBezierTo(w * .5, h * .2, w * .26, h * .26)
              ..close(),
            p);
    }
    // face
    p.color = const Color(0xFF20263D);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .405, h * .315), width: w * .075, height: h * .06), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .595, h * .315), width: w * .075, height: h * .06), p);
    p.color = Colors.white;
    canvas.drawCircle(Offset(w * .417, h * .30), w * .015, p);
    canvas.drawCircle(Offset(w * .607, h * .30), w * .015, p);
    canvas.drawCircle(Offset(w * .395, h * .328), w * .007, p);
    canvas.drawCircle(Offset(w * .585, h * .328), w * .007, p);
    final brow = Paint()..color = hairColors[hair]..style = PaintingStyle.stroke..strokeWidth = w * .016..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(w * .405, h * .275), width: w * .09, height: h * .04), pi + .3, pi - .6, false, brow);
    canvas.drawArc(Rect.fromCenter(center: Offset(w * .595, h * .275), width: w * .09, height: h * .04), pi + .3, pi - .6, false, brow);
    final sp = Paint()
      ..color = const Color(0xFF8A3B2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .015
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(w * .5, h * .35), width: w * .16, height: h * .08), .15, pi - .3, false, sp);
    p.color = const Color(0x44FF6FA5);
    canvas.drawCircle(Offset(w * .35, h * .36), w * .035, p);
    canvas.drawCircle(Offset(w * .65, h * .36), w * .035, p);
  }

  @override
  bool shouldRepaint(AvatarPainter o) => o.hair != hair || o.outfit != outfit;
}

class AvatarView extends StatelessWidget {
  final int hair, outfit;
  final String? hatEmoji;
  final double height;
  const AvatarView({super.key, required this.hair, required this.outfit, this.hatEmoji, this.height = 220});
  @override
  Widget build(BuildContext context) {
    final w = height * .72;
    return SizedBox(
      width: w,
      height: height,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        CustomPaint(size: Size(w, height), painter: AvatarPainter(hair, outfit)),
        if (hatEmoji != null)
          Positioned(top: -height * .04, child: Text(hatEmoji!, style: TextStyle(fontSize: height * .26))),
      ]),
    );
  }
}

// ======================================================================
// Animated adventure backgrounds
// ======================================================================
enum Scene { day, forest, ocean, night, treasure, castle }

class AdventureBackground extends StatefulWidget {
  final Scene scene;
  final Widget? child;
  final bool calm; // fewer particles for game screens
  final String? artId; // painted art from ART_PROMPTS.md replaces the code-drawn scene when the file exists
  const AdventureBackground({super.key, this.scene = Scene.day, this.child, this.calm = false, this.artId});
  @override
  State<AdventureBackground> createState() => _AdventureBackgroundState();
}

class _AdventureBackgroundState extends State<AdventureBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 90))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = ReadleAssets.instance.art(widget.artId ?? 'bg.${widget.scene.name}');
    return Stack(fit: StackFit.expand, children: [
      if (art != null) ...[
        // painted background: drawn once and cached; only a few light sparkles move on their own layer
        RepaintBoundary(child: Image.asset(art, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.medium)),
        RepaintBoundary(child: IgnorePointer(child: AnimatedBuilder(animation: _c, builder: (_, _) => CustomPaint(painter: _MotesPainter(_c.value, widget.calm ? 10 : 18))))),
      ] else
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(painter: _ScenePainter(widget.scene, _c.value, widget.calm)),
          ),
        ),
      if (widget.child != null) widget.child!,
    ]);
  }
}

/// A few soft glowing motes drifting upward over a painted background (cheap: small circles only).
class _MotesPainter extends CustomPainter {
  final double t;
  final int n;
  _MotesPainter(this.t, this.n);
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < n; i++) {
      final r = Random(i * 97 + 13);
      final speed = 3 + r.nextInt(4);
      final y = (r.nextDouble() - t * speed) % 1.0;
      final x = r.nextDouble() * size.width + sin((t * speed + r.nextDouble()) * 2 * pi) * 14;
      final a = (sin((t * 40 + i) * .7).abs() * .5 + .25) * (y < .1 ? y * 10 : 1);
      final rad = 1.6 + r.nextDouble() * 2.2;
      canvas.drawCircle(Offset(x, y * size.height), rad * 2.4, Paint()..color = Colors.white.withValues(alpha: a * .25));
      canvas.drawCircle(Offset(x, y * size.height), rad, Paint()..color = const Color(0xFFFFF6D8).withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_MotesPainter o) => o.t != t;
}

class _ScenePainter extends CustomPainter {
  final Scene scene;
  final double t;
  final bool calm;
  _ScenePainter(this.scene, this.t, this.calm);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final (top, mid, bottom) = switch (scene) {
      Scene.night => (const Color(0xFF141B45), const Color(0xFF3B2F8F), const Color(0xFF8E5BE0)),
      Scene.ocean => (const Color(0xFF2F9BE6), const Color(0xFF58C6EE), const Color(0xFFB8EEF0)),
      Scene.forest => (const Color(0xFF2E9E78), const Color(0xFF8FD99A), const Color(0xFFE9F0A8)),
      Scene.treasure => (const Color(0xFFE8833A), const Color(0xFFFFC066), const Color(0xFFFFE9B0)),
      Scene.castle => (const Color(0xFF8E6BEF), const Color(0xFFF29BC7), const Color(0xFFFFD9B0)),
      Scene.day => (const Color(0xFF5E78F0), const Color(0xFFA48BF5), const Color(0xFFFFC9A8)),
    };
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, mid, bottom], stops: const [0, .55, 1])
              .createShader(rect));

    // sun / moon glow
    final glow = Paint()
      ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: scene == Scene.night ? .35 : .55), Colors.transparent])
          .createShader(Rect.fromCircle(center: Offset(w * .78, h * .16), radius: min(w, h) * .3));
    canvas.drawCircle(Offset(w * .78, h * .16), min(w, h) * .3, glow);

    // clouds drifting
    final cp = Paint()..color = Colors.white.withValues(alpha: scene == Scene.night ? .12 : .75);
    for (var i = 0; i < 5; i++) {
      final speed = .4 + i * .13;
      final x = ((t * speed + i * .23) % 1.2 - .1) * w;
      final y = h * (.07 + .09 * ((i * 37) % 5) / 4 + (i % 2) * .08);
      final r = min(w, h) * (.035 + .01 * (i % 3));
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 5, height: r * 1.6), cp);
      canvas.drawCircle(Offset(x - r * .8, y - r * .5), r * .9, cp);
      canvas.drawCircle(Offset(x + r * .6, y - r * .6), r * 1.1, cp);
    }

    // far hills
    final hill1 = switch (scene) {
      Scene.night => const Color(0xFF3A2D86),
      Scene.ocean => const Color(0xFF58B0D8),
      Scene.treasure => const Color(0xFFF2A55B),
      _ => const Color(0xFF8F7BE0),
    };
    final hill2 = switch (scene) {
      Scene.night => const Color(0xFF2B2370),
      Scene.ocean => const Color(0xFF3D98C8),
      Scene.treasure => const Color(0xFFE08B3C),
      Scene.castle => const Color(0xFF7BC47F),
      _ => const Color(0xFF56B87B),
    };
    Path hills(double base, double amp, double phase) {
      final p = Path()..moveTo(0, h);
      p.lineTo(0, h * base);
      for (var x = 0.0; x <= w; x += 8) {
        p.lineTo(x, h * base - sin(x / w * pi * 2 + phase) * h * amp);
      }
      p.lineTo(w, h);
      p.close();
      return p;
    }

    Shader hs(Color a, Color b, double base) => LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]).createShader(Rect.fromLTWH(0, h * (base - .06), w, h * .5));
    canvas.drawPath(hills(.72, .04, 1), Paint()..shader = hs(hill1, Color.lerp(hill1, Colors.black, .18)!, .72));

    // distant castle silhouette
    if (scene == Scene.day || scene == Scene.castle || scene == Scene.night) {
      Props.castle(canvas, w * .72, h * .72, min(w, h) * .26,
          wall: scene == Scene.night ? const Color(0xFF5A4BB0) : const Color(0xFFD9CCF8), roof: C.pink, roof2: const Color(0xFF7A8CFF));
    }

    canvas.drawPath(hills(.82, .035, 3), Paint()..shader = hs(Color.lerp(hill2, Colors.white, .12)!, hill2, .82));
    // tree line
    if (scene != Scene.ocean) {
      final tl = min(w, h) * .2;
      for (var i = 0; i < 9; i++) {
        final x = w * ((i * 0.13 + .02) % 1.0);
        final base = h * (.86 - sin(x / w * pi * 2 + 3) * .035) + h * .005;
        (i % 2 == 0)
            ? Props.pine(canvas, x, base, tl, light: scene == Scene.night ? const Color(0xFF5A6BE0) : const Color(0xFF3FBF7A), dark: scene == Scene.night ? const Color(0xFF3A46B0) : const Color(0xFF1F8F5A))
            : Props.roundTree(canvas, x, base, tl * .9, light: scene == Scene.treasure ? const Color(0xFFFFC85A) : const Color(0xFF6FD66F), dark: scene == Scene.treasure ? const Color(0xFFE08B2B) : const Color(0xFF2E9B4F));
      }
    }
    canvas.drawPath(hills(.94, .02, 0), Paint()..shader = hs(hill2, Color.lerp(hill2, Colors.black, .2)!, .94));

    // sparkles
    if (!calm) {
      final sp = Paint()..color = Colors.white.withValues(alpha: .8);
      for (var i = 0; i < 14; i++) {
        final ph = (t * 30 + i * .37) % 1;
        final x = w * ((i * 53 % 97) / 97);
        final y = h * (.15 + .6 * ((i * 31 % 89) / 89)) - ph * 12;
        final a = (sin(ph * pi)).clamp(0.0, 1.0);
        sp.color = Colors.white.withValues(alpha: a * .8);
        canvas.drawCircle(Offset(x, y), 1.6 + (i % 3), sp);
      }
    }
  }

  @override
  bool shouldRepaint(_ScenePainter o) => o.t != t || o.scene != scene || o.calm != calm;
}

// ======================================================================
// Island blob for the world map
// ======================================================================
class IslandPainter extends CustomPainter {
  final Color grass;
  final Color grassDark;
  final bool locked;
  IslandPainter(this.grass, this.grassDark, {this.locked = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final g = locked ? const Color(0xFF9AA3BF) : grass;
    final gd = locked ? const Color(0xFF7A83A0) : grassDark;
    // shadow on water
    canvas.drawOval(Rect.fromLTWH(w * .08, h * .72, w * .84, h * .24), Paint()..color = const Color(0x22000000));
    // rock underside
    final rock = Path()
      ..moveTo(w * .06, h * .52)
      ..quadraticBezierTo(w * .1, h * .88, w * .5, h * .94)
      ..quadraticBezierTo(w * .9, h * .88, w * .94, h * .52)
      ..close();
    canvas.drawPath(rock, Paint()..color = const Color(0xFF8B6B4E));
    final rock2 = Path()
      ..moveTo(w * .2, h * .6)
      ..quadraticBezierTo(w * .3, h * .86, w * .5, h * .9)
      ..quadraticBezierTo(w * .44, h * .74, w * .3, h * .6)
      ..close();
    canvas.drawPath(rock2, Paint()..color = const Color(0xFF6E5139));
    // grass top
    final top = Path()
      ..moveTo(w * .02, h * .5)
      ..cubicTo(w * .0, h * .2, w * .26, h * .06, w * .5, h * .06)
      ..cubicTo(w * .78, h * .06, w * 1.0, h * .22, w * .98, h * .5)
      ..cubicTo(w * .9, h * .64, w * .64, h * .68, w * .5, h * .68)
      ..cubicTo(w * .34, h * .68, w * .1, h * .64, w * .02, h * .5)
      ..close();
    canvas.drawPath(top, Paint()..color = g);
    canvas.drawPath(
        Path()
          ..moveTo(w * .02, h * .5)
          ..cubicTo(w * .1, h * .64, w * .34, h * .68, w * .5, h * .68)
          ..cubicTo(w * .64, h * .68, w * .9, h * .64, w * .98, h * .5)
          ..cubicTo(w * .8, h * .56, w * .6, h * .58, w * .5, h * .58)
          ..cubicTo(w * .4, h * .58, w * .2, h * .56, w * .02, h * .5)
          ..close(),
        Paint()..color = gd);
  }

  @override
  bool shouldRepaint(IslandPainter o) => o.locked != locked || o.grass != grass;
}

class WavesPainter extends CustomPainter {
  final double t;
  WavesPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF63D2F2), Color(0xFF2A8FD6), Color(0xFF1D5FB8)])
              .createShader(rect));
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 6; c++) {
        final x = size.width * ((c + (r.isEven ? .25 : .75)) / 6) + sin(t * 2 * pi + r) * 6;
        final y = size.height * (r + .5) / 9;
        final path = Path()
          ..moveTo(x - 14, y)
          ..quadraticBezierTo(x - 7, y - 6, x, y)
          ..quadraticBezierTo(x + 7, y + 6, x + 14, y);
        canvas.drawPath(path, p);
      }
    }
    for (var i = 0; i < 18; i++) {
      final tw = (sin((t * 6 + i) * 1.7) + 1) / 2;
      Props.sparkle(canvas, size.width * ((i * 41 % 100) / 100), size.height * ((i * 67 % 100) / 100), 2 + tw * 2.5, color: Colors.white.withValues(alpha: .25 + .5 * tw));
    }
    Props.cloud(canvas, size.width * (.1 + .8 * ((t * 1.0) % 1)), size.height * .05, size.width * .12, alpha: .35);
  }

  @override
  bool shouldRepaint(WavesPainter o) => o.t != t;
}
