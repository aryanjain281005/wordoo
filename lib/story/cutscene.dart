import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../core/assets.dart';
import '../core/audio.dart';
import '../core/theme.dart';
import '../widgets/art.dart';
import '../widgets/hero.dart';
import 'puppets.dart';
import 'story_lines.dart';

/// One character on screen during a shot.
class CastSpec {
  final String id;
  final double x; // 0..1 horizontal position
  final String mood;
  final String enter; // none | left | right | pop | float
  final double size; // fraction of screen width
  final double y; // 0 = standing on the ground … 1 = top of the screen
  final String cage; // none | closed | open (v3: Story Keepers in Gumsum's cloud cages)
  final bool burst; // colour flash + sticker outline behind the character (Nessy-style spotlight)
  const CastSpec(this.id, {this.x = .5, this.mood = 'happy', this.enter = 'pop', this.size = .38, this.y = 0, this.cage = 'none', this.burst = false});
  factory CastSpec.fromJson(Map<String, dynamic> j) => CastSpec(j['id'] as String,
      x: (j['x'] as num?)?.toDouble() ?? .5,
      mood: j['mood'] as String? ?? 'happy',
      enter: j['enter'] as String? ?? 'pop',
      size: (j['size'] as num?)?.toDouble() ?? .38,
      y: (j['y'] as num?)?.toDouble() ?? 0,
      cage: j['cage'] as String? ?? 'none',
      burst: j['burst'] as bool? ?? false);
}

/// One shot = background + camera move + characters + (optional) one voice line + effect + sound.
class Shot {
  final String bg;
  final String fx; // none | grey | greying | colour | sparkle | light | storm
  final List<CastSpec> cast;
  final String? line;
  final String? sfx;
  final double zoomFrom, zoomTo, panFrom, panTo;
  final int minMs;
  final String? video; // AI video clip (assets/video/<video>.mp4); when present it replaces the picture + cast
  final String? card; // big title card (e.g. the Storm Trial rules)
  const Shot({this.bg = 'tree', this.fx = 'none', this.cast = const [], this.line, this.sfx, this.zoomFrom = 1, this.zoomTo = 1.06, this.panFrom = 0, this.panTo = 0, this.minMs = 2500, this.video, this.card});
  factory Shot.fromJson(Map<String, dynamic> j) {
    final cam = (j['camera'] as Map?) ?? const {};
    List<double> pair(dynamic v, List<double> d) => v == null ? d : [for (final x in v as List) (x as num).toDouble()];
    final z = pair(cam['zoom'], [1, 1.06]), p = pair(cam['pan'], [0, 0]);
    return Shot(
      bg: j['bg'] as String? ?? 'tree',
      fx: j['fx'] as String? ?? 'none',
      cast: [for (final c in (j['cast'] as List? ?? const [])) CastSpec.fromJson(Map<String, dynamic>.from(c as Map))],
      line: j['line'] as String?,
      sfx: j['sfx'] as String?,
      zoomFrom: z[0],
      zoomTo: z[1],
      panFrom: p[0],
      panTo: p[1],
      minMs: j['ms'] as int? ?? 2500,
      video: j['video'] as String?,
      card: j['card'] as String?,
    );
  }
}

class Cutscene {
  final String id, title;
  final List<Shot> shots;
  const Cutscene(this.id, this.title, this.shots);
  static Future<Cutscene> load(String id) async {
    final j = jsonDecode(await rootBundle.loadString('assets/cutscenes/$id.json')) as Map<String, dynamic>;
    return Cutscene(id, j['title'] as String? ?? id, [for (final s in j['shots'] as List) Shot.fromJson(Map<String, dynamic>.from(s as Map))]);
  }
}

/// Plays a cutscene full-screen. Tap = next line. "Skip" appears after the first shot
/// (or immediately if [canSkip], e.g. when the scene was already seen).
class CutsceneScreen extends StatefulWidget {
  final String sceneId;
  final bool canSkip;
  final int companion;
  final double gumsumLightness;
  const CutsceneScreen({super.key, required this.sceneId, this.canSkip = false, this.companion = 0, this.gumsumLightness = 0});
  @override
  State<CutsceneScreen> createState() => _CutsceneScreenState();
}

class _CutsceneScreenState extends State<CutsceneScreen> with TickerProviderStateMixin {
  Cutscene? scene;
  int i = 0;
  bool _skipShot = false;
  bool _closing = false;
  late final AnimationController _cam = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  late final AnimationController _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

  String? _musicBefore;
  VideoPlayerController? _video; // the AI clip of the current shot, if one exists

  static String _videoPath(String id) => 'assets/video/$id.mp4';

  /// Starts the shot's clip (muted: voices, music and effects come from the app). Returns its length.
  Future<Duration?> _playVideo(Shot s) async {
    final old = _video;
    _video = null;
    old?.dispose();
    final v = s.video;
    if (v == null || !ReadleAssets.instance.bundled(_videoPath(v))) return null;
    try {
      final c = VideoPlayerController.asset(_videoPath(v));
      await c.initialize();
      await c.setVolume(0);
      if (!mounted || _closing) {
        c.dispose();
        return null;
      }
      setState(() => _video = c);
      await c.play();
      return c.value.duration;
    } catch (e) {
      debugPrint('video $v: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _musicBefore = AudioManager.instance.currentMusic;
    AudioManager.instance.music('music.story');
    _start();
  }

  Future<void> _start() async {
    await StoryLines.instance.load();
    try {
      scene = await Cutscene.load(widget.sceneId);
    } catch (e) {
      debugPrint('cutscene ${widget.sceneId}: $e');
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (!mounted) return;
    setState(() {});
    for (i = 0; i < scene!.shots.length; i++) {
      if (!mounted || _closing) return;
      final s = scene!.shots[i];
      setState(() => _skipShot = false);
      _cam.duration = Duration(milliseconds: max(s.minMs, 3500));
      _cam.forward(from: 0);
      if (s.sfx != null) AudioManager.instance.sfx(s.sfx!);
      final clip = await _playVideo(s);
      final sw = Stopwatch()..start();
      if (s.line != null) {
        final l = StoryLines.instance[s.line!];
        if (l != null) {
          await Future.any([AudioManager.instance.voice(s.line!, l.text, character: l.who), _waitSkip()]);
        }
      }
      final rest = max(s.minMs, clip?.inMilliseconds ?? 0) - sw.elapsedMilliseconds;
      if (rest > 0 && !_skipShot) await Future.any([Future.delayed(Duration(milliseconds: rest)), _waitSkip()]);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    _close();
  }

  Future<void> _waitSkip() async {
    while (mounted && !_skipShot && !_closing) {
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  void _next() {
    AudioManager.instance.stopVoice();
    setState(() => _skipShot = true);
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    AudioManager.instance.stopVoice();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _closing = true;
    AudioManager.instance.stopVoice();
    if (_musicBefore != null) AudioManager.instance.music(_musicBefore!);
    _video?.dispose();
    _cam.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sc = scene;
    if (sc == null) return const Scaffold(backgroundColor: Colors.black);
    final shot = sc.shots[i.clamp(0, sc.shots.length - 1)];
    final line = shot.line == null ? null : StoryLines.instance[shot.line!];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: LayoutBuilder(builder: (context, box) {
          final vid = _video;
          final showVideo = vid != null && vid.value.isInitialized && shot.video != null;
          return Stack(fit: StackFit.expand, children: [
            if (showVideo)
              FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: vid.value.size.width, height: vid.value.size.height, child: VideoPlayer(vid)))
            else ...[
            AnimatedBuilder(
              animation: _cam,
              builder: (_, child) {
                final t = Curves.easeInOut.transform(_cam.value);
                final z = shot.zoomFrom + (shot.zoomTo - shot.zoomFrom) * t;
                final p = shot.panFrom + (shot.panTo - shot.panFrom) * t;
                // zoom in at least enough that panning never shows the edge of the picture
                final zz = max(z, 1 + 2 * p.abs() + .02);
                return Transform.translate(offset: Offset(0, p * box.maxHeight), child: Transform.scale(scale: zz, child: child));
              },
              child: AnimatedSwitcher(duration: const Duration(milliseconds: 700), child: KeyedSubtree(key: ValueKey('bg$i${shot.bg}'), child: SizedBox.expand(child: _background(shot)))),
            ),
            _fx(shot),
            for (final c in shot.cast) _castMember(c, box, i),
            ],
            if (shot.card != null) _card(shot.card!),
            if (line != null)
              Positioned(
                left: 14,
                right: 14,
                bottom: 30,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(shot.line),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    decoration: BoxDecoration(color: const Color(0xEE1B1F4B), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE8C46A), width: 2)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(storyCast[line.who]?.name ?? line.who, style: ts(14, color: const Color(0xFFFFE17A))),
                      const SizedBox(height: 4),
                      Text(line.text, style: ts(19, color: Colors.white, h: 1.3)),
                    ]),
                  ),
                ),
              ),
            if (widget.canSkip || i > 0)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 12,
                child: TextButton(
                  onPressed: _close,
                  style: TextButton.styleFrom(backgroundColor: Colors.black38, foregroundColor: Colors.white, shape: const StadiumBorder()),
                  child: const Text('Skip ▶▶'),
                ),
              ),
          ]);
        }),
      ),
    );
  }

  Widget _background(Shot s) {
    if (s.bg.startsWith('art:')) {
      final id = s.bg.substring(4);
      final storm = id.endsWith('~storm'); // "~storm": the picture in stormy grey
      final art = ArtImage(storm ? id.substring(0, id.length - 6) : id, fit: BoxFit.cover, fallback: const AdventureBackground(scene: Scene.night));
      return storm ? ColorFiltered(colorFilter: const ColorFilter.matrix(_stormMatrix), child: art) : art;
    }
    final fallback = switch (s.bg) {
      'tree' || 'tree_grey' => AnimatedBuilder(animation: _ambient, builder: (_, __) => CustomPaint(painter: StoryTreePainter(color: s.bg == 'tree_grey' ? 0 : 1, t: _ambient.value))),
      'aksharpur' => const HeroScene(),
      'night' => const AdventureBackground(scene: Scene.night),
      'forest' => const AdventureBackground(scene: Scene.forest),
      'castle' => const AdventureBackground(scene: Scene.castle),
      'sea' => AnimatedBuilder(animation: _ambient, builder: (_, __) => CustomPaint(painter: WavesPainter(_ambient.value))),
      _ => const AdventureBackground(scene: Scene.day),
    };
    // until the dedicated cutscene picture exists, borrow the closest finished background
    const borrow = {'night': 'bg.night', 'forest': 'bg.forest', 'castle': 'bg.island.castle', 'day': 'bg.day', 'sea': 'bg.island.ocean'};
    final alt = borrow[s.bg];
    return ArtImage('bg.cut.${s.bg}', fit: BoxFit.cover, fallback: alt == null ? fallback : ArtImage(alt, fit: BoxFit.cover, fallback: fallback));
  }

  Widget _fx(Shot s) {
    switch (s.fx) {
      case 'greying':
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _cam,
            builder: (_, __) => Container(color: const Color(0xFF59607A).withValues(alpha: .65 * _cam.value)),
          ),
        );
      case 'grey':
        return IgnorePointer(child: Container(color: const Color(0x8859607A)));
      case 'storm':
        return IgnorePointer(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xAA1B1F3B), Color(0x441B1F3B)]))));
      case 'light':
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _cam,
            builder: (_, __) => Container(decoration: BoxDecoration(gradient: RadialGradient(colors: [Colors.white.withValues(alpha: .85 * (1 - _cam.value)), Colors.white.withValues(alpha: 0)], radius: .9))),
          ),
        );
      case 'rain' || 'sparkle' || 'keys' || 'lightning':
        return IgnorePointer(child: AnimatedBuilder(animation: _ambient, builder: (_, _) => CustomPaint(size: Size.infinite, painter: _ParticlesPainter(s.fx, _ambient.value))));
      case 'colour':
        // grey wipes away from left to right: the island comes back to life
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _cam,
            builder: (_, _) => ClipRect(
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: (1 - Curves.easeInOut.transform((_cam.value * 1.4).clamp(0, 1))),
                child: Container(color: const Color(0x9959607A)),
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  static const _stormMatrix = <double>[
    .25, .5, .1, 0, -10, //
    .25, .5, .12, 0, -8,
    .28, .52, .2, 0, 0,
    0, 0, 0, 1, 0,
  ];

  Widget _castMember(CastSpec c, BoxConstraints box, int shotIndex) {
    final size = box.maxWidth * c.size;
    return TweenAnimationBuilder<double>(
      key: ValueKey('c$shotIndex${c.id}'),
      tween: Tween(begin: c.enter == 'none' ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (_, v, child) {
        final dx = switch (c.enter) { 'left' => -(1 - v) * box.maxWidth * .6, 'right' => (1 - v) * box.maxWidth * .6, _ => 0.0 };
        final dy = c.enter == 'float' ? (1 - v) * -80 : 0.0;
        return Positioned(
          left: c.x * box.maxWidth - size / 2 + dx,
          bottom: box.maxHeight * (.2 + c.y * .6) + dy,
          child: Opacity(opacity: v.clamp(0, 1), child: Transform.scale(scale: c.enter == 'pop' ? .6 + .4 * v : 1, child: child)),
        );
      },
      child: _castBody(c, size),
    );
  }

  Widget _castBody(CastSpec c, double size) {
    Widget p = Puppet(id: c.id, size: c.cage == 'none' ? size : size * .76, mood: c.mood, companionType: widget.companion, lightness: widget.gumsumLightness);
    if (c.cage != 'none') {
      p = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: c.cage == 'open' ? 1 : 0),
        duration: const Duration(milliseconds: 1600),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => CloudCage(size: size, open: v, child: child!),
        child: p,
      );
    }
    if (!c.burst) return p;
    final col = storyCast[c.id]?.color ?? const Color(0xFFFFC93C);
    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutBack,
        builder: (_, v, _) => Transform.scale(
          scale: .3 + v * 1.05,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [col, col.withValues(alpha: .65), col.withValues(alpha: 0)], stops: const [0, .6, 1])),
          ),
        ),
      ),
      // white "sticker" outline, as in the reference animation
      Container(width: size * .92, height: size * .92, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 6))),
      p,
    ]);
  }

  Widget _card(String text) => Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 26),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xF21B1F4B),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFFFD45C), width: 3),
              boxShadow: const [BoxShadow(color: Color(0x88FFD45C), blurRadius: 30)],
            ),
            child: Text(text, textAlign: TextAlign.center, style: ts(26, color: Colors.white, h: 1.25)),
          ),
        ),
      );
}


/// Cheap looping particles for cutscenes: rain, sparkles, flying keys, soft cartoon lightning (no flashing).
class _ParticlesPainter extends CustomPainter {
  final String kind;
  final double t; // 0..1, loops every 20 s
  _ParticlesPainter(this.kind, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(kind.hashCode);
    switch (kind) {
      case 'rain':
        final p = Paint()
          ..color = const Color(0x99C8D6F0)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (var k = 0; k < 90; k++) {
          final x = rng.nextDouble() * size.width;
          final y = ((rng.nextDouble() + t * 40 * (.8 + rng.nextDouble() * .4)) % 1) * size.height;
          canvas.drawLine(Offset(x, y), Offset(x - 4, y + 16), p);
        }
      case 'sparkle':
        for (var k = 0; k < 40; k++) {
          final x = rng.nextDouble() * size.width;
          final y = ((rng.nextDouble() - t * 6) % 1) * size.height;
          final a = (sin((t * 60 + k) * 1.3)).abs();
          canvas.drawCircle(Offset(x, y), 2 + 2 * a, Paint()..color = const Color(0xFFFFE9A0).withValues(alpha: .4 + .6 * a));
        }
      case 'keys':
        final tp = TextPainter(text: const TextSpan(text: '🔑', style: TextStyle(fontSize: 26)), textDirection: TextDirection.ltr)..layout();
        for (var k = 0; k < 14; k++) {
          final ph = ((t * 10 + k / 14) % 1);
          final from = Offset(rng.nextDouble() * size.width, size.height * 1.05);
          final to = Offset(size.width / 2, size.height * .45);
          final p = Offset.lerp(from, to, Curves.easeIn.transform(ph))! + Offset(sin(ph * 6 + k) * 30, 0);
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(ph * 6);
          tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
          canvas.restore();
        }
      case 'lightning':
        final cycle = (t * 20) % 1; // a soft bolt every second, fading in and out (never a flash)
        final a = sin(cycle * pi) * .7;
        final p = Paint()
          ..color = const Color(0xFFFFF3B0).withValues(alpha: a)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
        final r2 = Random((t * 20).floor());
        final x0 = size.width * (.2 + r2.nextDouble() * .6);
        final path = Path()..moveTo(x0, size.height * .05);
        var x = x0;
        for (var k = 1; k <= 5; k++) {
          x += (k.isOdd ? 1 : -1) * size.width * .05;
          path.lineTo(x, size.height * (.05 + k * .06));
        }
        canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter o) => o.t != t || o.kind != kind;
}
