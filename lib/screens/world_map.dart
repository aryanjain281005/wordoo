import 'dart:math';
import 'package:flutter/material.dart';
import '../story/play_scene.dart';
import '../core/assets.dart';
import '../engine/meta.dart';
import 'journal.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../data/strings.dart';
import '../engine/campaign.dart';
import '../engine/personalizer.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/props.dart';
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
  _Region('sky', null, 'Star Observatory', 'All skills', '🛰️🚀', Color(0xFF9AA8FF), Color(0xFF6A78E0), Offset(.86, .20), Offset(.27, .88)),
];

const _regionIsland = {
  'forest': IslandId.forest,
  'valley': IslandId.valley,
  'ocean': IslandId.ocean,
  'village': IslandId.village,
  'treasure': IslandId.treasure,
  'castle': IslandId.castle,
  'sky': IslandId.observatory,
};

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
      if (st.campaign.observatoryUnlocked && !st.badges.contains('obs-s${st.campaign.season}')) {
        st.badges.add('obs-s${st.campaign.season}');
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

  Future<void> _play(Quest q) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreen(quest: q)));
  }

  void _openRegion(_Region r) {
    final st = context.read<AppState>();
    final island = _regionIsland[r.id]!;
    if (island == IslandId.observatory && !st.campaign.observatoryUnlocked) {
      _toast('Finish the chapter on all six islands to open the Star Observatory!');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RegionSheet(island: island, onPlay: (q) {
        Navigator.of(context).pop();
        _play(q);
      }),
    );
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m, style: ts(16, color: Colors.white)), behavior: SnackBarBehavior.floating, backgroundColor: C.ink));

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final rank = Personalizer.byNeed(st.models);
    final board = st.board;
    final nextMission = board.isEmpty ? null : board.first;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: AnimatedBuilder(animation: _wave, builder: (_, __) => CustomPaint(painter: WavesPainter(_wave.value)))),
        SafeArea(
          child: Column(children: [
            _hud(st),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final canvasW = c.maxWidth;
                final canvasH = canvasW * 3.4 + 270;
                final mapH = canvasW * 3.4;
                final base = min(canvasW * .34, 145.0);
                return Stack(children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: canvasW,
                        height: canvasH,
                        child: Stack(children: [
                          Positioned.fill(child: CustomPaint(painter: _TrailPainter([for (final r in _regions) Offset(r.tall.dx * canvasW, r.tall.dy * mapH + base * .35)]))),
                          for (final r in _regions) _island(r, st, rank, nextMission, board, canvasW, mapH, false, base),
                        ]),
                      ),
                    ),
                  ),
                  // explorer + companion waiting on the shore
                  Positioned(
                    left: 6,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Padding(padding: const EdgeInsets.only(left: 18, bottom: 2), child: SpeechBubble(text: Str.t(st.langCode, 'whereToday'), fontSize: 14, maxWidth: 200)),
                        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          AvatarView(hair: st.avatar.hair, outfit: st.avatar.outfit, height: 112, hatEmoji: st.avatar.hat >= 0 ? Collectibles.all[st.avatar.hat].emoji : null),
                          Companion(type: st.avatar.companion, size: 72),
                        ]),
                      ]),
                    ),
                  ),
                ]);
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
                  child: Text('🔭 New island unlocked: the Star Observatory!', textAlign: TextAlign.center, style: ts(22, color: C.purple)),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _island(_Region r, AppState st, List<Skill> rank, Quest? next, List<Quest> board, double w, double h, bool wide, double base) {
    final pos = wide ? r.wide : r.tall;
    final island = _regionIsland[r.id]!;
    final locked = island == IslandId.observatory && !st.campaign.observatoryUnlocked;
    var scale = 1.0;
    final bi = board.indexWhere((q) => q.island == island);
    final int? order = bi >= 0 ? bi + 1 : null;
    final done = st.campaign.chapterDone(island);
    if (r.skill != null) {
      final rk = rank.indexOf(r.skill!);
      scale = [1.28, 1.16, 1.06, .98, .94, .9][rk];
    }
    final isNext = next != null && next.island == island;
    final restoration = st.campaign.restoration(island, st.models);
    final tier = st.campaign.islands[island]!.tier;
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
                  child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                    if (isNext) _PulseRing(size: size),
                    // colour returns as the island is restored (Gumsum's grey fades); painted island art when available
                    Positioned.fill(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(_saturation(locked ? 1 : .35 + .65 * (restoration / 100).clamp(0.0, 1.0))),
                        child: ArtImage('island.${island.name}', fallback: CustomPaint(painter: IslandArt(r.id, r.grass, r.grassDark, locked: locked))),
                      ),
                    ),
                    // the island grows a tier every season
                    if (!locked && tier >= 2) Positioned(left: size * .06, top: size * .06, child: Text(const ['🌱', '🌳', '✨', '👑'][min(tier - 2, 3)], style: TextStyle(fontSize: size * .14))),
                    if (!locked && st.gems.contains(gemId(st.campaign.season, island))) Positioned(left: size * .08, bottom: size * .3, child: Text(islandGem[island]!.$1, style: TextStyle(fontSize: size * .13))),
                    if (locked) Positioned(top: size * .2, child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xCC1E2753), shape: BoxShape.circle), child: Icon(Icons.lock_rounded, color: Colors.white, size: size * .16))),
                    if (band == Band.strong) Positioned(right: size * .04, top: size * .04, child: Text('✨', style: TextStyle(fontSize: size * .15))),
                    if (isNext) Positioned(top: -4, child: _Bounce(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 2)), child: Text('Start here!', style: ts(12, color: C.ink))))),
                    if (!locked)
                      Positioned(
                        bottom: size * .08,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(14), boxShadow: [softShadow(const Color(0x33000000), 6, 2)]),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(tier > 1 ? '${tierName(tier)} ' : '', style: ts(11, color: C.purple)),
                            SizedBox(width: size * .32, child: GameProgressBar(value: restoration / 100, color: C.green, height: 8)),
                            const SizedBox(width: 4),
                            Text('${restoration.round()}%', style: ts(11, color: C.greenDark)),
                            if (r.skill != null) ...[const SizedBox(width: 4), PowerPips(level: level, emoji: '⭐', max: 4)],
                          ]),
                        ),
                      ),
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
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: locked ? [const Color(0xFF8A92B2), const Color(0xFF6C7494)] : [const Color(0xFF2F7A57), const Color(0xFF1B4A37)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isNext ? C.gold : const Color(0xFFE8C46A), width: 2.5),
            boxShadow: [softShadow(const Color(0x44000000), 8, 4)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(r.name, style: ts(15, color: Colors.white))),
            FittedBox(fit: BoxFit.scaleDown, child: Text(done ? '✓ chapter complete' : r.tag, style: ts(11, color: Colors.white70, w: FontWeight.w600))),
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
        RoundIconButton(icon: Icons.menu_book_rounded, label: 'Explorer’s Journal', size: 50, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JournalScreen()))),
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
    final board = st.board;
    Widget content;
    if (st.retestReady) {
      content = Row(children: [
        Companion(type: st.avatar.companion, size: 70),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🌉 The Star Bridge has appeared!', style: ts(18, color: Colors.white)),
            Text('All seven islands played — Gumsum is waiting.', style: ts(13, color: Colors.white70, w: FontWeight.w600)),
          ]),
        ),
        BigButton(label: 'Let’s Go!', style: BtnStyle.go, height: 52, fontSize: 18, onTap: () => playScene(context, 'star_bridge').then((_) => st.go(AppScreen.intro))),
      ]);
    } else {
      content = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('${seasonName(st.campaign.season)} · Quest board', style: ts(15, color: Colors.white)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [for (final q in board) _questChip(q)]),
        ),
      ]);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(color: C.night.withValues(alpha: .86), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(top: false, child: content),
    );
  }

  Widget _questChip(Quest q) {
    final g = Skills.game(q.game);
    final color = switch (q.kind) {
      QuestKind.boss => const Color(0xFFE5483F),
      QuestKind.challenge => C.purple,
      QuestKind.support => C.green,
      QuestKind.observatory => const Color(0xFF6A78E0),
      _ => C.orange,
    };
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _play(q),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: color, width: 3)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(g.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(questKindLabel(q.kind).toUpperCase(), style: ts(10, color: color)),
                Text(q.title, style: ts(14, color: C.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
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
  final IslandId island;
  final void Function(Quest) onPlay;
  const _RegionSheet({required this.island, required this.onPlay});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final camp = st.campaign;
    final ist = camp.islands[island]!;
    final skill = islandSkill[island];
    final q = camp.questFor(island, st.models);
    final need = camp.nodesNeeded(island);
    final restoration = camp.restoration(island, st.models);
    final emoji = skill == null ? '🔭' : Skills.of(skill).emoji;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(color: Color(0xFFFFF9E8), borderRadius: BorderRadius.vertical(top: Radius.circular(34))),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 12),
          Text('$emoji  ${Campaign.islandName(island)}', style: ts(28)),
          Text('${tierName(ist.tier)} · chapter ${ist.nodes.clamp(0, need)}/$need', style: ts(15, color: C.inkSoft)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: GameProgressBar(value: restoration / 100, color: C.green, height: 14)),
            const SizedBox(width: 8),
            Text('${restoration.round()}% restored', style: ts(14, color: C.greenDark)),
          ]),
          if (skill != null) ...[
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Your power: ', style: ts(15, color: C.inkSoft)), PowerPips(level: st.model(skill).band, emoji: '⚡')]),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: C.orange, width: 3)),
            child: Row(children: [
              Text(Skills.game(q.game).emoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(questKindLabel(q.kind).toUpperCase(), style: ts(12, color: C.orangeDark)),
                  Text(q.title, style: ts(19)),
                  Text('${Skills.game(q.game).name} · ${q.items} challenges', style: ts(13, color: C.inkSoft, w: FontWeight.w600)),
                ]),
              ),
              BigButton(label: 'Play', icon: Icons.play_arrow_rounded, style: BtnStyle.go, height: 52, fontSize: 18, onTap: () => onPlay(q)),
            ]),
          ),
          if (skill != null) ...[
            const SizedBox(height: 10),
            for (final gid in Skills.of(skill).games.where((g) => !Skills.game(g).playable)) _GameRow(game: Skills.game(gid)),
          ],
        ]),
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  final GameMeta game;
  const _GameRow({required this.game});
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
        ]),
      ),
    );
  }
}

class _Bounce extends StatefulWidget {
  final Widget child;
  const _Bounce({required this.child});
  @override
  State<_Bounce> createState() => _BounceState();
}

class _BounceState extends State<_Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, ch) => Transform.translate(offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)), child: ch), child: widget.child);
}

/// Dotted adventure trail linking the islands in play order.
class _TrailPainter extends CustomPainter {
  final List<Offset> pts;
  _TrailPainter(this.pts);
  @override
  void paint(Canvas c, Size s) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final midY = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }
    final dot = Paint()..color = Colors.white.withValues(alpha: .75);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 22) {
        final p = m.getTangentForOffset(d)!.position;
        c.drawCircle(p, 3.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter o) => false;
}

/// Colour matrix that blends between grey (0) and full colour (1).
List<double> _saturation(double s) {
  const r = .2126, g = .7152, b = .0722;
  final i = 1 - s;
  return [
    i * r + s, i * g, i * b, 0, 0, //
    i * r, i * g + s, i * b, 0, 0,
    i * r, i * g, i * b + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
