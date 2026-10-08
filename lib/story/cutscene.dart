import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const CastSpec(this.id, {this.x = .5, this.mood = 'happy', this.enter = 'pop', this.size = .38});
  factory CastSpec.fromJson(Map<String, dynamic> j) => CastSpec(j['id'] as String,
      x: (j['x'] as num?)?.toDouble() ?? .5, mood: j['mood'] as String? ?? 'happy', enter: j['enter'] as String? ?? 'pop', size: (j['size'] as num?)?.toDouble() ?? .38);
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
  const Shot({this.bg = 'tree', this.fx = 'none', this.cast = const [], this.line, this.sfx, this.zoomFrom = 1, this.zoomTo = 1.06, this.panFrom = 0, this.panTo = 0, this.minMs = 2500});
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

  @override
  void initState() {
    super.initState();
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
      final sw = Stopwatch()..start();
      if (s.line != null) {
        final l = StoryLines.instance[s.line!];
        if (l != null) {
          await Future.any([AudioManager.instance.voice(s.line!, l.text, character: l.who), _waitSkip()]);
        }
      }
      final rest = s.minMs - sw.elapsedMilliseconds;
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
          return Stack(fit: StackFit.expand, children: [
            AnimatedBuilder(
              animation: _cam,
              builder: (_, child) {
                final t = Curves.easeInOut.transform(_cam.value);
                final z = shot.zoomFrom + (shot.zoomTo - shot.zoomFrom) * t;
                final p = shot.panFrom + (shot.panTo - shot.panFrom) * t;
                return Transform.translate(offset: Offset(0, p * box.maxHeight), child: Transform.scale(scale: z, child: child));
              },
              child: AnimatedSwitcher(duration: const Duration(milliseconds: 700), child: KeyedSubtree(key: ValueKey('bg$i${shot.bg}'), child: _background(shot))),
            ),
            _fx(shot),
            for (final c in shot.cast) _castMember(c, box, i),
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
      default:
        return const SizedBox.shrink();
    }
  }

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
          bottom: box.maxHeight * .2 + dy,
          child: Opacity(opacity: v.clamp(0, 1), child: Transform.scale(scale: c.enter == 'pop' ? .6 + .4 * v : 1, child: child)),
        );
      },
      child: Puppet(id: c.id, size: size, mood: c.mood, companionType: widget.companion, lightness: widget.gumsumLightness),
    );
  }
}
