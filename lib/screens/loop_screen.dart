import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

/// "Continuous Learning Loop" — the core innovation, shown as an animated cycle.
class LoopScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final String buttonLabel;
  const LoopScreen({super.key, required this.onContinue, this.buttonLabel = 'Start the next adventure'});
  @override
  State<LoopScreen> createState() => _LoopScreenState();
}

class _LoopScreenState extends State<LoopScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _nodes = [
    ('1', 'Assess', 'Fresh items every week', '📋', Color(0xFF6C4DF0)),
    ('2', 'Personalize', 'New plan from the profile', '🗺️', Color(0xFFE0568A)),
    ('3', 'Play', 'Daily adventures (~10 min)', '🎮', Color(0xFF2FA866)),
    ('4', 'Measure', 'Every answer is noticed', '📈', Color(0xFFF08A24)),
    ('5', 'Re-personalize', 'Levels adapt per skill', '🔁', Color(0xFF1E88E5)),
  ];

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return AdventureBackground(
      scene: Scene.night,
      calm: true,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text('Continuous Learning Loop', textAlign: TextAlign.center, style: ts(30, color: Colors.white, w: FontWeight.w900)),
          ),
          Text('Assess → Personalize → Play → Measure → Re-personalize', textAlign: TextAlign.center, style: ts(15, color: Colors.white70, w: FontWeight.w600)),
          Expanded(
            child: LayoutBuilder(builder: (_, c) {
              final size = min(c.maxWidth, c.maxHeight);
              final r = size * .36;
              final cx = c.maxWidth / 2, cy = c.maxHeight / 2;
              return AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final active = (_c.value * 5).floor() % 5;
                  return Stack(children: [
                    Positioned.fill(child: CustomPaint(painter: _RingPainter(Offset(cx, cy), r, _c.value))),
                    Positioned(left: cx - 70, top: cy - 90, child: AvatarView(hair: st.avatar.hair, outfit: st.avatar.outfit, height: 130)),
                    Positioned(left: cx + 10, top: cy - 10, child: Companion(type: st.avatar.companion, size: 80)),
                    for (var i = 0; i < 5; i++)
                      _node(i, cx + r * cos(-pi / 2 + i * 2 * pi / 5), cy + r * sin(-pi / 2 + i * 2 * pi / 5), i == active),
                  ]);
                },
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(children: [
              Text('The child gets a journey built around their own skills — and it keeps adapting.', textAlign: TextAlign.center, style: ts(16, color: Colors.white, w: FontWeight.w600)),
              const SizedBox(height: 12),
              BigButton(label: widget.buttonLabel, icon: Icons.arrow_forward_rounded, style: BtnStyle.go, width: 400, onTap: widget.onContinue),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _node(int i, double x, double y, bool active) {
    final n = _nodes[i];
    return Positioned(
      left: x - 62,
      top: y - 38,
      width: 124,
      child: AnimatedScale(
        scale: active ? 1.12 : 1,
        duration: const Duration(milliseconds: 400),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: n.$5, width: active ? 5 : 3),
            boxShadow: [softShadow(active ? n.$5.withValues(alpha: .6) : const Color(0x44000000), active ? 20 : 8, 4)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${n.$1}  ${n.$4}', style: ts(20, color: n.$5)),
            Text(n.$2, style: ts(15), textAlign: TextAlign.center),
            Text(n.$3, style: ts(10.5, color: C.inkSoft, w: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2),
          ]),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Offset c;
  final double r, t;
  _RingPainter(this.c, this.r, this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, p);
    final a = -pi / 2 + t * 2 * pi;
    final dot = c + Offset(cos(a), sin(a)) * r;
    canvas.drawCircle(dot, 12, Paint()..color = C.gold);
    canvas.drawCircle(dot, 20, Paint()..color = C.gold.withValues(alpha: .3));
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.t != t;
}
