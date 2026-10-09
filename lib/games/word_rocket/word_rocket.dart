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
import '../../story/story_lines.dart';
import '../../widgets/common.dart';
import '../game_module.dart';

/// Ocean zone by difficulty step: Sunlight → Twilight → Deep → Alien Trench (made-up words).
int rocketZone(int step) => step <= 3 ? 1 : (step <= 5 ? 2 : (step <= 7 ? 3 : 4));
const rocketZoneNames = ['Sunlight Zone', 'Twilight Zone', 'Deep Zone', 'Alien Trench'];

/// How deep the Bubble Rocket has dived during one quest. Each BOOST dives one level; at [pearlDepth] the
/// Pearl of Sounds is found. Restarts with every quest (the demo resets it).
class RocketDive {
  static const pearlDepth = 5;
  static int depth = 0;
  static int zoneIntro = 0; // zone whose welcome line was already said this quest
  static void reset() {
    depth = 0;
    zoneIntro = 0;
  }
}

/// Game 5 · Word Rocket — "Captain Kachhua's Bubble Rocket" (scene drawn with the Flame engine).
/// Fuel cells hold the sound units (c · a · t). Tap a cell to hear it, swipe up to blend the cells together,
/// then pick the word. Right → BOOST, the rocket dives deeper; wrong → the engine sputters and the cells
/// are read again slowly.
class WordRocketItem extends StatefulWidget {
  final GameCtx ctx;
  final int seaLog; // persistent: creatures met so far
  const WordRocketItem({super.key, required this.ctx, this.seaLog = 0});
  @override
  State<WordRocketItem> createState() => _WordRocketItemState();
}

class _WordRocketItemState extends State<WordRocketItem> with TickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late final _RocketScene scene = _RocketScene(zone: rocketZone(it.level), alien: alien ? it.options[it.correct].label : null);
  late final AnimationController _zip = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  final List<String> _tags = [];
  final Set<int> _faded = {};
  final Map<int, int> _shake = {};
  int _attempts = 0;
  bool _resolved = false;
  bool _blended = false;
  bool _blending = false;
  int _litCell = -1;
  int? _picked; // heard options: last one listened to
  int? _correctShown;
  double _swipe = 0;
  bool _disposed = false;
  bool _pearl = false;

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  bool get demo => widget.ctx.demo;
  bool get alien => it.id.startsWith('dn:');
  bool get pictures => it.options.every((o) => o.emoji != null);
  List<String> get cells => (it.stimulus ?? '').split(' · ').where((s) => s.isNotEmpty).toList();
  List<String> get spoken {
    final s = (it.replaySay ?? '').split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
    return s.length == cells.length ? s : cells;
  }

  void _say(String t) => Speaker.instance.speak(t, widget.ctx.pack.tts);

  Future<void> _line(String id) async {
    final l = StoryLines.instance[id];
    if (l != null && !_disposed) await AudioManager.instance.voice(id, l.text, character: l.who);
  }

  @override
  void initState() {
    super.initState();
    if (demo) RocketDive.reset();
    scene.depth = RocketDive.depth;
    if (widget.ctx.scaffold && it.options.length > 2) {
      _faded.add([for (var i = 0; i < it.options.length; i++) if (i != it.correct) i].first);
      widget.ctx.feedback(Str.t(lang, 'hint'), true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => demo ? _runDemo() : _open());
  }

  @override
  void dispose() {
    _disposed = true;
    _zip.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final z = rocketZone(it.level);
    if (RocketDive.zoneIntro != z) {
      RocketDive.zoneIntro = z;
      await _line('rocket_zone_$z');
    }
    if (_disposed) return;
    _say(it.prompt);
    if (widget.ctx.scaffold) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!_disposed) _readCells(slow: true);
    }
  }

  Future<void> _runDemo() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    for (var i = 0; i < cells.length; i++) {
      if (_disposed) return;
      setState(() => _litCell = i);
      await Future.delayed(const Duration(milliseconds: 450));
    }
    if (_disposed) return;
    setState(() => _litCell = -1);
    await _blend(force: true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (_disposed) return;
    setState(() => _correctShown = it.correct);
    scene.boost();
  }

  // ---------------- cells ----------------
  void _tapCell(int i) {
    if (demo || _blending) return;
    AudioManager.instance.sfx('bubble', volume: .5);
    setState(() => _litCell = i);
    _say(spoken[i]);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!_disposed && _litCell == i) setState(() => _litCell = -1);
    });
  }

  /// Light the cells one by one while their sounds play (scaffold / after a sputter).
  Future<void> _readCells({bool slow = false}) async {
    for (var i = 0; i < cells.length; i++) {
      if (_disposed) return;
      setState(() => _litCell = i);
      _say(spoken[i]);
      await Future.delayed(Duration(milliseconds: slow ? 1000 : 600));
    }
    if (!_disposed) setState(() => _litCell = -1);
  }

  /// Swipe up: the sounds play quickly one after another and the cells zip into one word.
  Future<void> _blend({bool force = false}) async {
    if (_blended || _blending || (demo && !force)) return;
    setState(() => _blending = true);
    AudioManager.instance.sfx('whoosh_2', volume: .5);
    for (var i = 0; i < cells.length; i++) {
      if (_disposed) return;
      setState(() => _litCell = i);
      if (!demo) _say(spoken[i]);
      await Future.delayed(const Duration(milliseconds: 380));
    }
    if (_disposed) return;
    await _zip.forward();
    if (_disposed) return;
    AudioManager.instance.sfx('power_up', volume: .5);
    scene.rumble();
    setState(() {
      _blending = false;
      _blended = true;
      _litCell = -1;
    });
  }

  // ---------------- answers ----------------
  void _tapOption(int i) {
    if (_resolved || demo || !_blended || _faded.contains(i)) return;
    final o = it.options[i];
    if (it.audioOptions && _picked != i) {
      // heard options: first tap listens, the ✓ chooses
      AudioManager.instance.sfx('bubble', volume: .4);
      setState(() => _picked = i);
      _say(o.say ?? o.label);
      return;
    }
    _choose(i);
  }

  void _choose(int i) {
    if (i == it.correct) {
      final first = _attempts == 0;
      setState(() {
        _resolved = true;
        _correctShown = i;
      });
      _say(it.options[i].say ?? it.options[i].label);
      widget.ctx.feedback(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
      AudioManager.instance.sfx('boost', volume: .7);
      if (first) {
        RocketDive.depth++;
        scene.depth = RocketDive.depth;
      }
      scene.boost();
      final pearl = first && RocketDive.depth == RocketDive.pearlDepth;
      Future.delayed(const Duration(milliseconds: 900), () async {
        if (_disposed) return;
        if (pearl) {
          setState(() => _pearl = true);
          AudioManager.instance.sfx('reward_fanfare', volume: .6);
          await _line('rocket_pearl');
        } else if (first && RocketDive.depth % 2 == 1) {
          await _line('rocket_boost');
        }
      });
      _finish(first, pearl ? 4200 : 2000);
      return;
    }
    _attempts++;
    final tag = it.options[i].tag;
    if (tag != null) _tags.add(tag);
    scene.sputter();
    AudioManager.instance.sfx('thud_soft', volume: .7);
    final canRetry = _attempts < 2 && (it.options.length - _faded.length - 1) > 1;
    setState(() {
      _shake[i] = (_shake[i] ?? 0) + 1;
      _faded.add(i);
      _picked = null;
      if (!canRetry) {
        _resolved = true;
        _correctShown = it.correct;
      }
    });
    if (canRetry) {
      widget.ctx.feedback(it.hint, false);
      Future.delayed(const Duration(milliseconds: 700), () async {
        if (_disposed) return;
        if (_attempts == 1) await _line('rocket_sputter');
        if (!_disposed) _readCells(slow: true);
      });
    } else {
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      _say(it.options[it.correct].say ?? it.options[it.correct].label);
      _finish(false, 2400);
    }
  }

  void _finish(bool firstTry, int delayMs) {
    final r = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: firstTry, ms: _clock.elapsedMilliseconds, tags: [..._tags]);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_disposed && !demo) widget.ctx.done(r);
    });
  }

  // ---------------- UI ----------------
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
              ArtImage('bg.rocket.zone${rocketZone(it.level)}', fit: BoxFit.cover, fallback: const SizedBox.shrink()),
              GameWidget(game: scene),
              Positioned(left: 0, right: 0, top: 12, child: _cellsArea()),
              Positioned(right: 8, top: 0, bottom: 0, child: _depthMeter()),
              if (_pearl) Positioned.fill(child: IgnorePointer(child: _pearlOverlay())),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 8),
      _options(),
    ]);
  }

  Widget _header() => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          SizedBox(width: 58, height: 60, child: ArtImage('char.kachhua.happy', fallback: const Center(child: Text('🐢', style: TextStyle(fontSize: 40))))),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(alien ? 'Meet the alien! How do we say its name?' : it.prompt, style: ts(17, color: C.ink)),
              Text('🌊 ${rocketZoneNames[rocketZone(it.level) - 1]}${demo ? '' : '  ·  🐠 ${widget.seaLog} in the Sea Log'}', style: ts(12, color: C.inkSoft, w: FontWeight.w600)),
            ]),
          ),
          RoundIconButton(icon: Icons.volume_up_rounded, label: 'Hear the cells', color: C.gold, size: 44, onTap: demo ? () {} : () => _readCells()),
        ]),
      );

  Widget _cellsArea() {
    return GestureDetector(
      onVerticalDragUpdate: demo || _blended ? null : (d) => setState(() => _swipe = (_swipe + d.delta.dy).clamp(-120.0, 0.0)),
      onVerticalDragEnd: demo || _blended
          ? null
          : (d) {
              final go = _swipe < -40 || (d.primaryVelocity ?? 0) < -300;
              setState(() => _swipe = 0);
              if (go) _blend();
            },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Transform.translate(
            offset: Offset(0, _swipe * .5),
            child: AnimatedBuilder(
              animation: _zip,
              builder: (_, _) => _blended ? _mergedCell() : _cellRow(_zip.value),
            ),
          ),
          const SizedBox(height: 6),
          if (!_blended)
            GestureDetector(
              onTap: demo ? null : _blend,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(20)),
                child: Text(_blending ? 'Blending…' : '⇡  Swipe up to blend', style: ts(15, color: const Color(0xFF1A6E8E))),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _cellRow(double zip) {
    final n = cells.length;
    return LayoutBuilder(builder: (context, box) {
      final w = min(64.0, (box.maxWidth - 8) / n - 8);
      return SizedBox(
        height: 74,
        child: Stack(alignment: Alignment.center, children: [
          for (var i = 0; i < n; i++)
            Transform.translate(
              // cells start apart and slide together like a zip
              offset: Offset((i - (n - 1) / 2) * (w + 10) * (1 - zip) + (i - (n - 1) / 2) * w * .55 * zip, 0),
              child: GestureDetector(onTap: () => _tapCell(i), child: _cell(cells[i], w, _litCell == i, zip)),
            ),
        ]),
      );
    });
  }

  Widget _cell(String unit, double w, bool lit, double zip) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: w,
        height: 66,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: lit ? const [Color(0xFFFFF59D), Color(0xFFFFC93C)] : const [Color(0xFFE0FBFF), Color(0xFF7FD8EE)]),
          borderRadius: BorderRadius.circular(16 * (1 - zip) + 4),
          border: Border.all(color: lit ? const Color(0xFFE0A100) : const Color(0xFF1A6E8E), width: 3),
          boxShadow: [BoxShadow(color: (lit ? const Color(0xFFFFD45C) : const Color(0xFF7FD8EE)).withValues(alpha: .7), blurRadius: lit ? 18 : 8)],
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(unit, style: ts(30, color: C.ink)))),
      );

  Widget _mergedCell() => TweenAnimationBuilder<double>(
        tween: Tween(begin: .8, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: GestureDetector(
          onTap: demo ? null : () => _readCells(),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFF59D), Color(0xFFFFC93C)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0A100), width: 3),
              boxShadow: const [BoxShadow(color: Color(0xAAFFD45C), blurRadius: 22)],
            ),
            child: Text(cells.join(), style: ts(36, color: C.ink)),
          ),
        ),
      );

  Widget _depthMeter() {
    final d = RocketDive.depth.clamp(0, RocketDive.pearlDepth);
    return Center(
      child: Container(
        width: 22,
        height: 170,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .25), borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white54, width: 2)),
        child: Stack(alignment: Alignment.topCenter, children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            top: 4 + (170 - 34) * d / RocketDive.pearlDepth,
            child: const Text('🚀', style: TextStyle(fontSize: 14)),
          ),
          const Positioned(bottom: 2, child: Text('⚪', style: TextStyle(fontSize: 13))),
        ]),
      ),
    );
  }

  Widget _options() {
    final enabled = _blended || demo;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: enabled ? 1 : .35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            for (var i = 0; i < it.options.length; i++) Expanded(child: _option(i)),
          ]),
          if (it.audioOptions)
            SizedBox(
              height: 52,
              child: _picked != null && !_resolved && enabled && !demo
                  ? Center(child: BigButton(label: '✓', style: BtnStyle.go, width: 90, height: 46, fontSize: 24, onTap: () => _choose(_picked!)))
                  : Center(child: Text(enabled ? 'Tap a bubble to hear it' : '', style: ts(14, color: Colors.white, w: FontWeight.w600).copyWith(shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)]))),
            ),
        ]),
      ),
    );
  }

  Widget _option(int i) {
    final o = it.options[i];
    final faded = _faded.contains(i);
    final right = _correctShown == i;
    final sel = _picked == i;
    return Opacity(
      opacity: faded ? .3 : 1,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('o$i${_shake[i] ?? 0}'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (_, t, child) => Transform.translate(offset: Offset((_shake[i] ?? 0) == 0 ? 0 : sin(t * pi * 5) * 7 * (1 - t), 0), child: child),
        child: GestureDetector(
          onTap: () => _tapOption(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 92,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: right ? const Color(0xFFCDEFC4) : Colors.white,
              shape: it.audioOptions ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: it.audioOptions ? null : BorderRadius.circular(20),
              border: Border.all(color: right ? const Color(0xFF4CAF50) : (sel ? const Color(0xFF1A6E8E) : const Color(0xFFB9E6F2)), width: right || sel ? 4 : 2),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            alignment: Alignment.center,
            child: pictures
                ? Text(o.emoji!, style: const TextStyle(fontSize: 46))
                : (it.audioOptions
                    ? Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.volume_up_rounded, color: sel ? const Color(0xFF1A6E8E) : C.inkSoft, size: 28), Text('${i + 1}', style: ts(20, color: C.ink))])
                    : FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.all(6), child: Text(o.label, style: ts(24, color: C.ink))))),
          ),
        ),
      ),
    );
  }

  Widget _pearlOverlay() => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.elasticOut,
        builder: (_, v, _) => Center(
          child: Transform.scale(
            scale: v,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0xCC7FD8EE), blurRadius: 30)]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 80, height: 80, child: ArtImage('prop.rocket.pearl', fallback: const Center(child: Text('🦪', style: TextStyle(fontSize: 60))))),
                Text('The Pearl of Sounds!', style: ts(22, color: const Color(0xFF1A6E8E))),
              ]),
            ),
          ),
        ),
      );
}

/// Flame scene: the ocean zone, light rays, bubbles, sea creatures and the Bubble Rocket.
class _RocketScene extends FlameGame {
  final int zone;
  final String? alien; // Alien Trench: the made-up word is this creature's name
  _RocketScene({required this.zone, this.alien});

  int depth = 0;
  double t = 0;
  double _boostT = -1; // seconds since boost (−1 = idle)
  double _sputterT = -1;
  double _rumbleT = -1;
  final _rng = Random(7);
  late final List<_Bubble> _bubbles = [for (var i = 0; i < 26; i++) _Bubble.random(_rng, 400, 600)];
  late final List<_Fish> _fish = [for (var i = 0; i < 3 + zone; i++) _Fish.random(_rng, zone)];

  void boost() => _boostT = 0;
  void sputter() => _sputterT = 0;
  void rumble() => _rumbleT = 0;

  @override
  Color backgroundColor() => const Color(0x00000000);

  static const _zoneColors = [
    [Color(0xFF7FE3F7), Color(0xFF1E9CC4)],
    [Color(0xFF2C86B8), Color(0xFF173E7A)],
    [Color(0xFF14326A), Color(0xFF0A1636)],
    [Color(0xFF241046), Color(0xFF07041A)],
  ];

  @override
  void update(double dt) {
    super.update(dt);
    dt = min(dt, 1 / 30);
    t += dt;
    if (_boostT >= 0) _boostT += dt;
    if (_boostT > 1.6) _boostT = -1;
    if (_sputterT >= 0) _sputterT += dt;
    if (_sputterT > 1.0) _sputterT = -1;
    if (_rumbleT >= 0) _rumbleT += dt;
    if (_rumbleT > .6) _rumbleT = -1;
    final rush = _boostT >= 0 ? 6.0 : 1.0; // diving: everything streams upward past the rocket
    for (final b in _bubbles) {
      b.y -= b.speed * dt * rush;
      b.x += sin(t * 2 + b.phase) * 8 * dt;
      if (b.y < -10) {
        b
          ..y = size.y + 10
          ..x = _rng.nextDouble() * size.x;
      }
    }
    for (final f in _fish) {
      f.x += f.speed * dt;
      f.y -= _boostT >= 0 ? 160 * dt : 0;
      if (f.x > size.x + 60 || f.x < -60 || f.y < -40) {
        f.x = f.speed > 0 ? -50 : size.x + 50;
        f.y = size.y * (.3 + _rng.nextDouble() * .6);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x, h = size.y;
    final rect = Rect.fromLTWH(0, 0, w, h);
    if (ReadleAssets.instance.art('bg.rocket.zone$zone') == null) {
      final c = _zoneColors[zone - 1];
      canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c).createShader(rect));
      // light rays in the shallow zones, glowing specks in the deep
      if (zone <= 2) {
        for (var k = 0; k < 4; k++) {
          final x = w * (.15 + k * .25) + sin(t * .3 + k) * 20;
          final ray = Path()
            ..moveTo(x - 18, 0)
            ..lineTo(x + 18, 0)
            ..lineTo(x + 60, h)
            ..lineTo(x - 10, h)
            ..close();
          canvas.drawPath(ray, Paint()..color = Colors.white.withValues(alpha: zone == 1 ? .09 : .05));
        }
      } else {
        for (var k = 0; k < 30; k++) {
          final r = Random(k);
          final a = .3 + .5 * sin(t * 1.5 + k).abs();
          canvas.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * h), 1.6, Paint()..color = (zone == 4 ? const Color(0xFFD08CFF) : const Color(0xFF7FFFE1)).withValues(alpha: a));
        }
      }
    }
    for (final f in _fish) {
      _paintFish(canvas, f);
    }
    for (final b in _bubbles) {
      canvas.drawCircle(Offset(b.x, b.y), b.r, Paint()
        ..color = Colors.white.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
    }
    if (alien != null) _paintAlien(canvas, Offset(w * .25, h * .72));
    _paintRocket(canvas, Offset(w * .55, h * .66));
  }

  void _paintFish(Canvas canvas, _Fish f) {
    final tp = TextPainter(text: TextSpan(text: f.emoji, style: TextStyle(fontSize: f.size)), textDirection: TextDirection.ltr)..layout();
    canvas.save();
    canvas.translate(f.x, f.y + sin(t * 2 + f.phase) * 4);
    if (f.speed > 0) canvas.scale(-1, 1); // emoji fish face left; flip them when swimming right
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  /// A friendly made-up creature for the Alien Trench, coloured by its name.
  void _paintAlien(Canvas canvas, Offset c) {
    final hue = (alien!.codeUnits.fold<int>(0, (a, b) => a * 31 + b) % 360).toDouble();
    final body = HSLColor.fromAHSL(1, hue, .7, .62).toColor();
    final bob = sin(t * 2) * 6;
    final o = c + Offset(0, bob);
    canvas.drawCircle(o, 34, Paint()..color = body.withValues(alpha: .35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    for (var k = -1; k <= 1; k += 2) {
      final tip = o + Offset(k * 16.0, -48 + sin(t * 3 + k) * 4);
      canvas.drawLine(o + Offset(k * 8.0, -22), tip, Paint()
        ..color = body
        ..strokeWidth = 3);
      canvas.drawCircle(tip, 5, Paint()..color = const Color(0xFFFFF59D));
    }
    canvas.drawOval(Rect.fromCenter(center: o, width: 64, height: 54), Paint()..color = body);
    for (var k = -1; k <= 1; k += 2) {
      canvas.drawCircle(o + Offset(k * 12.0, -6), 9, Paint()..color = Colors.white);
      canvas.drawCircle(o + Offset(k * 12.0 + 2, -5), 4.5, Paint()..color = const Color(0xFF1E2753));
    }
    canvas.drawArc(Rect.fromCenter(center: o + const Offset(0, 8), width: 20, height: 12), .2, pi - .4, false, Paint()
      ..color = const Color(0xFF1E2753)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    final tp = TextPainter(
      text: TextSpan(text: '“${alien!}”', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, o + Offset(-tp.width / 2, 34));
  }

  void _paintRocket(Canvas canvas, Offset c) {
    var o = c + Offset(0, sin(t * 1.6) * 6);
    if (_boostT >= 0) o += Offset(0, sin(_boostT * pi / 1.6) * 40); // dives down and comes back
    if (_sputterT >= 0) o += Offset(sin(_sputterT * 50) * 5 * (1 - _sputterT), 0);
    if (_rumbleT >= 0) o += Offset(sin(_rumbleT * 70) * 2.5, 0);
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.rotate(pi + (_boostT >= 0 ? 0 : sin(t) * .05)); // nose points down into the deep
    // flame at the back (now on top)
    final flame = _boostT >= 0 ? 1.0 : (_rumbleT >= 0 ? .5 : .15);
    final fl = 26 + 40 * flame + sin(t * 30) * 5 * flame;
    final flamePath = Path()
      ..moveTo(-12, -40)
      ..quadraticBezierTo(0, -40 - fl * 1.2, 12, -40)
      ..close();
    canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFF8A3D).withValues(alpha: .4 + .6 * flame));
    canvas.drawPath(
        Path()
          ..moveTo(-6, -40)
          ..quadraticBezierTo(0, -40 - fl * .7, 6, -40)
          ..close(),
        Paint()..color = const Color(0xFFFFE07A));
    if (_sputterT >= 0) {
      for (var k = 0; k < 4; k++) {
        canvas.drawCircle(Offset(sin(k * 2.0) * 10, -50 - _sputterT * 60 - k * 10), 7 + k * 2.0, Paint()..color = Colors.grey.withValues(alpha: .5 * (1 - _sputterT)));
      }
    }
    {
      // fins
      final fin = Paint()..color = const Color(0xFFE0568A);
      canvas.drawPath(Path()..moveTo(-20, -18)..lineTo(-34, -42)..lineTo(-18, -38)..close(), fin);
      canvas.drawPath(Path()..moveTo(20, -18)..lineTo(34, -42)..lineTo(18, -38)..close(), fin);
      // body
      final body = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 44, height: 84), const Radius.circular(22));
      canvas.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFFFFD45C), Color(0xFFF0A020)]).createShader(body.outerRect));
      canvas.drawRRect(body, Paint()
        ..color = const Color(0xFF8B5A2B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
      // nose cone
      canvas.drawPath(Path()..moveTo(-22, 24)..quadraticBezierTo(0, 70, 22, 24)..close(), Paint()..color = const Color(0xFF1A6E8E));
      // porthole with the captain
      canvas.drawCircle(const Offset(0, -2), 13, Paint()..color = const Color(0xFFBFF3FF));
      canvas.drawCircle(const Offset(0, -2), 13, Paint()
        ..color = const Color(0xFF8B5A2B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
      canvas.rotate(pi);
      final tp = TextPainter(text: const TextSpan(text: '🐢', style: TextStyle(fontSize: 15)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(-tp.width / 2, 2 - tp.height / 2));
    }
    canvas.restore();
  }
}

class _Bubble {
  double x, y, r, speed, phase;
  _Bubble(this.x, this.y, this.r, this.speed, this.phase);
  factory _Bubble.random(Random r, double w, double h) => _Bubble(r.nextDouble() * w, r.nextDouble() * h, 2 + r.nextDouble() * 5, 20 + r.nextDouble() * 40, r.nextDouble() * 6);
}

class _Fish {
  double x, y, speed, size, phase;
  final String emoji;
  _Fish(this.x, this.y, this.speed, this.size, this.phase, this.emoji);
  factory _Fish.random(Random r, int zone) {
    const shallow = ['🐠', '🐟', '🐡', '🐬'], deep = ['🦑', '🐙', '🦈', '🐡'];
    final l = zone <= 2 ? shallow : deep;
    final dir = r.nextBool() ? 1 : -1;
    return _Fish(r.nextDouble() * 360, 120 + r.nextDouble() * 300, dir * (18 + r.nextDouble() * 30), 20 + r.nextDouble() * 14, r.nextDouble() * 6, l[r.nextInt(l.length)]);
  }
}
