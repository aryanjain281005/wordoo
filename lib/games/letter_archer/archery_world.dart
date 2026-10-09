import 'dart:math';
import 'dart:ui';

/// The physics and state of Letter Archer, kept free of Flame/Flutter widgets so it can be unit-tested.
/// Coordinates are in logical pixels of the game area (origin top-left).
class ArcheryWorld {
  final int lanterns;
  final double drift; // 0 = still, 1 = gentle drift, 2 = breeze
  final bool aimGuide; // scaffold: dotted aiming line
  final void Function(int lantern) onHit;
  final void Function()? onMiss;

  ArcheryWorld({required this.lanterns, this.drift = 0, this.aimGuide = false, required this.onHit, this.onMiss});

  Size size = const Size(360, 480);
  double t = 0;
  final Set<int> dimmed = {}; // wrong or faded lanterns
  final Set<int> lit = {}; // hit correctly: glowing and rising
  int? glow; // lantern to highlight (reveal after misses)
  final Map<int, double> wobble = {}; // lantern → time left of the "thunk" wobble
  final Map<int, double> rise = {}; // lit lantern → seconds since it lit
  bool locked = false; // no more shots (item resolved)

  // arrow
  Offset? arrow; // position while flying
  Offset vel = Offset.zero;
  Offset pull = Offset.zero; // bow drawn back by this vector (from the nock point)
  bool aiming = false;
  final List<Spark> sparks = [];
  String? fireworksText;
  double fireworksT = 0;

  static const speed = 1100.0;

  double get radius => min(size.width, size.height) * .1;
  Offset get bow => Offset(size.width / 2, size.height - 70);
  Offset get nock => bow + pull;

  Offset home(int i) => Offset(size.width * (i + 1) / (lanterns + 1), size.height * (.2 + (i.isOdd ? .17 : 0)));

  Offset lanternAt(int i, [double? at]) {
    final tt = at ?? t;
    final h = home(i);
    final up = rise[i] == null ? 0.0 : -pow(rise[i]!, 1.6) * 90;
    // sway stays inside each lantern's own lane, so neighbours never overlap
    final lane = size.width / (lanterns + 1);
    final amp = min(drift * size.width * .06, max(0.0, (lane - radius * 1.9) / 2));
    return h + Offset(sin(tt * (.6 + .15 * i) + i * 2.1) * amp, cos(tt * .9 + i) * 5 + up);
  }

  // ---------------- input ----------------
  void startAim() {
    if (locked || arrow != null) return;
    aiming = true;
  }

  void dragAim(Offset delta) {
    if (!aiming) return;
    var p = pull + delta;
    final maxPull = size.height * .22;
    if (p.distance > maxPull) p = p / p.distance * maxPull;
    if (p.dy < 0) p = Offset(p.dx, 0); // you can only pull the string back (down)
    pull = p;
  }

  /// Let go of the string: the arrow flies opposite to the pull.
  bool release() {
    if (!aiming) return false;
    aiming = false;
    final p = pull;
    pull = Offset.zero;
    if (p.distance < 18) return false; // too gentle a pull: nothing happens
    fire(-p / p.distance);
    return true;
  }

  /// Tap a lantern: an auto-aimed arrow flies to where the lantern will be.
  bool autoFire(int i) {
    if (locked || arrow != null || i < 0 || i >= lanterns) return false;
    var target = lanternAt(i);
    for (var k = 0; k < 3; k++) {
      final eta = (target - bow).distance / speed;
      target = lanternAt(i, t + eta);
    }
    final d = target - bow;
    fire(d / d.distance);
    return true;
  }

  void fire(Offset dir) {
    arrow = bow;
    vel = dir * speed;
  }

  int? lanternAtPoint(Offset p) {
    for (var i = 0; i < lanterns; i++) {
      if ((lanternAt(i) - p).distance < radius * 1.3) return i;
    }
    return null;
  }

  /// Points of the aiming guide (straight line in the shooting direction).
  List<Offset> guide() {
    if (!aiming || pull.distance < 8) return const [];
    final dir = -pull / pull.distance;
    return [for (var k = 1; k <= 12; k++) bow + dir * (k * 28.0)];
  }

  // ---------------- simulation ----------------
  void update(double dt) {
    t += dt;
    for (final k in wobble.keys.toList()) {
      wobble[k] = wobble[k]! - dt;
      if (wobble[k]! <= 0) wobble.remove(k);
    }
    for (final k in rise.keys.toList()) {
      rise[k] = rise[k]! + dt;
    }
    if (fireworksText != null) fireworksT += dt;
    for (final s in sparks) {
      s.update(dt);
    }
    sparks.removeWhere((s) => s.life <= 0);

    final a = arrow;
    if (a == null) return;
    final next = a + vel * dt;
    // hit test along the path (fast arrows must not skip over a lantern)
    for (var i = 0; i < lanterns; i++) {
      if (lit.contains(i)) continue;
      final c = lanternAt(i);
      if (_segmentDist(a, next, c) < radius * .95) {
        arrow = null;
        _burst(c, i);
        onHit(i);
        return;
      }
    }
    arrow = next;
    if (next.dy < -40 || next.dx < -40 || next.dx > size.width + 40) {
      arrow = null;
      onMiss?.call();
    }
  }

  void markLit(int i) {
    lit.add(i);
    rise[i] = 0;
    final c = lanternAt(i);
    for (var k = 0; k < 26; k++) {
      sparks.add(Spark.random(c, const Color(0xFFFFD45C)));
    }
  }

  void markWrong(int i) {
    dimmed.add(i);
    wobble[i] = .6;
  }

  void startFireworks(String text) {
    fireworksText = text;
    fireworksT = 0;
    final rng = Random();
    for (var b = 0; b < 5; b++) {
      final c = Offset(size.width * (.15 + rng.nextDouble() * .7), size.height * (.15 + rng.nextDouble() * .35));
      final col = [const Color(0xFFFF6B9A), const Color(0xFFFFD45C), const Color(0xFF7CE0FF), const Color(0xFFB98CFF)][b % 4];
      for (var k = 0; k < 30; k++) {
        sparks.add(Spark.random(c, col, speed: 220, life: 1.6));
      }
    }
  }

  void _burst(Offset c, int i) {
    for (var k = 0; k < 10; k++) {
      sparks.add(Spark.random(c, const Color(0xFFFFF3C4), speed: 120, life: .5));
    }
  }

  static double _segmentDist(Offset a, Offset b, Offset p) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final tt = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2).clamp(0.0, 1.0);
    return (p - (a + ab * tt)).distance;
  }
}

class Spark {
  Offset p, v;
  double life;
  final double maxLife;
  final Color color;
  Spark(this.p, this.v, this.life, this.color) : maxLife = life;

  factory Spark.random(Offset at, Color c, {double speed = 160, double life = 1.0}) {
    final r = Random();
    final a = r.nextDouble() * 2 * pi;
    final s = speed * (.4 + r.nextDouble() * .8);
    return Spark(at, Offset(cos(a) * s, sin(a) * s), life * (.6 + r.nextDouble() * .5), c);
  }

  void update(double dt) {
    p += v * dt;
    v = Offset(v.dx * .96, v.dy * .96 + 60 * dt);
    life -= dt;
  }
}
