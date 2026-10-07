import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'game_screen.dart';

/// "Your First Adventure" — the child sees a broken bridge, not an assessment.
class AdventureIntro extends StatelessWidget {
  const AdventureIntro({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final re = st.hasBaseline;
    final line = Str.t(st.langCode, re ? 'skyBridge' : 'bridge');
    return AdventureBackground(
      scene: re ? Scene.castle : Scene.forest,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Pop(child: Text(re ? 'Your Next Adventure Awaits!' : 'Your First Adventure', textAlign: TextAlign.center, style: ts(38, color: Colors.white, w: FontWeight.w900).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 10)]))),
                const SizedBox(height: 18),
                Pop(index: 1, child: _BridgePicture(broken: true)),
                const SizedBox(height: 14),
                Pop(index: 2, child: Companion(type: st.avatar.companion, size: 130, message: '${Brand.companion} says: $line', speakLocale: st.pack.tts)),
                const SizedBox(height: 22),
                Pop(
                  index: 3,
                  child: BigButton(
                    label: re ? 'Let’s Go!' : 'Let’s Fix It!',
                    icon: Icons.construction_rounded,
                    style: BtnStyle.go,
                    width: 300,
                    onTap: () => st.go(AppScreen.assessment),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: .28), borderRadius: BorderRadius.circular(16)),
                  child: Text('For grown-ups: this adventure includes a short literacy skill assessment (about 5 minutes). It checks six reading and writing skills and is not a diagnosis.',
                      textAlign: TextAlign.center, style: ts(14, color: Colors.white, w: FontWeight.w500)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _BridgePicture extends StatelessWidget {
  final bool broken;
  final double fixed = 0; // 0..1
  const _BridgePicture({required this.broken});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: LayoutBuilder(builder: (_, c) {
        const n = 6;
        final w = c.maxWidth;
        return Stack(alignment: Alignment.center, children: [
          Positioned(left: 0, bottom: 0, child: const Text('🌳⛰️', style: TextStyle(fontSize: 54))),
          Positioned(right: 0, bottom: 0, child: const Text('🌲🌲', style: TextStyle(fontSize: 54))),
          for (var i = 0; i < n; i++)
            if (!(broken && fixed == 0 && (i == 2 || i == 4)))
            Positioned(
              left: 54 + (w - 140) * i / (n - 1),
              bottom: 34 + (i == 2 || i == 4 ? -10 : 0).toDouble() * (1 - (i / n < fixed ? 1 : 0)),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: (i / n < fixed) ? 1 : .85,
                child: Container(
                  width: 34,
                  height: 14,
                  decoration: BoxDecoration(color: const Color(0xFFB77B3C), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF7A4E22), width: 2)),
                ),
              ),
            ),
        ]);
      }),
    );
  }
}

/// Hidden six-skill assessment inside the bridge story. Also used for the fresh-item weekly reassessment.
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});
  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  static const _levels = [1, 2, 3];
  late final AppState st = context.read<AppState>();
  late final LangPack pack = st.pack;
  late final ItemFactory factory = ItemFactory(pack, Random(st.explorerName.hashCode + st.history.length * 7919));
  late final List<Item> items;
  final List<ItemResult> results = [];
  int i = 0;
  bool stationIntro = true;
  bool finished = false;
  String msg = '';
  bool happy = true;

  static const _lines = {
    Skill.phonological: 'Listen closely to the sounds!',
    Skill.gpc: 'Find the letters that match the sounds!',
    Skill.decoding: 'Blend the pieces to read the word!',
    Skill.wordRecognition: 'Spot the right word!',
    Skill.spelling: 'Build the word with tiles!',
    Skill.comprehension: 'Read the tiny story, then answer!',
  };

  @override
  void initState() {
    super.initState();
    final used = <String>{};
    final list = <Item>[];
    for (final s in Skill.values) {
      for (final lv in _levels) {
        final it = factory.make(s, lv, {st.assessForm}, used: used);
        used.add(it.id);
        list.add(it);
      }
    }
    items = list;
    msg = Str.t(pack.code, 'ready');
  }

  Skill get currentSkill => items[i.clamp(0, items.length - 1)].skill;

  void _onDone(ItemResult r) {
    results.add(r);
    i++;
    if (i >= items.length) {
      setState(() => finished = true);
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (!mounted) return;
        if (st.hasBaseline) {
          st.completeReassessment(results);
        } else {
          st.completeBaseline(results);
        }
      });
      return;
    }
    setState(() {
      stationIntro = i % 3 == 0;
      msg = stationIntro ? '' : 'Keep going, Explorer!';
      happy = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skill = currentSkill;
    final meta = Skills.of(skill);
    final progress = finished ? 1.0 : i / items.length;
    return AdventureBackground(
      scene: finished ? Scene.day : sceneFor(skill),
      calm: true,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              Text('🌉', style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(finished ? 'The bridge is fixed!' : (st.hasBaseline ? 'Rebuild the Cloud Bridge' : 'Fix the Bridge'), style: ts(18, color: Colors.white)),
                  const SizedBox(height: 4),
                  GameProgressBar(value: progress, color: C.gold),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: finished
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🌉✨', style: TextStyle(fontSize: 90)),
                      const SizedBox(height: 10),
                      Companion(type: st.avatar.companion, size: 130, message: 'We did it together! The way is open!', speakLocale: pack.tts),
                    ]),
                  )
                : stationIntro
                    ? _stationCard(meta, i ~/ 3 + 1)
                    : Stack(children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 92),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 720),
                                child: ItemView(
                                  key: ValueKey('a$i'),
                                  item: items[i],
                                  skin: skinFor(skill),
                                  pack: pack,
                                  allowRetry: false,
                                  onFeedback: (m, g) => setState(() {
                                    msg = m;
                                    happy = g;
                                  }),
                                  onDone: _onDone,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(left: 8, right: 8, bottom: 4, child: Align(alignment: Alignment.bottomLeft, child: Companion(type: st.avatar.companion, size: 84, message: msg.isEmpty ? null : msg, happy: happy))),
                      ]),
          ),
        ]),
      ),
    );
  }

  Widget _stationCard(SkillMeta meta, int n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Pop(
            key: ValueKey('station$n'),
            child: Panel(
              color: const Color(0xFFFFF9E8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                  child: Text('$n', style: ts(28, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                Text(meta.station, textAlign: TextAlign.center, style: ts(32, color: C.ink)),
                const SizedBox(height: 6),
                Text(meta.emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 6),
                Companion(type: st.avatar.companion, size: 100, message: _lines[meta.skill], speakLocale: null),
                const SizedBox(height: 16),
                BigButton(
                  label: 'Start',
                  icon: Icons.play_arrow_rounded,
                  style: BtnStyle.go,
                  width: 220,
                  onTap: () {
                    Speaker.instance.stop();
                    setState(() => stationIntro = false);
                  },
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
