import 'dart:math';
import 'package:flutter/material.dart';
import 'props.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../core/audio.dart';
import '../engine/campaign.dart';
import '../engine/meta.dart';
import '../engine/levels.dart';
import '../story/story_lines.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'common.dart';

Future<void> showRewardModal(BuildContext context, {required SessionOutcome outcome, required GameId game, required int companion, required int level, Quest? quest}) async {
  // voiced moments: Story Gem (Dadi), effort gift (Milo), then the next guardian's "next time…" teaser
  var open = true;
  Future<void> narrate() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    for (final id in [if (outcome.gem != null) 'gem_found', if (outcome.gift != null) 'gift_found', ?outcome.teaser]) {
      final l = StoryLines.instance[id];
      if (!open || l == null) return;
      await AudioManager.instance.voice(id, l.text, character: l.who);
    }
  }

  narrate();
  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => _RewardDialog(outcome: outcome, game: game, companion: companion, level: level, quest: quest),
    transitionBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child)),
  );
  open = false;
  AudioManager.instance.stopVoice();
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
                  if (quest != null) ...[
                    const SizedBox(height: 10),
                    _LevelResult(outcome: outcome, game: game),
                  ],
                  if (outcome.unlockedGame != null) ...[
                    const SizedBox(height: 10),
                    _Moment(Skills.game(outcome.unlockedGame!).emoji, 'New game unlocked!', '${Skills.game(outcome.unlockedGame!).name} is open on this island', const Color(0xFFE3F6E5)),
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
                    Text('🏆 Every level on this island is cleared! +5 stars', textAlign: TextAlign.center, style: ts(18, color: C.greenDark)),
                  ],
                  if (outcome.gem != null) ...[
                    const SizedBox(height: 12),
                    _Moment(islandGem[outcome.gem]!.$1, 'Story Gem!', islandGem[outcome.gem]!.$2, const Color(0xFFEDE4FF)),
                  ],
                  if (outcome.gift != null) ...[
                    const SizedBox(height: 10),
                    _Moment(outcome.gift!.$1, 'Milo found a gift!', 'A ${outcome.gift!.$2}, for trying so hard', const Color(0xFFFFF1C2)),
                  ],
                  if (outcome.newItems.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                      for (final (c, i) in outcome.newItems.take(4))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE8F8EE), borderRadius: BorderRadius.circular(16)),
                          child: Text('${i.emoji}  ${i.name} · ${c.name}', style: ts(14, color: C.greenDark)),
                        ),
                    ]),
                  ],
                  if (outcome.teaser != null && StoryLines.instance[outcome.teaser!] != null) ...[
                    const SizedBox(height: 12),
                    Text('“${StoryLines.instance[outcome.teaser!]!.text}”', textAlign: TextAlign.center, style: ts(15, color: C.inkSoft, w: FontWeight.w600)),
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

/// "Level 2 cleared!" or a gentle "play it again", with the 4 level dots of this game.
class _LevelResult extends StatelessWidget {
  final SessionOutcome outcome;
  final GameId game;
  const _LevelResult({required this.outcome, required this.game});
  @override
  Widget build(BuildContext context) {
    final l = outcome.level;
    final ok = outcome.levelPassed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: ok ? const Color(0xFFE3F6E5) : const Color(0xFFFFF1C2), borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Text(
          ok ? (outcome.levelNew ? 'Level $l cleared! ⭐' : 'Level $l played again ⭐') : 'Almost! Play level $l again to clear it',
          textAlign: TextAlign.center,
          style: ts(19, color: ok ? C.greenDark : C.orangeDark),
        ),
        if (!ok) Text('Get at least half right the first time.', textAlign: TextAlign.center, style: ts(13, color: C.inkSoft, w: FontWeight.w600)),
        if (outcome.islandKeysMax > 0) ...[
          const SizedBox(height: 6),
          // v3 keys: this play, best ever, and what is still to win
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < outcome.keysMax; k++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + k * 180),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: k < outcome.keysWon ? v : 1, child: child),
                child: Opacity(opacity: k < outcome.keysBest ? 1 : .2, child: const Text('🔑', style: TextStyle(fontSize: 30))),
              ),
          ]),
          Text(
            outcome.keysBest >= outcome.keysMax
                ? 'All ${outcome.keysMax} keys on this level!'
                : '${outcome.keysWon} ${outcome.keysWon == 1 ? 'key' : 'keys'} · get every answer right for all ${outcome.keysMax}',
            textAlign: TextAlign.center,
            style: ts(14, color: C.inkSoft, w: FontWeight.w600),
          ),
          Text('Island: 🔑 ${outcome.islandKeys} / ${outcome.islandKeysMax}', style: ts(15, color: const Color(0xFF8A6100))),
        ],
        if (ok && outcome.levelNew && l < levelsPerGame) Text('Level ${l + 1} is open!', style: ts(14, color: C.inkSoft, w: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var k = 1; k <= levelsPerGame; k++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: k < l || (k == l && ok) ? C.green : (k == l ? C.orange : Colors.black12),
              ),
              child: Text('$k', style: ts(15, color: Colors.white)),
            ),
        ]),
        Text(Skills.game(game).name, style: ts(12, color: C.inkSoft, w: FontWeight.w600)),
      ]),
    );
  }
}

/// A highlighted reward moment (Story Gem, effort gift) with a pop-in.
class _Moment extends StatelessWidget {
  final String emoji, title, sub;
  final Color bg;
  const _Moment(this.emoji, this.title, this.sub, this.bg);
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: .5 + .5 * v, child: child),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 42)),
            const SizedBox(width: 10),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: ts(19, color: C.purpleDark)),
                Text(sub, style: ts(15, color: C.inkSoft, w: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      );
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
