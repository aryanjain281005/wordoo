import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/tts.dart';
import '../data/lang.dart';
import '../data/skills.dart';
import '../data/strings.dart';
import '../engine/campaign.dart';
import '../engine/item_gen.dart';
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

/// Plays one quest: short explanation → demonstration → items → reward. Every answer immediately
/// updates that skill's learner model, so the next item already uses the new difficulty.
class GameScreen extends StatefulWidget {
  final Quest quest;
  const GameScreen({super.key, required this.quest});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  _Phase phase = _Phase.intro;
  late final Quest quest = widget.quest;
  late final GameMeta meta = Skills.game(quest.game);
  late final AppState st = context.read<AppState>();
  late final LangPack pack = st.pack;
  late final ItemGen gen = ItemGen(st.content, seen: st.itemSeen);
  late final Map<Skill, int> startSteps = {for (final s in quest.skills.toSet()) s: st.model(s).step};
  final List<ItemResult> results = [];
  Item? item;
  Item? demoItem;
  bool scaffold = false;
  int index = 0;
  late String msg;
  bool happy = true;
  String? banner;
  late final DateTime startedAt;

  Skill get skillNow => quest.skills[index % quest.skills.length];

  @override
  void initState() {
    super.initState();
    final s0 = quest.skills.first;
    demoItem = ItemGen(st.content, seen: Map.of(st.itemSeen)).make(s0, (st.model(s0).step - 1).clamp(1, 10));
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
    final m = st.model(skillNow);
    item = gen.make(skillNow, m.step, focus: m.focusErrors);
    scaffold = m.needsScaffold || quest.kind == QuestKind.support;
  }

  void _onFeedback(String m, bool good) => setState(() {
        msg = m;
        happy = good;
      });

  void _onDone(ItemResult r) {
    final it = item!;
    final before = st.model(it.skill).step;
    results.add(r);
    st.recordItem(it, r);
    final after = st.model(it.skill).step;
    String? ban;
    var nextMsg = Str.t(pack.code, 'ready');
    if (after > before) {
      ban = '${quest.mixed ? Skills.of(it.skill).emoji : meta.emoji} ${Str.t(pack.code, 'powerUp')}';
      nextMsg = Str.t(pack.code, 'stronger');
    } else if (after < before) {
      nextMsg = Str.t(pack.code, 'warmUp');
    }
    index++;
    if (index >= quest.items) {
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
    final out = st.completeQuest(quest, results, seconds, startSteps);
    final band = st.model(quest.skills.first).band;
    await showRewardModal(context, outcome: out, game: quest.game, companion: st.avatar.companion, level: band, quest: quest);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdventureBackground(
        scene: quest.mixed ? Scene.night : sceneFor(quest.skills.first),
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

  Widget _topBar({bool play = false}) {
    final region = Campaign.islandName(quest.island);
    final m = st.model(play ? skillNow : quest.skills.first);
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
                Expanded(child: Text('$region · ${questKindLabel(quest.kind)}', style: ts(14, color: const Color(0xFFFFE17A)))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (quest.mixed) Text('${Skills.of(skillNow).emoji} ', style: const TextStyle(fontSize: 14)),
                    PowerPips(level: m.band),
                  ]),
                ),
              ]),
              Text(quest.title, style: ts(17, color: Colors.white), maxLines: 2),
              if (play) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: GameProgressBar(value: index / quest.items, color: C.gold, height: 14)),
                  const SizedBox(width: 8),
                  const Text('⭐', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 3),
                  Text('$index/${quest.items}', style: ts(15, color: Colors.white)),
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
                      child: ItemView(key: const ValueKey('demo'), item: demoItem!, skin: skinFor(demoItem!.skill), pack: pack, demo: true, autoSpeak: true, onDone: (_) {}, onFeedback: (_, __) {}),
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
                      skin: skinFor(item!.skill),
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
