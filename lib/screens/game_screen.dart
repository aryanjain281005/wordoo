import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../core/tts.dart';
import '../data/lang.dart';
import '../data/skills.dart';
import '../data/strings.dart';
import '../engine/item_factory.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/item_views.dart';
import '../widgets/reward_modal.dart';

Scene sceneFor(Skill s) => switch (s) {
      Skill.phonological => Scene.forest,
      Skill.gpc => Scene.day,
      Skill.decoding => Scene.night,
      Skill.wordRecognition => Scene.ocean,
      Skill.spelling => Scene.treasure,
      Skill.comprehension => Scene.castle,
    };

enum _Phase { intro, play }

/// Every game follows: short explanation → demonstration → gameplay → feedback → reward → back to the map.
class GameScreen extends StatefulWidget {
  final GameId game;
  final int? levelOverride;
  const GameScreen({super.key, required this.game, this.levelOverride});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  _Phase phase = _Phase.intro;
  late final GameMeta meta = Skills.game(widget.game);
  late final AppState st = context.read<AppState>();
  late final LangPack pack = st.pack;
  late final ItemFactory factory = ItemFactory(pack);
  late int level;
  late int startLevel;
  late bool scaffold;
  final List<ItemResult> results = [];
  final Set<String> used = {};
  Item? item;
  Item? demoItem;
  int index = 0;
  int streak = 0, misses = 0;
  late String msg;
  bool happy = true;
  String? banner;
  late final DateTime startedAt;

  @override
  void initState() {
    super.initState();
    final ss = st.skills[meta.skill]!;
    level = widget.levelOverride ?? ss.level;
    startLevel = level;
    scaffold = ss.scaffold;
    demoItem = factory.make(meta.skill, level.clamp(1, 2), {Pool.p});
    msg = Str.t(pack.code, 'tryDemo');
    startedAt = DateTime.now();
  }

  @override
  void dispose() {
    Speaker.instance.stop();
    super.dispose();
  }

  void _start() {
    Speaker.instance.stop();
    setState(() {
      phase = _Phase.play;
      msg = Str.t(pack.code, 'yourTurn');
      _nextItem();
    });
  }

  void _nextItem() {
    final it = factory.make(meta.skill, level, {Pool.p}, used: used);
    used.add(it.id);
    item = it;
  }

  void _onFeedback(String m, bool good) => setState(() {
        msg = m;
        happy = good;
      });

  void _onDone(ItemResult r) {
    results.add(r);
    String? ban;
    if (r.correct) {
      streak++;
      misses = 0;
    } else {
      misses++;
      streak = 0;
    }
    var nextMsg = Str.t(pack.code, 'ready');
    if (streak >= Cfg.streakToLevelUp && level < Cfg.maxLevel) {
      level++;
      streak = 0;
      scaffold = false;
      ban = '${meta.emoji} ${Str.t(pack.code, 'powerUp')}';
      nextMsg = Str.t(pack.code, 'stronger');
    } else if (misses >= Cfg.missesToLevelDown) {
      if (level > Cfg.minLevel) level--;
      misses = 0;
      scaffold = true;
      nextMsg = Str.t(pack.code, 'warmUp');
    }
    index++;
    if (index >= Cfg.itemsPerRound) {
      _finish();
      return;
    }
    setState(() {
      banner = ban;
      msg = nextMsg;
      happy = true;
      _nextItem();
    });
    if (ban != null) {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => banner = null);
      });
    }
  }

  Future<void> _finish() async {
    final seconds = DateTime.now().difference(startedAt).inSeconds.toDouble();
    final out = st.recordGame(widget.game, results, seconds, endLevel: level);
    final newLevel = st.skills[meta.skill]!.level;
    await showRewardModal(context, outcome: out, game: widget.game, companion: st.avatar.companion, level: newLevel);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdventureBackground(
        scene: sceneFor(meta.skill),
        calm: true,
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: phase == _Phase.intro ? _intro() : _play(),
          ),
        ),
      ),
    );
  }

  static const _missions = {
    GameId.soundOrchestra: 'Wake the Forest Band!',
    GameId.letterArcher: 'Hit the Letter Targets!',
    GameId.wordRocket: 'Launch the Word Rocket!',
    GameId.wordDetective: 'Catch the Right Word!',
    GameId.spellingHive: 'Fix the Pirate Map!',
    GameId.storyQuest: 'Read the Magic Scroll!',
  };

  Widget _topBar({bool play = false}) {
    final st2 = context.read<AppState>();
    final mi = st2.missions.indexWhere((m) => m.game == widget.game);
    final region = Skills.of(meta.skill).region;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RoundIconButton(icon: Icons.close_rounded, label: 'Back to the map', onTap: () => Navigator.of(context).pop(), size: 48),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 12, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B3F8F), Color(0xFF262A66)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8C46A), width: 2.5),
              boxShadow: [softShadow(const Color(0x55000000), 10, 5)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(region, style: ts(14, color: const Color(0xFFFFE17A)))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(10)),
                  child: PowerPips(level: level),
                ),
              ]),
              Text(mi >= 0 ? 'Mission ${mi + 1}: ${_missions[widget.game] ?? meta.tagline}' : (_missions[widget.game] ?? meta.tagline), style: ts(17, color: Colors.white), maxLines: 2),
              if (play) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: GameProgressBar(value: index / Cfg.itemsPerRound, color: C.gold, height: 14)),
                  const SizedBox(width: 8),
                  const Text('⭐', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 3),
                  Text('$index/${Cfg.itemsPerRound}', style: ts(15, color: Colors.white)),
                ]),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _intro() {
    return Column(key: const ValueKey('intro'), children: [
      _topBar(),
      Expanded(
        child: LayoutBuilder(builder: (_, c) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(children: [
                  Text('${meta.emoji}  ${meta.name}', textAlign: TextAlign.center, style: ts(36, color: Colors.white).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 8)])),
                  const SizedBox(height: 4),
                  Text(meta.tagline, style: ts(20, color: Colors.white, w: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Container(
                    height: 400,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: .22), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white54, width: 2)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: ItemView(key: const ValueKey('demo'), item: demoItem!, skin: skinFor(meta.skill), pack: pack, demo: true, autoSpeak: true, onDone: (_) {}, onFeedback: (_, __) {}),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Companion(type: st.avatar.companion, size: 90, message: '$msg  ${meta.how}', speakLocale: null),
                  const SizedBox(height: 14),
                  BigButton(label: Str.t(pack.code, 'letsGo'), icon: Icons.play_arrow_rounded, style: BtnStyle.go, width: 260, onTap: _start),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          );
        }),
      ),
    ]);
  }

  Widget _play() {
    return Column(key: const ValueKey('play'), children: [
      _topBar(play: true),
      Expanded(
        child: Stack(children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 96),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(.08, 0), end: Offset.zero).animate(a), child: c)),
                    child: ItemView(
                      key: ValueKey('${item!.id}-$index'),
                      item: item!,
                      skin: skinFor(meta.skill),
                      pack: pack,
                      scaffold: scaffold,
                      onFeedback: _onFeedback,
                      onDone: _onDone,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 4,
            child: Align(alignment: Alignment.bottomLeft, child: Companion(type: st.avatar.companion, size: 84, message: msg, happy: happy)),
          ),
          if (banner != null)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(30), boxShadow: [softShadow()]),
                    child: Text(banner!, style: ts(24, color: C.ink)),
                  ),
                ),
              ),
            ),
        ]),
      ),
    ]);
  }
}
