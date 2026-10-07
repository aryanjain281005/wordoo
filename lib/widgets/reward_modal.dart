import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'common.dart';

Future<void> showRewardModal(BuildContext context, {required SessionOutcome outcome, required GameId game, required int companion, required int level}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => _RewardDialog(outcome: outcome, game: game, companion: companion, level: level),
    transitionBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child)),
  );
}

class _RewardDialog extends StatelessWidget {
  final SessionOutcome outcome;
  final GameId game;
  final int companion, level;
  const _RewardDialog({required this.outcome, required this.game, required this.companion, required this.level});

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
                  Text('You Did It!', style: ts(40, color: C.purple, w: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < 3; i++)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 500 + i * 350),
                        curve: Curves.elasticOut,
                        builder: (_, v, __) => Transform.scale(
                          scale: i < outcome.stars ? v : .8,
                          child: Text('⭐', style: TextStyle(fontSize: 58, color: i < outcome.stars ? null : Colors.grey.withValues(alpha: .35), shadows: i < outcome.stars ? null : null)),
                        ),
                      ),
                  ]),
                  Opacity(opacity: .0, child: Container()),
                  Text('+${outcome.stars} stars', style: ts(24, color: C.orangeDark)),
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
                  if (outcome.dayComplete) ...[
                    const SizedBox(height: 10),
                    Text('🎉 Today’s adventure is complete! +3 bonus stars', textAlign: TextAlign.center, style: ts(18, color: C.greenDark)),
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
