import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/audio.dart';
import '../core/theme.dart';
import '../widgets/art.dart';
import '../widgets/props.dart';

/// Who can appear in a story scene. Guardians use a portrait placeholder until their art arrives
/// (manifest id `char.<id>`), the three main characters are fully animated puppets.
class StoryCharacter {
  final String id, name, emoji;
  final Color color;
  const StoryCharacter(this.id, this.name, this.emoji, this.color);
}

const storyCast = <String, StoryCharacter>{
  'milo': StoryCharacter('milo', 'Milo', '🦊', Color(0xFFF58A2B)),
  'gumsum': StoryCharacter('gumsum', 'Gumsum', '☁️', Color(0xFF8E9BB8)),
  'dadi': StoryCharacter('dadi', 'Dadi Kahani', '🌳', Color(0xFF3FAF5F)),
  'bhalu': StoryCharacter('bhalu', 'Maestro Bhalu', '🐻', Color(0xFFC0662B)),
  'arya': StoryCharacter('arya', 'Arya the Archer', '🏹', Color(0xFF8E5BE0)),
  'kachhua': StoryCharacter('kachhua', 'Captain Kachhua', '🐢', Color(0xFF2E9E8F)),
  'ullu': StoryCharacter('ullu', 'Inspector Ullu', '🦉', Color(0xFF8A5A30)),
  'madhu': StoryCharacter('madhu', 'Queen Madhu', '🐝', Color(0xFFE0A100)),
  'pari': StoryCharacter('pari', 'Princess Pari', '👑', Color(0xFFE0568A)),
  'kitabu': StoryCharacter('kitabu', 'Kitabu', '📖', Color(0xFF6C4DF0)),
  'bolt': StoryCharacter('bolt', 'Bolt', '🤖', Color(0xFF5A72D8)),
};

/// An animated character: breathes, blinks, and moves its mouth with the voice line it is speaking.
class Puppet extends StatefulWidget {
  final String id;
  final double size;
  final String mood; // happy | sad | surprised | thinking
  final double lightness; // Gumsum gets lighter each season (0 storm-grey … 1 fluffy white)
  final int companionType; // Milo can be fox / panda / dragon as chosen by the child
  const Puppet({super.key, required this.id, this.size = 140, this.mood = 'happy', this.lightness = 0, this.companionType = 0});
  @override
  State<Puppet> createState() => _PuppetState();
}

class _PuppetState extends State<Puppet> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  bool _blink = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(Duration(milliseconds: 2800 + widget.id.hashCode % 900), (_) async {
      if (!mounted) return;
      setState(() => _blink = true);
      await Future.delayed(const Duration(milliseconds: 130));
      if (mounted) setState(() => _blink = false);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = AudioManager.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([_c, a.mouth, a.speaking]),
      builder: (_, __) {
        final talking = a.speaking.value == widget.id;
        final mouth = talking ? a.mouth.value : 0.0;
        final bob = sin(_c.value * pi) * (talking ? -6 : -3);
        final squash = 1 + (talking ? mouth * .03 : sin(_c.value * pi) * .012);
        Widget body;
        switch (widget.id) {
          case 'milo':
            body = CustomPaint(painter: CreaturePainter(widget.companionType, wag: _c.value * 2 - 1, blink: _blink, mouth: mouth, mood: widget.mood, happy: widget.mood != 'sad'));
            break;
          case 'gumsum':
            body = CustomPaint(painter: CloudPainter(mouth: mouth, blink: _blink, mood: widget.mood, lightness: widget.lightness, t: _c.value));
            break;
          case 'dadi':
            body = CustomPaint(painter: GrandmaPainter(mouth: mouth, blink: _blink, glow: .6 + .4 * _c.value));
            break;
          default:
            body = GuardianPortrait(id: widget.id, talking: talking, mouth: mouth);
        }
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.scale(
            scaleY: squash,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: ArtImage('char.${widget.id}.${widget.mood}', fallback: ArtImage('char.${widget.id}', fallback: body)),
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder for guardians until their illustrations exist: a framed portrait that pulses while speaking.
class GuardianPortrait extends StatelessWidget {
  final String id;
  final bool talking;
  final double mouth;
  const GuardianPortrait({super.key, required this.id, this.talking = false, this.mouth = 0});
  @override
  Widget build(BuildContext context) {
    final c = storyCast[id] ?? storyCast['milo']!;
    return LayoutBuilder(builder: (_, box) {
      final s = box.biggest.shortestSide;
      return Stack(alignment: Alignment.center, children: [
        Container(
          width: s * .92,
          height: s * .92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [Color.lerp(c.color, Colors.white, .55)!, c.color]),
            border: Border.all(color: const Color(0xFFE8C46A), width: s * .045),
            boxShadow: [BoxShadow(color: c.color.withValues(alpha: talking ? .7 : .35), blurRadius: talking ? 22 + mouth * 20 : 12)],
          ),
          alignment: Alignment.center,
          child: Transform.scale(scale: 1 + mouth * .06, child: Text(c.emoji, style: TextStyle(fontSize: s * .48))),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: s * .06, vertical: s * .015),
            decoration: BoxDecoration(color: const Color(0xFF262A66), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8C46A), width: 1.5)),
            child: Text(c.name, style: ts(max(9, s * .085), color: Colors.white)),
          ),
        ),
      ]);
    });
  }
}

/// Gumsum, the lonely hush-cloud. [lightness] goes from storm-grey (season 1) to fluffy white (later seasons).
class CloudPainter extends CustomPainter {
  final double mouth, lightness, t;
  final bool blink;
  final String mood;
  CloudPainter({this.mouth = 0, this.blink = false, this.mood = 'happy', this.lightness = 0, this.t = 0});
  @override
  void paint(Canvas c, Size size) {
    final s = size.shortestSide;
    final base = Color.lerp(const Color(0xFF7D879E), const Color(0xFFF4F7FF), lightness.clamp(0, 1))!;
    final dark = Color.lerp(base, Colors.black, .18)!;
    c.drawOval(Rect.fromCenter(center: Offset(s * .5, s * .93), width: s * .5, height: s * .06), Paint()..color = const Color(0x22000000));
    final p = Paint()..shader = RadialGradient(center: const Alignment(-.3, -.5), colors: [Color.lerp(base, Colors.white, .35)!, base, dark]).createShader(Offset.zero & size);
    for (final (x, y, r) in [(.28, .58, .2), (.5, .45, .27), (.72, .58, .2), (.4, .66, .2), (.6, .66, .2)]) {
      c.drawCircle(Offset(s * x, s * y), s * r, p);
    }
    // letters floating inside (the words he swallowed)
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < 4; i++) {
      final ch = ['a', 'b', 'k', 'm'][i];
      tp.text = TextSpan(text: ch, style: TextStyle(fontSize: s * .07, color: Colors.white.withValues(alpha: .35 + .2 * lightness), fontWeight: FontWeight.w700));
      tp.layout();
      tp.paint(c, Offset(s * (.3 + i * .13), s * (.62 + .04 * sin(t * pi * 2 + i))));
    }
    // eyes
    final eyeY = s * .45;
    final ink = Paint()..color = const Color(0xFF2A3050);
    if (blink) {
      final b = Paint()
        ..color = const Color(0xFF2A3050)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .02
        ..strokeCap = StrokeCap.round;
      c.drawArc(Rect.fromCenter(center: Offset(s * .41, eyeY), width: s * .09, height: s * .05), 0, pi, false, b);
      c.drawArc(Rect.fromCenter(center: Offset(s * .59, eyeY), width: s * .09, height: s * .05), 0, pi, false, b);
    } else {
      for (final x in [.41, .59]) {
        c.drawOval(Rect.fromCenter(center: Offset(s * x, eyeY), width: s * .1, height: s * .13), ink);
        c.drawCircle(Offset(s * (x + .015), eyeY - s * .03), s * .022, Paint()..color = Colors.white);
      }
    }
    // mouth
    if (mouth > .06) {
      c.drawOval(Rect.fromCenter(center: Offset(s * .5, s * .56), width: s * (.06 + .04 * mouth), height: s * (.03 + .07 * mouth)), Paint()..color = const Color(0xFF4A2A40));
    } else {
      final m = Paint()
        ..color = const Color(0xFF2A3050)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .016
        ..strokeCap = StrokeCap.round;
      final sad = mood == 'sad';
      c.drawPath(Path()..moveTo(s * .45, sad ? s * .58 : s * .555)..quadraticBezierTo(s * .5, sad ? s * .54 : s * .6, s * .55, sad ? s * .58 : s * .555), m);
    }
    c.drawCircle(Offset(s * .33, s * .53), s * .035, Paint()..color = const Color(0x40FF6FA5));
    c.drawCircle(Offset(s * .67, s * .53), s * .035, Paint()..color = const Color(0x40FF6FA5));
  }

  @override
  bool shouldRepaint(CloudPainter o) => o.mouth != mouth || o.blink != blink || o.t != t || o.lightness != lightness || o.mood != mood;
}

/// Dadi Kahani, the warm storyteller grandmother who lives in the Story Tree.
class GrandmaPainter extends CustomPainter {
  final double mouth, glow;
  final bool blink;
  GrandmaPainter({this.mouth = 0, this.blink = false, this.glow = 1});
  @override
  void paint(Canvas c, Size size) {
    final s = size.shortestSide;
    c.drawCircle(Offset(s * .5, s * .45), s * .48, Paint()..shader = RadialGradient(colors: [const Color(0xFFFFF3B0).withValues(alpha: .55 * glow), const Color(0x00FFF3B0)]).createShader(Offset.zero & size));
    // shawl of leaves
    final shawl = Path()
      ..moveTo(s * .14, s * .96)
      ..quadraticBezierTo(s * .18, s * .6, s * .5, s * .58)
      ..quadraticBezierTo(s * .82, s * .6, s * .86, s * .96)
      ..close();
    c.drawPath(shawl, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF52C27A), Color(0xFF2E8B57)]).createShader(Offset.zero & size));
    for (var i = 0; i < 7; i++) {
      final x = s * (.22 + i * .093), y = s * (.82 + (i.isEven ? 0 : .05));
      c.save();
      c.translate(x, y);
      c.rotate(i.isEven ? .5 : -.5);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * .07, height: s * .035), Paint()..color = const Color(0xFF8FE09E));
      c.restore();
    }
    // face
    const skin = Color(0xFFE9B98F);
    c.drawCircle(Offset(s * .5, s * .42), s * .2, Paint()..shader = RadialGradient(center: const Alignment(-.3, -.4), colors: [const Color(0xFFF6D3B0), skin]).createShader(Rect.fromCircle(center: Offset(s * .5, s * .42), radius: s * .2)));
    // white hair + bun
    final hair = Paint()..color = const Color(0xFFF1F1F6);
    c.drawCircle(Offset(s * .5, s * .18), s * .085, hair);
    c.drawPath(Path()..moveTo(s * .3, s * .42)..quadraticBezierTo(s * .28, s * .2, s * .5, s * .22)..quadraticBezierTo(s * .72, s * .2, s * .7, s * .42)..quadraticBezierTo(s * .62, s * .3, s * .5, s * .3)..quadraticBezierTo(s * .38, s * .3, s * .3, s * .42)..close(), hair);
    // glasses
    final g = Paint()
      ..color = const Color(0xFF7A4E2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .013;
    c.drawCircle(Offset(s * .43, s * .42), s * .055, g);
    c.drawCircle(Offset(s * .57, s * .42), s * .055, g);
    c.drawLine(Offset(s * .485, s * .42), Offset(s * .515, s * .42), g);
    final ink = Paint()..color = const Color(0xFF3A2A20);
    if (blink) {
      c.drawLine(Offset(s * .41, s * .425), Offset(s * .45, s * .425), Paint()..color = const Color(0xFF3A2A20)..strokeWidth = s * .012);
      c.drawLine(Offset(s * .55, s * .425), Offset(s * .59, s * .425), Paint()..color = const Color(0xFF3A2A20)..strokeWidth = s * .012);
    } else {
      c.drawCircle(Offset(s * .43, s * .42), s * .018, ink);
      c.drawCircle(Offset(s * .57, s * .42), s * .018, ink);
    }
    c.drawCircle(Offset(s * .38, s * .49), s * .03, Paint()..color = const Color(0x40FF6F7A));
    c.drawCircle(Offset(s * .62, s * .49), s * .03, Paint()..color = const Color(0x40FF6F7A));
    if (mouth > .06) {
      c.drawOval(Rect.fromCenter(center: Offset(s * .5, s * .52), width: s * (.06 + .03 * mouth), height: s * (.02 + .05 * mouth)), Paint()..color = const Color(0xFF7A2A30));
    } else {
      c.drawArc(Rect.fromCenter(center: Offset(s * .5, s * .5), width: s * .1, height: s * .06), .2, pi - .4, false, Paint()
        ..color = const Color(0xFF7A2A30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .012
        ..strokeCap = StrokeCap.round);
    }
    // bindi
    c.drawCircle(Offset(s * .5, s * .335), s * .012, Paint()..color = const Color(0xFFE5483F));
  }

  @override
  bool shouldRepaint(GrandmaPainter o) => o.mouth != mouth || o.blink != blink || o.glow != glow;
}

/// The great Story Tree of Aksharpur (background for story scenes). [color] 0 = drained grey, 1 = full colour.
class StoryTreePainter extends CustomPainter {
  final double color, t;
  StoryTreePainter({this.color = 1, this.t = 0});
  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    Color k(Color a) => Color.lerp(Color.lerp(a, const Color(0xFF8A8F9E), .85)!, a, color)!;
    final rect = Offset.zero & size;
    c.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [k(const Color(0xFF2B2A7A)), k(const Color(0xFF7A5BD8)), k(const Color(0xFFF2A6C8))]).createShader(rect));
    for (var i = 0; i < 30; i++) {
      final tw = (sin((t * 6 + i) * 1.7) + 1) / 2;
      Props.sparkle(c, w * ((i * 37 % 100) / 100), h * ((i * 53 % 100) / 260), 1.5 + tw * 2, color: Colors.white.withValues(alpha: .3 + .5 * tw * color));
    }
    // floating island under the tree
    c.drawOval(Rect.fromCenter(center: Offset(w * .5, h * .86), width: w * 1.1, height: h * .22), Paint()..color = k(const Color(0xFF3FAF5F)));
    c.drawPath(Path()..moveTo(w * -.05, h * .86)..quadraticBezierTo(w * .5, h * 1.25, w * 1.05, h * .86)..close(), Paint()..color = k(const Color(0xFF7A5536)));
    // trunk
    final trunk = Path()
      ..moveTo(w * .42, h * .86)
      ..quadraticBezierTo(w * .45, h * .6, w * .4, h * .42)
      ..lineTo(w * .6, h * .42)
      ..quadraticBezierTo(w * .55, h * .6, w * .58, h * .86)
      ..close();
    c.drawPath(trunk, Paint()..shader = LinearGradient(colors: [k(const Color(0xFF8A5A30)), k(const Color(0xFF5C3A1E))]).createShader(rect));
    // canopy
    for (final (x, y, r) in [(.5, .3, .26), (.28, .38, .17), (.72, .38, .17), (.38, .22, .15), (.62, .22, .15)]) {
      c.drawCircle(Offset(w * x, h * y), min(w, h) * r, Paint()..shader = RadialGradient(center: const Alignment(-.3, -.4), colors: [k(const Color(0xFF8FE09E)), k(const Color(0xFF2E9B57))]).createShader(Rect.fromCircle(center: Offset(w * x, h * y), radius: min(w, h) * r)));
    }
    // glowing word-leaves
    final rng = Random(4);
    for (var i = 0; i < 22; i++) {
      final x = w * (.24 + rng.nextDouble() * .52), y = h * (.1 + rng.nextDouble() * .38);
      final pulse = (sin(t * pi * 2 + i) + 1) / 2;
      c.drawCircle(Offset(x, y), 4 + pulse * 3, Paint()..color = const Color(0xFFFFE17A).withValues(alpha: (.35 + .5 * pulse) * color));
    }
  }

  @override
  bool shouldRepaint(StoryTreePainter o) => o.color != color || o.t != t;
}

/// Small helper so other screens can show the right puppet for a speaker id.
Widget puppetFor(String id, {double size = 120, String mood = 'happy', int companion = 0, double lightness = 0}) =>
    Puppet(id: id, size: size, mood: mood, companionType: companion, lightness: lightness);

TextStyle speakerNameStyle(Color c) => ts(15, color: c);
