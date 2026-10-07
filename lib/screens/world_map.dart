import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../data/strings.dart';
import '../engine/personalizer.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import 'collection.dart';
import 'game_screen.dart';
import 'parent_gate.dart';

class _Region {
  final String id;
  final Skill? skill;
  final String name, tag;
  final String landmark;
  final Color grass, grassDark;
  final Offset wide, tall;
  const _Region(this.id, this.skill, this.name, this.tag, this.landmark, this.grass, this.grassDark, this.wide, this.tall);
}

const _regions = <_Region>[
  _Region('forest', Skill.phonological, 'Sound Forest', 'Foundations', '🌲🌳🌲', Color(0xFF56C27E), Color(0xFF2E9B5B), Offset(.14, .27), Offset(.27, .075)),
  _Region('valley', Skill.gpc, 'Symbol Valley', 'Letters', '🏹⛰️', Color(0xFFA98BF0), Color(0xFF7B5BD0), Offset(.40, .14), Offset(.73, .17)),
  _Region('ocean', Skill.decoding, 'Word Ocean', 'Decoding', '⛵🐠', Color(0xFF5BC4EE), Color(0xFF2E96C8), Offset(.19, .62), Offset(.27, .30)),
  _Region('village', Skill.wordRecognition, 'Word Village', 'Familiar words', '🏘️🔍', Color(0xFFFFB866), Color(0xFFE08A2B), Offset(.62, .42), Offset(.73, .41)),
  _Region('treasure', Skill.spelling, 'Treasure Island', 'Spelling', '🏝️💰', Color(0xFFFFD35C), Color(0xFFE0A41A), Offset(.44, .77), Offset(.27, .53)),
  _Region('castle', Skill.comprehension, 'Story Castle', 'Comprehension', '🏰📖', Color(0xFFFF8FB8), Color(0xFFD9578A), Offset(.83, .72), Offset(.73, .66)),
  _Region('sky', null, 'Sky Station', 'Advanced', '🛰️🚀', Color(0xFF9AA8FF), Color(0xFF6A78E0), Offset(.86, .20), Offset(.27, .88)),
];

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});
  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  bool _skyToast = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final st = context.read<AppState>();
      if (st.history.length >= 2 && !st.badges.contains('sky-seen')) {
        st.badges.add('sky-seen');
        setState(() => _skyToast = true);
        st.changed();
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _skyToast = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  Future<void> _play(GameId g, {int? level}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreen(game: g, levelOverride: level)));
  }

  void _openRegion(_Region r) {
    final st = context.read<AppState>();
    if (r.skill == null) {
      if (st.history.length < 2) {
        _toast('Finish the next adventure checkpoint to unlock the Sky Station!');
        return;
      }
      // advanced challenge: stretch the strongest skill
      final strongest = Personalizer.ranked(st.skills).last;
      _play(Skills.of(strongest).demoGame, level: 4);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RegionSheet(skill: r.skill!, onPlay: (g) {
        Navigator.of(context).pop();
        _play(g);
      }),
    );
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m, style: ts(16, color: Colors.white)), behavior: SnackBarBehavior.floating, backgroundColor: C.ink));

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final rank = Personalizer.ranked(st.skills);
    final nextMission = st.missions.where((m) => !m.done).firstOrNull;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: AnimatedBuilder(animation: _wave, builder: (_, __) => CustomPaint(painter: WavesPainter(_wave.value)))),
        SafeArea(
          child: Column(children: [
            _hud(st),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth / max(c.maxHeight, 1) > 1.15;
                final canvasH = wide ? c.maxHeight : max(c.maxHeight, c.maxWidth * 3.0);
                final canvasW = c.maxWidth;
                final base = wide ? min(min(canvasW * .19, canvasH * .27), 190.0) : min(canvasW * .36, 150.0);
                return SingleChildScrollView(
                  physics: wide ? const NeverScrollableScrollPhysics() : null,
                  child: SizedBox(
                    width: canvasW,
                    height: canvasH,
                    child: Stack(children: [
                      for (final r in _regions)
                        _island(r, st, rank, nextMission, canvasW, canvasH, wide, base),
                    ]),
                  ),
                );
              }),
            ),
            _bottom(st),
          ]),
        ),
        if (_skyToast)
          Positioned(
            top: 90,
            left: 20,
            right: 20,
            child: Pop(
              child: Center(
                child: Panel(
                  color: const Color(0xFFFFF9E8),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  child: Text('🛰️ New area unlocked: Sky Station!', textAlign: TextAlign.center, style: ts(22, color: C.purple)),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _island(_Region r, AppState st, List<Skill> rank, Mission? next, double w, double h, bool wide, double base) {
    final pos = wide ? r.wide : r.tall;
    final locked = r.skill == null && st.history.length < 2;
    var scale = 1.0;
    int? order;
    var done = false;
    if (r.skill != null) {
      final rk = rank.indexOf(r.skill!);
      scale = [1.28, 1.16, 1.06, .98, .94, .9][rk];
      final mi = st.missions.indexWhere((m) => m.skill == r.skill);
      if (mi >= 0) {
        order = mi + 1;
        done = st.missions[mi].done;
      }
    }
    final isNext = next != null && r.skill == next.skill;
    final size = base * scale;
    final totalH = size * .95 + 70;
    final level = r.skill == null ? 0 : st.skills[r.skill!]!.level;
    final band = r.skill == null ? null : st.bandOf(r.skill!);
    return Positioned(
      left: (pos.dx * w - size / 2).clamp(0, max(0.0, w - size)),
      top: (pos.dy * h - totalH / 2).clamp(0, max(0.0, h - totalH)),
      child: SizedBox(
        width: size,
        height: totalH,
        child: Pop(
          index: _regions.indexOf(r),
          child: Semantics(
            button: true,
            label: '${r.name}, ${r.tag}',
            child: GestureDetector(
              onTap: () => _openRegion(r),
              child: Column(children: [
                _label(r, order, done, locked, isNext),
                const SizedBox(height: 2),
                Expanded(
                  child: Stack(alignment: Alignment.center, children: [
                    if (isNext) _PulseRing(size: size),
                    Positioned.fill(child: CustomPaint(painter: IslandPainter(r.grass, r.grassDark, locked: locked))),
                    Positioned(top: size * .08, child: Opacity(opacity: locked ? .45 : 1, child: Text(r.landmark, style: TextStyle(fontSize: size * .30)))),
                    if (locked) Positioned(top: size * .22, child: Text('🔒', style: TextStyle(fontSize: size * .26))),
                    if (band == Band.strong) Positioned(right: size * .08, top: size * .06, child: Text('✨', style: TextStyle(fontSize: size * .15))),
                    if (r.skill != null)
                      Positioned(bottom: size * .30, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(14)), child: PowerPips(level: level, emoji: '⭐'))),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(_Region r, int? order, bool done, bool locked, bool isNext) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (order != null)
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: done ? C.green : C.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
          child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : Text('$order', style: ts(16, color: Colors.white)),
        ),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: locked ? [const Color(0xFF8A92B2), const Color(0xFF6C7494)] : [const Color(0xFF2B6A4E), const Color(0xFF1C4A38)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isNext ? C.gold : Colors.white70, width: isNext ? 3 : 2),
            boxShadow: [softShadow(const Color(0x44000000), 8, 4)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(r.name, style: ts(15, color: Colors.white))),
            FittedBox(fit: BoxFit.scaleDown, child: Text(r.tag, style: ts(11, color: Colors.white70, w: FontWeight.w600))),
          ]),
        ),
      ),
    ]);
  }

  Widget _hud(AppState st) {
    final hat = st.avatar.hat >= 0 ? Collectibles.all[st.avatar.hat].emoji : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
          decoration: BoxDecoration(color: C.ink.withValues(alpha: .85), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white54, width: 2)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            ClipOval(child: Container(width: 40, height: 40, color: const Color(0xFFBEE7FF), child: FittedBox(fit: BoxFit.cover, alignment: const Alignment(0, -.85), child: SizedBox(width: 60, height: 130, child: AvatarView(hair: st.avatar.hair, outfit: st.avatar.outfit, height: 130, hatEmoji: hat))))),
            const SizedBox(width: 8),
            Text(st.explorerName, style: ts(18, color: Colors.white)),
          ]),
        ),
        const Spacer(),
        StarChip(st.stars),
        const SizedBox(width: 8),
        RoundIconButton(icon: Icons.backpack_rounded, label: 'My treasures', size: 50, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectionScreen()))),
        const SizedBox(width: 8),
        RoundIconButton(icon: Icons.settings_rounded, label: 'Grown-up area', size: 50, onTap: () async {
          if (await askParentGate(context)) {
            if (mounted) context.read<AppState>().go(AppScreen.dashboard);
          }
        }),
      ]),
    );
  }

  Widget _bottom(AppState st) {
    final lang = st.langCode;
    Widget content;
    if (st.weekReady) {
      content = Row(children: [
        Companion(type: st.avatar.companion, size: 76),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Next Adventure Awaits!', style: ts(20, color: Colors.white)),
            Text('New challenges, new treasure!', style: ts(14, color: Colors.white70, w: FontWeight.w600)),
          ]),
        ),
        BigButton(label: 'Let’s Go!', style: BtnStyle.go, height: 56, fontSize: 20, onTap: () => st.go(AppScreen.intro)),
      ]);
    } else if (st.dayDone) {
      content = Row(children: [
        Companion(type: st.avatar.companion, size: 76),
        const SizedBox(width: 8),
        Expanded(child: Text('🎉 Today’s adventure is done! See you tomorrow, ${st.explorerName}!', style: ts(17, color: Colors.white))),
        BigButton(label: 'Tomorrow', icon: Icons.skip_next_rounded, style: BtnStyle.soft, height: 52, fontSize: 16, onTap: st.advanceDay),
      ]);
    } else {
      content = Row(children: [
        Companion(type: st.avatar.companion, size: 70),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Day ${st.day} • ${Str.t(lang, 'whereToday')}', style: ts(15, color: Colors.white)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [for (var i = 0; i < st.missions.length; i++) _missionChip(st, i)]),
            ),
          ]),
        ),
      ]);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(color: C.night.withValues(alpha: .86), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(top: false, child: content),
    );
  }

  Widget _missionChip(AppState st, int i) {
    final m = st.missions[i];
    final g = Skills.game(m.game);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: m.done ? null : () => _play(m.game),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: m.done ? C.green.withValues(alpha: .35) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: m.done ? C.green : C.orange, width: 3),
          ),
          child: Row(children: [
            Text(m.done ? '✅' : g.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(g.name, style: ts(15, color: m.done ? Colors.white : C.ink)),
          ]),
        ),
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  final double size;
  const _PulseRing({required this.size});
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: widget.size * (1.0 + _c.value * .06),
          height: widget.size * .8 * (1.0 + _c.value * .06),
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: C.gold.withValues(alpha: .55 * (1 - _c.value * .5)), blurRadius: 36, spreadRadius: 4)]),
        ),
      );
}

class _RegionSheet extends StatelessWidget {
  final Skill skill;
  final void Function(GameId) onPlay;
  const _RegionSheet({required this.skill, required this.onPlay});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final meta = Skills.of(skill);
    final level = st.skills[skill]!.level;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(color: Color(0xFFFFF9E8), borderRadius: BorderRadius.vertical(top: Radius.circular(34))),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 12),
          Text('${meta.emoji}  ${meta.region}', style: ts(30)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Your power: ', style: ts(15, color: C.inkSoft)), PowerPips(level: level, emoji: '⚡')]),
          const SizedBox(height: 14),
          for (final gid in meta.games) _GameRow(game: Skills.game(gid), onPlay: onPlay),
        ]),
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  final GameMeta game;
  final void Function(GameId) onPlay;
  const _GameRow({required this.game, required this.onPlay});
  @override
  Widget build(BuildContext context) {
    final locked = !game.playable;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: locked ? const Color(0xFFEDEBF5) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: locked ? Colors.black12 : game.color, width: 3)),
        child: Row(children: [
          Text(locked ? '🔒' : game.emoji, style: const TextStyle(fontSize: 38)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(game.name, style: ts(20, color: locked ? C.inkSoft : C.ink)),
              Text(locked ? 'Coming on a future adventure' : game.tagline, style: ts(14, color: C.inkSoft, w: FontWeight.w600)),
            ]),
          ),
          if (!locked) BigButton(label: 'Play', icon: Icons.play_arrow_rounded, style: BtnStyle.go, height: 52, fontSize: 18, onTap: () => onPlay(game.id)),
        ]),
      ),
    );
  }
}
