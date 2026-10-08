import 'dart:math';
import 'package:flutter/material.dart';
import 'props.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../engine/campaign.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'common.dart';

Future<void> showRewardModal(BuildContext context, {required SessionOutcome outcome, required GameId game, required int companion, required int level, Quest? quest}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => _RewardDialog(outcome: outcome, game: game, companion: companion, level: level, quest: quest),
    transitionBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child)),
  );
}

class _RewardDialog extends StatelessWidget {
  final SessionOutcome outcome;
  final GameId game;
  final int companion, level;
  final Quest? quest;
  const _RewardDialog({required this.outcome, required this.game, required this.companion, required this.level, this.quest});

  @override
  Widget build(BuildContext context) {
    final g = Skills.game(game);
    final up = outcome.adapt.any((e) => e.up);
    final down = outcome.adapt.any((e) => e.down);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Panel(
                color: const Color(0xFFFFF9E8),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  outlinedText('You Did It!', 46, fill: const Color(0xFFFFD34D), stroke: const Color(0xFF5B3DD8)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 150,
                    child: Stack(alignment: Alignment.center, children: [
                      const _Sunburst(),
                      Positioned(bottom: 0, child: SizedBox(width: 130, height: 90, child: CustomPaint(painter: _ChestPainter()))),
                      for (var i = 0; i < 3; i++)
                        Positioned(
                          top: i == 1 ? 0 : 14,
                          left: 40.0 + i * 70,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 500 + i * 350),
                            curve: Curves.elasticOut,
                            builder: (_, v, __) => Transform.scale(
                              scale: i < outcome.stars ? v : .75,
                              child: Text('⭐', style: TextStyle(fontSize: i == 1 ? 64 : 50, color: i < outcome.stars ? null : Colors.grey.withValues(alpha: .35))),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  Opacity(opacity: .0, child: Container()),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _RewardCard('⭐', '+${outcome.stars * 10} XP', C.gold),
                    const SizedBox(width: 8),
                    _RewardCard('🌟', '+${outcome.stars} stars', C.orange),
                    const SizedBox(width: 8),
                    _RewardCard(outcome.newCollectibles.isNotEmpty ? outcome.newCollectibles.first.emoji : '🎁', outcome.newCollectibles.isNotEmpty ? 'New treasure' : 'Keep going', C.pink),
                  ]),
                  const SizedBox(height: 10),
                  Companion(type: companion, size: 96, message: up ? 'You’re getting stronger!' : (down ? 'Great effort! We’ll practise this together.' : 'Great job, Explorer!')),
                  if (up || down) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: (up ? C.green : C.sky).withValues(alpha: .15), borderRadius: BorderRadius.circular(18)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(g.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 8),
                        Flexible(child: Text(up ? '${g.name} got stronger!' : '${g.name}: a friendly warm-up next time', style: ts(17))),
                        const SizedBox(width: 8),
                        PowerPips(level: level),
                      ]),
                    ),
                  ],
                  for (final c in outcome.newCollectibles) ...[
                    const SizedBox(height: 14),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: C.gold.withValues(alpha: .25), borderRadius: BorderRadius.circular(22), border: Border.all(color: C.gold, width: 2.5)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(c.emoji, style: const TextStyle(fontSize: 46)),
                          const SizedBox(width: 12),
                          Flexible(child: Text('You found a new treasure!\n${c.name}', style: ts(18, h: 1.25))),
                        ]),
                      ),
                    ),
                  ],
                  for (final b in outcome.newBadges) ...[
                    const SizedBox(height: 10),
                    Text('${b.emoji}  New badge: ${b.name}', textAlign: TextAlign.center, style: ts(17, color: C.purpleDark)),
                  ],
                  if (quest != null) ...[
                    const SizedBox(height: 12),
                    Text('${Campaign.islandName(quest!.island)} restored', style: ts(15, color: C.inkSoft)),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: outcome.restorationBefore / 100, end: outcome.restorationAfter / 100),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Row(children: [
                        Expanded(child: GameProgressBar(value: v, color: C.green, height: 14)),
                        const SizedBox(width: 8),
                        Text('${(v * 100).round()}%', style: ts(15, color: C.greenDark)),
                      ]),
                    ),
                  ],
                  if (outcome.chapterComplete) ...[
                    const SizedBox(height: 10),
                    Text('🏆 Chapter complete! The island is growing. +5 stars', textAlign: TextAlign.center, style: ts(18, color: C.greenDark)),
                  ],
                  if (outcome.retestUnlocked) ...[
                    const SizedBox(height: 10),
                    Text('🌉 The Star Bridge has appeared! Gumsum is waiting on the map.', textAlign: TextAlign.center, style: ts(17, color: C.purple)),
                  ],
                  const SizedBox(height: 20),
                  BigButton(label: 'Continue', style: BtnStyle.primary, onTap: () => Navigator.of(context).pop(), width: 240),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String emoji, label;
  final Color color;
  const _RewardCard(this.emoji, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(18), border: Border.all(color: color, width: 2.5)),
        child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 28)), FittedBox(child: Text(label, style: ts(13)))]),
      );
}

class _Sunburst extends StatefulWidget {
  const _Sunburst();
  @override
  State<_Sunburst> createState() => _SunburstState();
}

class _SunburstState extends State<_Sunburst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(size: const Size(300, 150), painter: _RayPainter(_c.value)));
}

class _RayPainter extends CustomPainter {
  final double t;
  _RayPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height * .55);
    final p = Paint()..color = const Color(0xFFFFD34D).withValues(alpha: .28);
    for (var i = 0; i < 12; i++) {
      final a = t * 2 * pi + i * pi / 6;
      c.drawPath(Path()..moveTo(center.dx, center.dy)..lineTo(center.dx + cos(a - .1) * 200, center.dy + sin(a - .1) * 200)..lineTo(center.dx + cos(a + .1) * 200, center.dy + sin(a + .1) * 200)..close(), p);
    }
  }

  @override
  bool shouldRepaint(_RayPainter o) => o.t != t;
}

class _ChestPainter extends CustomPainter {
  const _ChestPainter();
  @override
  void paint(Canvas c, Size s) => Props.chest(c, s.width / 2, s.height, s.width * 1.1);
  @override
  bool shouldRepaint(_) => false;
}
