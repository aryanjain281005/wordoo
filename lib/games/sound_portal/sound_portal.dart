import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/assets.dart';
import '../../core/audio.dart';
import '../../core/theme.dart';
import '../../core/tts.dart';
import '../../data/strings.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../game_module.dart';

const portalCritters = ['🐞', '🐌', '🐸', '🦎', '🐤', '🐹', '🐰', '🦔', '🐢', '🐿️', '🦋', '🐛'];

/// Game 4 · Sound Portal — "Bolt's Broken Portals".
/// A sound orb hums on the left; letter portals glow on the right. The child drags an energy beam from the
/// orb to the portal that makes that sound (or taps a portal). The matching portal hums when the beam is
/// near it (scaffold). A fixed portal sends a critter zooming through.
class SoundPortalItem extends StatefulWidget {
  final GameCtx ctx;
  final int critters; // persistent: portals fixed so far (Portal Critters)
  const SoundPortalItem({super.key, required this.ctx, this.critters = 0});
  @override
  State<SoundPortalItem> createState() => _SoundPortalItemState();
}

class _SoundPortalItemState extends State<SoundPortalItem> with TickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final AnimationController _ride = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  final List<String> _tags = [];
  final Set<int> _faded = {};
  final Map<int, int> _zap = {};
  Size _area = Size.zero; // the board, measured by LayoutBuilder
  /// Portals shrink on short boards so all of them always fit.
  double get _portalSize => _area == Size.zero ? 96.0 : min(96.0, (_area.height - 16) / n - 10);
  Offset? _beamEnd; // while dragging
  int? _near;
  int? _linked; // portal joined to the orb
  int _attempts = 0;
  bool _resolved = false;
  bool _disposed = false;

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  bool get demo => widget.ctx.demo;
  int get n => it.options.length;
  void _say(String t) => Speaker.instance.speak(t, widget.ctx.pack.tts);

  @override
  void initState() {
    super.initState();
    if (widget.ctx.scaffold && n > 2) {
      _faded.add(
        [
          for (var i = 0; i < n; i++)
            if (i != it.correct) i,
        ].first,
      );
      widget.ctx.feedback(Str.t(lang, 'hint'), true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (demo) {
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!_disposed) _connect(it.correct, force: true);
      } else {
        _say(it.say);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _spin.dispose();
    _ride.dispose();
    super.dispose();
  }

  /// Portals sit in the right 5/9 of the board, spaced evenly top to bottom (same maths as the layout).
  Offset? _portalCentre(int i) {
    if (_area == Size.zero) return null;
    final gap = max(0.0, (_area.height - n * _portalSize) / (n + 1));
    return Offset(_area.width * 4 / 9 + _area.width * 5 / 9 / 2, gap * (i + 1) + _portalSize * i + _portalSize / 2);
  }

  int? _portalAt(Offset p) {
    for (var i = 0; i < n; i++) {
      final c = _portalCentre(i);
      if (c != null && (c - p).distance < 56 && !_faded.contains(i)) return i;
    }
    return null;
  }

  void _drag(Offset p) {
    if (_resolved || demo) return;
    final near = _portalAt(p);
    if (near != _near && near != null && widget.ctx.scaffold && near == it.correct) AudioManager.instance.sfx('zap', volume: .25);
    setState(() {
      _beamEnd = p;
      _near = near;
    });
  }

  void _release() {
    final target = _near;
    setState(() {
      _beamEnd = null;
      _near = null;
    });
    if (target != null) _connect(target);
  }

  void _connect(int i, {bool force = false}) {
    if (_resolved || (demo && !force) || _faded.contains(i)) return;
    AudioManager.instance.sfx('zap', volume: .5);
    if (i == it.correct) {
      final first = _attempts == 0;
      setState(() {
        _resolved = true;
        _linked = i;
      });
      _ride.forward(from: 0);
      if (demo) return;
      AudioManager.instance.sfx('power_up', volume: .5);
      _say(it.say);
      widget.ctx.feedback(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
      _finish(first, 1800);
      return;
    }
    _attempts++;
    final t = it.options[i].tag;
    if (t != null) _tags.add(t);
    final canRetry = _attempts < 2 && (n - _faded.length - 1) > 1;
    setState(() {
      _zap[i] = (_zap[i] ?? 0) + 1;
      _faded.add(i);
      if (!canRetry) {
        _resolved = true;
        _linked = it.correct;
      }
    });
    AudioManager.instance.sfx('miss_soft');
    if (canRetry) {
      widget.ctx.feedback('Beep! Crossed wires. ${it.hint}', false);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!_disposed) _say(it.say);
      });
    } else {
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      _say(it.say);
      _finish(false, 2400);
    }
  }

  void _finish(bool first, int delayMs) {
    final r = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: first, ms: _clock.elapsedMilliseconds, tags: [..._tags]);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_disposed && !demo) widget.ctx.done(r);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(10, 4, 10, 6), child: _header()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: LayoutBuilder(
                builder: (context, box) {
                  _area = Size(box.maxWidth, box.maxHeight);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ArtImage(
                        'bg.portal.workshop',
                        fit: BoxFit.cover,
                        fallback: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF16324F), Color(0xFF2E5E7E), Color(0xFF1B3A4B)],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_spin, _ride]),
                            builder: (_, _) => CustomPaint(
                              painter: _BeamPainter(
                                orb: _orbCentre(),
                                end: _beamEnd ?? (_linked != null ? _portalCentre(_linked!) : null),
                                linked: _linked != null,
                                t: _spin.value,
                                ride: _ride.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(flex: 4, child: Center(child: _orb())),
                          Expanded(
                            flex: 5,
                            child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (var i = 0; i < n; i++) _portal(i)]),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Offset? _orbCentre() => _area == Size.zero ? null : Offset(_area.width * 4 / 9 / 2, _area.height / 2);

  Widget _header() => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(22)),
    child: Row(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: ArtImage(
            'char.bolt.happy',
            fallback: const Center(child: Text('🤖', style: TextStyle(fontSize: 38))),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Drag the beam to the letters that make this sound', style: ts(16, color: C.ink)),
              if (!demo)
                Text(
                  '${portalCritters[widget.critters % portalCritters.length]} ${widget.critters} Portal Critters',
                  style: ts(12, color: C.inkSoft, w: FontWeight.w600),
                ),
            ],
          ),
        ),
        RoundIconButton(icon: Icons.volume_up_rounded, label: 'Hear the sound', color: C.gold, size: 44, onTap: demo ? () {} : () => _say(it.say)),
      ],
    ),
  );

  Widget _orb() => GestureDetector(
    onTap: demo ? null : () => _say(it.say),
    onPanStart: demo ? null : (d) => _drag(_orbCentre()! + d.localPosition - const Offset(52, 52)),
    onPanUpdate: demo ? null : (d) => _drag(_orbCentre()! + d.localPosition - const Offset(52, 52)),
    onPanEnd: demo ? null : (_) => _release(),
    child: AnimatedBuilder(
      animation: _spin,
      builder: (_, _) => Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFFFFFDE0), Color(0xFF7CE0FF), Color(0xFF2C86B8)]),
          boxShadow: [BoxShadow(color: const Color(0xFF7CE0FF).withValues(alpha: .5 + .3 * sin(_spin.value * 2 * pi)), blurRadius: 30, spreadRadius: 4)],
        ),
        child: const Icon(Icons.graphic_eq_rounded, size: 50, color: Color(0xFF16324F)),
      ),
    ),
  );

  Widget _portal(int i) {
    final faded = _faded.contains(i);
    final near = _near == i;
    final linked = _linked == i;
    final hum = widget.ctx.scaffold && near && i == it.correct;
    return Opacity(
      opacity: faded ? .3 : 1,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('p$i${_zap[i] ?? 0}'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (_, t, child) => Transform.translate(offset: Offset((_zap[i] ?? 0) == 0 ? 0 : sin(t * pi * 6) * 6 * (1 - t), 0), child: child),
        child: GestureDetector(
          onTap: demo ? null : () => _connect(i),
          child: AnimatedBuilder(
            animation: _spin,
            builder: (_, child) => Transform.scale(scale: hum ? 1.08 + .04 * sin(_spin.value * 40) : (near ? 1.06 : 1), child: child),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _spin,
                  builder: (_, _) => Transform.rotate(
                    angle: _spin.value * 2 * pi * (i.isEven ? 1 : -1),
                    child: Container(
                      width: _portalSize,
                      height: _portalSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: linked
                              ? const [Color(0xFF8CFF9E), Color(0xFF2FA866), Color(0xFF8CFF9E)]
                              : const [Color(0xFFB98CFF), Color(0xFF5A3FD8), Color(0xFF7CE0FF), Color(0xFFB98CFF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (linked ? const Color(0xFF8CFF9E) : const Color(0xFFB98CFF)).withValues(alpha: near || linked ? .8 : .4),
                            blurRadius: near || linked ? 24 : 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: _portalSize * .77,
                  height: _portalSize * .77,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF101A33)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(it.options[i].label, style: ts(32, color: Colors.white)),
                    ),
                  ),
                ),
                if (linked)
                  AnimatedBuilder(
                    animation: _ride,
                    builder: (_, _) => Transform.translate(
                      offset: Offset(-60 + 120 * _ride.value, -50 * sin(_ride.value * pi)),
                      child: Opacity(
                        opacity: (1 - _ride.value).clamp(0.0, 1.0),
                        child: Text(portalCritters[widget.critters % portalCritters.length], style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The energy beam: a wobbly bright line from the orb to the finger (or to the linked portal).
class _BeamPainter extends CustomPainter {
  final Offset? orb, end;
  final bool linked;
  final double t, ride;
  _BeamPainter({required this.orb, required this.end, required this.linked, required this.t, required this.ride});
  @override
  void paint(Canvas canvas, Size size) {
    if (orb == null || end == null) return;
    final a = orb!, b = end!;
    final path = Path()..moveTo(a.dx, a.dy);
    const seg = 18;
    final normal = Offset(-(b - a).dy, (b - a).dx) / max(1.0, (b - a).distance);
    for (var k = 1; k <= seg; k++) {
      final f = k / seg;
      final wob = sin(f * pi * 6 + t * 40) * 6 * sin(f * pi);
      final p = Offset.lerp(a, b, f)! + normal * wob;
      path.lineTo(p.dx, p.dy);
    }
    final col = linked ? const Color(0xFF8CFF9E) : const Color(0xFF7CE0FF);
    canvas.drawPath(
      path,
      Paint()
        ..color = col.withValues(alpha: .35)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_BeamPainter o) => true;
}
