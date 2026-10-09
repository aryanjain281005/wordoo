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
  final int delay; // ms after the shot starts before the character appears
  final String act; // none | sway | bounce | hop | shake | wave | float : a continuous motion on top of the puppet's own breathing
  final double? toX, toY; // the character travels to here during the shot
  final bool flip; // face the other way
  const CastSpec(this.id, {this.x = .5, this.mood = 'happy', this.enter = 'pop', this.size = .38, this.y = 0, this.cage = 'none', this.burst = false, this.delay = 0, this.act = 'none', this.toX, this.toY, this.flip = false});
  factory CastSpec.fromJson(Map<String, dynamic> j) => CastSpec(j['id'] as String,
      x: (j['x'] as num?)?.toDouble() ?? .5,
      mood: j['mood'] as String? ?? 'happy',
      enter: j['enter'] as String? ?? 'pop',
      size: (j['size'] as num?)?.toDouble() ?? .38,
      y: (j['y'] as num?)?.toDouble() ?? 0,
      cage: j['cage'] as String? ?? 'none',
      burst: j['burst'] as bool? ?? false,
      delay: j['delay'] as int? ?? 0,
      act: j['act'] as String? ?? 'none',
      toX: (j['toX'] as num?)?.toDouble(),
      toY: (j['toY'] as num?)?.toDouble(),
      flip: j['flip'] as bool? ?? false);
}

/// A sound cue inside a shot: `at` ms after the shot starts.
class SfxCue {
  final String id;
  final int at;
  final double volume;
  const SfxCue(this.id, this.at, this.volume);
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
  final List<String> fxList; // "fx": "fireflies+notes+rays" runs several effects together
  final List<SfxCue> cues; // timed sound effects ("sfx": "name" or [{"id":..,"at":ms,"vol":..}])
  final double panXFrom, panXTo; // sideways camera move (fraction of the screen width)
  final bool bars; // cinematic black bars
  final String? title; // place name that glides in at the top ("Sound Forest")
  final double shake; // camera shake strength (0 = none), e.g. thunder
  const Shot({this.fxList = const [], this.cues = const [], this.panXFrom = 0, this.panXTo = 0, this.bars = false, this.title, this.shake = 0, this.bg = 'tree', this.fx = 'none', this.cast = const [], this.line, this.sfx, this.zoomFrom = 1, this.zoomTo = 1.06, this.panFrom = 0, this.panTo = 0, this.minMs = 2500, this.video, this.card});
  factory Shot.fromJson(Map<String, dynamic> j) {
    final cam = (j['camera'] as Map?) ?? const {};
    List<double> pair(dynamic v, List<double> d) => v == null ? d : [for (final x in v as List) (x as num).toDouble()];
    final z = pair(cam['zoom'], [1, 1.06]), p = pair(cam['pan'], [0, 0]);
    final rawSfx = j['sfx'];
    final cues = <SfxCue>[
      if (rawSfx is String) SfxCue(rawSfx, 0, .8),
      if (rawSfx is List)
        for (final c in rawSfx)
          if (c is String) SfxCue(c, 0, .8) else SfxCue((c as Map)['id'] as String, (c['at'] as num?)?.toInt() ?? 0, (c['vol'] as num?)?.toDouble() ?? .8),
    ];
    final px = pair(cam['panx'], [0, 0]);
    return Shot(
      fxList: [for (final f in (j['fx'] as String? ?? 'none').split('+')) f.trim()],
      cues: cues,
      panXFrom: px[0],
      panXTo: px[1],
      bars: j['bars'] as bool? ?? false,
      title: j['title'] as String?,
      shake: (j['shake'] as num?)?.toDouble() ?? 0,
      bg: j['bg'] as String? ?? 'tree',
      fx: j['fx'] as String? ?? 'none',
      cast: [for (final c in (j['cast'] as List? ?? const [])) CastSpec.fromJson(Map<String, dynamic>.from(c as Map))],
      line: j['line'] as String?,
      sfx: rawSfx is String ? rawSfx : null,
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
  final String music; // background track while the scene plays
  const Cutscene(this.id, this.title, this.shots, {this.music = 'music.story'});
  static Future<Cutscene> load(String id) async {
    final j = jsonDecode(await rootBundle.loadString('assets/cutscenes/$id.json')) as Map<String, dynamic>;
    return Cutscene(id, j['title'] as String? ?? id, music: j['music'] as String? ?? 'music.story', [for (final s in j['shots'] as List) Shot.fromJson(Map<String, dynamic>.from(s as Map))]);
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

  final List<Timer> _cueTimers = [];
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
    if (scene!.music != 'music.story') AudioManager.instance.music(scene!.music);
    setState(() {});
    // sounds and pictures of every shot are prepared first so nothing loads in the middle of the scene
    AudioManager.instance.preloadSfx({for (final sh in scene!.shots) ...[for (final c in sh.cues) c.id, if (sh.sfx != null) sh.sfx!]}.toList());
    for (i = 0; i < scene!.shots.length; i++) {
      if (!mounted || _closing) return;
      final s = scene!.shots[i];
      setState(() => _skipShot = false);
      _cam.duration = Duration(milliseconds: max(s.minMs, 3500));
      _cam.forward(from: 0);
      for (final t in _cueTimers) {
        t.cancel();
      }
      _cueTimers.clear();
      for (final c in s.cues) {
        if (c.at <= 0) {
          AudioManager.instance.sfx(c.id, volume: c.volume);
        } else {
          _cueTimers.add(Timer(Duration(milliseconds: c.at), () {
            if (mounted && !_closing) AudioManager.instance.sfx(c.id, volume: c.volume);
          }));
        }
      }
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
    for (final t in _cueTimers) {
      t.cancel();
    }
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
            // every picture of the scene is put on the GPU once, invisibly, before it is needed (no hitch when a shot changes)
            Positioned(left: 0, top: 0, child: ArtWarmUp(_warmPrefixes(sc))),
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
                final px = shot.panXFrom + (shot.panXTo - shot.panXFrom) * t;
                final zz = max(z, 1 + 2 * max(p.abs(), px.abs()) + .02);
                var off = Offset(px * box.maxWidth, p * box.maxHeight);
                if (shot.shake > 0) {
                  // a short rumble at the start of the shot that settles down
                  final k = (1 - _cam.value * 2).clamp(0.0, 1.0) * shot.shake;
                  off += Offset(sin(_cam.value * 90) * 6 * k, cos(_cam.value * 110) * 5 * k);
                }
                return Transform.translate(offset: off, child: Transform.scale(scale: zz, child: child));
              },
              child: AnimatedSwitcher(duration: const Duration(milliseconds: 700), child: KeyedSubtree(key: ValueKey('bg$i${shot.bg}'), child: SizedBox.expand(child: _background(shot)))),
            ),
            for (final f in shot.fxList) _fx(f),
            for (final c in shot.cast) _castMember(c, box, i),
            ],
            if (shot.bars) ..._bars(box),
            if (shot.title != null) _placeTitle(shot.title!, i),
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

  List<String> _warmPrefixes(Cutscene sc) => {
        for (final sh in sc.shots) ...[
          if (sh.bg.startsWith('art:')) sh.bg.substring(4).replaceAll('~storm', '') else 'bg.cut.${sh.bg}',
          for (final c in sh.cast) ...[
            'char.${c.id}.',
            if (c.id.startsWith('jailer_')) 'char.${c.id}',
            if (c.cage != 'none') 'prop.cage.',
          ],
        ],
        'char.gumsum.',
      }.toList();

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

  /// Cinematic letterbox bars that slide in.
  List<Widget> _bars(BoxConstraints box) => [
        for (final top in [true, false])
          Positioned(
            left: 0,
            right: 0,
            top: top ? 0 : null,
            bottom: top ? null : 0,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('bar$i$top'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Container(height: box.maxHeight * .07 * v, color: Colors.black),
              ),
            ),
          ),
      ];

  /// The name of the place glides in, stays, and fades.
  Widget _placeTitle(String text, int shotIndex) => Positioned(
        top: MediaQuery.of(context).padding.top + 56,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('title$shotIndex'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 3200),
            builder: (_, v, _) {
              final a = v < .15 ? v / .15 : (v > .8 ? (1 - v) / .2 : 1.0);
              return Opacity(
                opacity: a.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - min(1, v * 6)) * -18),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xCC1B1F4B), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFFFE17A), width: 2.5)),
                      child: Text(text, style: ts(28, color: const Color(0xFFFFE17A))),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _fx(String kind) {
    switch (kind) {
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
      case 'rain' || 'sparkle' || 'keys' || 'lightning' || 'fireflies' || 'leaves' || 'notes' || 'mist' || 'rays' || 'letters' || 'lanterns' || 'dust' || 'embers' || 'petals' || 'confetti':
        return IgnorePointer(child: RepaintBoundary(child: AnimatedBuilder(animation: _ambient, builder: (_, _) => CustomPaint(size: Size.infinite, painter: _ParticlesPainter(kind, _ambient.value)))));
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
    return _Appear(
      key: ValueKey('c$shotIndex${c.id}'),
      delay: c.delay,
      child: TweenAnimationBuilder<double>(
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
        child: _moving(c, box, _acting(c, _castBody(c, size))),
      ),
    );
  }

  /// A character that walks / flies to a new place during the shot.
  Widget _moving(CastSpec c, BoxConstraints box, Widget body) {
    if (c.toX == null && c.toY == null) return body;
    return AnimatedBuilder(
      animation: _cam,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_cam.value);
        return Transform.translate(offset: Offset(((c.toX ?? c.x) - c.x) * box.maxWidth * t, -((c.toY ?? c.y) - c.y) * box.maxHeight * .6 * t), child: child);
      },
      child: body,
    );
  }

  /// Continuous gestures layered on the puppet's own breathing and blinking (cheap transforms only).
  Widget _acting(CastSpec c, Widget body) {
    if (c.flip) body = Transform.flip(flipX: true, child: body);
    if (c.act == 'none') return body;
    return AnimatedBuilder(
      animation: _ambient,
      builder: (_, child) {
        final a = _ambient.value * 2 * pi * 20; // _ambient loops every 20 s
        return switch (c.act) {
          'sway' => Transform.rotate(angle: sin(a * .5) * .05, child: child),
          'bounce' => Transform.translate(offset: Offset(0, -(sin(a * 1.4)).abs() * 14), child: child),
          'hop' => Transform.translate(offset: Offset(0, -pow(sin(a * .9).abs(), 3) * 40), child: child),
          'shake' => Transform.rotate(angle: sin(a * 6) * .04, child: child),
          'wave' => Transform.rotate(angle: sin(a * 1.6) * .09, alignment: Alignment.bottomCenter, child: child),
          'float' => Transform.translate(offset: Offset(sin(a * .35) * 10, sin(a * .6) * 12), child: child),
          _ => child!,
        };
      },
      child: body,
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

  static final Map<String, TextPainter> _glyphs = {};
  /// Text painters are built once per glyph, never inside a frame.
  static TextPainter _glyph(String ch, Color c, double size) => _glyphs.putIfAbsent('$ch${c.toARGB32()}$size', () => TextPainter(text: TextSpan(text: ch, style: TextStyle(fontSize: size, color: c, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout());

  /// A soft glowing dot made of stacked translucent discs (no blur filter, so it stays cheap on the GPU).
  static void _glow(Canvas canvas, Offset c, double r, Color col, double a) {
    final p = Paint();
    canvas.drawCircle(c, r * 3.2, p..color = col.withValues(alpha: a * .10));
    canvas.drawCircle(c, r * 2.0, p..color = col.withValues(alpha: a * .20));
    canvas.drawCircle(c, r * 1.0, p..color = col.withValues(alpha: a * .85));
  }

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
        final tp = _glyph('🔑', Colors.white, 26);
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
      case 'fireflies':
        for (var k = 0; k < 26; k++) {
          final x = (rng.nextDouble() + sin((t * 20 + k * .37) * 2 * pi * .25) * .05) % 1 * size.width;
          final y = (.15 + rng.nextDouble() * .7 + cos((t * 20 + k * .21) * 2 * pi * .2) * .04) * size.height;
          final a = .35 + .65 * pow(sin((t * 20 * .35 + rng.nextDouble() * 4) * pi).abs(), 2);
          _glow(canvas, Offset(x, y), 3, const Color(0xFFFFF59D), a);
        }
      case 'leaves':
        const cols = [Color(0xFF7CB342), Color(0xFFC0CA33), Color(0xFFFFB300), Color(0xFF9CCC65), Color(0xFFE57C23)];
        for (var k = 0; k < 18; k++) {
          final sp = .5 + rng.nextDouble() * .6;
          final ph = ((t * 20 * .045 * sp + rng.nextDouble()) % 1);
          final x = ((rng.nextDouble() + sin(ph * 9 + k) * .05)) * size.width;
          final y = (ph * 1.2 - .1) * size.height;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(sin(ph * 7 + k) * 1.2 + ph * 3);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 20 + rng.nextDouble() * 8, height: 9), Paint()..color = cols[k % cols.length].withValues(alpha: .9));
          canvas.restore();
        }
      case 'notes':
        const cols = [Color(0xFFFFE17A), Color(0xFFFF9EC4), Color(0xFF8FE3FF), Color(0xFFB9F5A0), Color(0xFFFFFFFF)];
        for (var k = 0; k < 14; k++) {
          final ph = ((t * 20 * .07 * (.7 + rng.nextDouble() * .6) + rng.nextDouble()) % 1);
          final x = (.1 + rng.nextDouble() * .8) * size.width + sin(ph * 8 + k) * 22;
          final y = (1.05 - ph * 1.15) * size.height;
          final fade = ((ph < .1 ? ph * 10 : (ph > .8 ? (1 - ph) * 5 : 1.0)).clamp(0.0, 1.0) * 6).round() / 6; // 7 fade steps keep the glyph cache small
          final tp = _glyph(k.isEven ? '♪' : '♫', cols[k % cols.length].withValues(alpha: fade), 30 + (k % 3) * 6.0);
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(sin(ph * 6 + k) * .35);
          if (fade > 0) tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
          canvas.restore();
        }
      case 'letters':
        const cols = [Color(0xFFFFE17A), Color(0xFFFFFFFF), Color(0xFFFFB38A), Color(0xFFA5E8FF)];
        const abc = 'ABCDEFGHIJKLMNOPRSTWabcdeghmnoprstu';
        for (var k = 0; k < 16; k++) {
          final ph = ((t * 20 * .05 * (.7 + rng.nextDouble() * .6) + rng.nextDouble()) % 1);
          final x = (.08 + rng.nextDouble() * .84) * size.width + sin(ph * 6 + k) * 16;
          final y = (1.05 - ph * 1.15) * size.height;
          final fade = ((ph < .1 ? ph * 10 : (ph > .8 ? (1 - ph) * 5 : 1.0)).clamp(0.0, 1.0) * 6).round() / 6;
          final tp = _glyph(abc[(k * 7) % abc.length], cols[k % cols.length].withValues(alpha: fade), 34 + (k % 3) * 8.0);
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(sin(ph * 5 + k) * .4);
          if (fade > 0) tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
          canvas.restore();
        }
      case 'mist':
        for (var k = 0; k < 4; k++) {
          final w = size.width * (1.1 + k * .15);
          final x = ((t * 20 * (.012 + k * .004) + k * .27) % 1.6 - .3) * size.width;
          final y = size.height * (.5 + k * .1);
          final r = Rect.fromCenter(center: Offset(x, y), width: w, height: size.height * .22);
          canvas.drawOval(r, Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: .22), Colors.white.withValues(alpha: 0)]).createShader(r));
        }
      case 'rays':
        final pulse = .55 + .45 * sin(t * 20 * .5);
        for (var k = 0; k < 5; k++) {
          final ang = .35 + k * .17 + sin(t * 20 * .15 + k) * .03;
          final from = Offset(size.width * (.1 + k * .09), -20);
          final len = size.height * 1.1;
          final w = size.width * (.07 + .03 * (k % 2));
          final path = Path()
            ..moveTo(from.dx - w * .15, from.dy)
            ..lineTo(from.dx + w * .15, from.dy)
            ..lineTo(from.dx + cos(ang) * len + w, from.dy + sin(ang) * len)
            ..lineTo(from.dx + cos(ang) * len - w, from.dy + sin(ang) * len)
            ..close();
          canvas.drawPath(path, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFF3B0).withValues(alpha: .30 * pulse), const Color(0x00FFF3B0)]).createShader(Offset.zero & size));
        }
      case 'lanterns':
        for (var k = 0; k < 9; k++) {
          final ph = ((t * 20 * .03 * (.7 + rng.nextDouble() * .6) + rng.nextDouble()) % 1);
          final x = (.06 + rng.nextDouble() * .88) * size.width + sin(ph * 5 + k) * 18;
          final y = (1.05 - ph * 1.2) * size.height;
          _glow(canvas, Offset(x, y), 14, const Color(0xFFFFB347), .9);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 16, height: 20), const Radius.circular(5)), Paint()..color = const Color(0xFFFF8A3D));
        }
      case 'dust':
        for (var k = 0; k < 34; k++) {
          final x = ((rng.nextDouble() + t * 20 * .006 * (1 + rng.nextDouble())) % 1) * size.width;
          final y = (rng.nextDouble() + sin((t * 20 * .2 + k)) * .015) * size.height;
          canvas.drawCircle(Offset(x, y), 1.4 + rng.nextDouble() * 1.4, Paint()..color = Colors.white.withValues(alpha: .25 + .35 * sin(t * 20 * .6 + k).abs()));
        }
      case 'embers':
        for (var k = 0; k < 22; k++) {
          final ph = ((t * 20 * .09 * (.6 + rng.nextDouble() * .8) + rng.nextDouble()) % 1);
          final x = (.15 + rng.nextDouble() * .7) * size.width + sin(ph * 9 + k) * 14;
          final y = (1 - ph * .9) * size.height;
          canvas.drawCircle(Offset(x, y), 2.2 * (1 - ph) + .8, Paint()..color = Color.lerp(const Color(0xFFFFD27A), const Color(0xFFFF6A3D), ph)!.withValues(alpha: 1 - ph));
        }
      case 'petals':
        for (var k = 0; k < 20; k++) {
          final ph = ((t * 20 * .04 * (.6 + rng.nextDouble() * .8) + rng.nextDouble()) % 1);
          final x = (rng.nextDouble() + sin(ph * 8 + k) * .06) * size.width;
          final y = (ph * 1.2 - .1) * size.height;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(ph * 8 + k);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 12, height: 7), Paint()..color = (k.isEven ? const Color(0xFFFFB6D1) : const Color(0xFFFFE0EC)).withValues(alpha: .9));
          canvas.restore();
        }
      case 'confetti':
        const cols = [Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF6BCB77), Color(0xFF4D96FF), Color(0xFFFF9EC4)];
        for (var k = 0; k < 44; k++) {
          final ph = ((t * 20 * .09 * (.6 + rng.nextDouble() * .8) + rng.nextDouble()) % 1);
          final x = (rng.nextDouble() + sin(ph * 7 + k) * .04) * size.width;
          final y = (ph * 1.15 - .1) * size.height;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(ph * 14 + k);
          canvas.scale(1, sin(ph * 12 + k).abs() * .9 + .1);
          canvas.drawRect(const Rect.fromLTWH(-5, -3, 10, 6), Paint()..color = cols[k % cols.length]);
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


/// Shows its child after [delay] ms (so a shot can bring characters in one after another).
class _Appear extends StatefulWidget {
  final int delay;
  final Widget child;
  const _Appear({super.key, required this.delay, required this.child});
  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> {
  late bool _on = widget.delay <= 0;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    if (!_on) {
      _t = Timer(Duration(milliseconds: widget.delay), () {
        if (mounted) setState(() => _on = true);
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _on ? widget.child : const SizedBox.shrink();
}
