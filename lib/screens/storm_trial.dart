import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/audio.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../engine/item_gen.dart';
import '../engine/levels.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../story/play_scene.dart';
import '../story/puppets.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/item_views.dart';

/// Story v3 · the Storm Trial (7th island). 30 mixed questions, 5 per skill, each at the child's own level.
/// One try per question (no hints). Every right answer drains Gumsum's storm; 21 right breaks it.
///
/// Developer mode (`dev`): nothing is saved. With `devAutoScore` the screen answers by itself (that many right, rest wrong)
/// so the pass and retry paths can be checked on a device in seconds.
class StormTrialScreen extends StatefulWidget {
  final bool dev;
  final int? devAutoScore;
  const StormTrialScreen({super.key, this.dev = false, this.devAutoScore});
  @override
  State<StormTrialScreen> createState() => _StormTrialScreenState();
}

class _StormTrialScreenState extends State<StormTrialScreen> {
  late final AppState st = context.read<AppState>();
  late final List<Item> items = _makeItems();
  final List<ItemResult> results = [];
  int index = 0;
  bool finished = false;
  late final Stopwatch clock = Stopwatch()..start();

  int get right => results.where((r) => r.correct).length;

  List<Item> _makeItems() {
    final gen = ItemGen(st.content, rng: Random(), seen: st.itemSeen);
    final out = <Item>[
      for (final s in Skill.values)
        for (var k = 0; k < trialPerSkill; k++) gen.make(s, st.model(s).step),
    ];
    out.shuffle();
    return out;
  }

  @override
  void initState() {
    super.initState();
    AudioManager.instance.music('music.boss');
    final auto = widget.devAutoScore;
    if (auto != null) WidgetsBinding.instance.addPostFrameCallback((_) => _autoPlay(auto));
  }

  Future<void> _autoPlay(int target) async {
    for (var k = 0; k < items.length && mounted && !finished; k++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      _onDone(ItemResult(itemId: items[k].id, skill: items[k].skill, level: st.model(items[k].skill).step, correct: k < target, ms: 1000));
    }
  }

  @override
  void dispose() {
    AudioManager.instance.music('music.aksharpur');
    super.dispose();
  }

  void _onDone(ItemResult r) {
    results.add(r);
    if (index + 1 >= items.length) {
      _finish();
      return;
    }
    setState(() => index++);
  }

  Future<void> _finish() async {
    setState(() => finished = true);
    final passed = widget.dev ? right >= trialPassMark : st.completeTrial(items, results, clock.elapsed.inSeconds.toDouble());
    await playScene(context, passed ? 'finale' : 'trial_retry');
    if (!mounted) return;
    if (passed) {
      Navigator.of(context).pop();
    } else {
      setState(() {}); // show the result card with the skills to practise
    }
  }

  /// The two skills with the fewest right answers in this attempt.
  List<Skill> _weakest() {
    final score = {for (final s in Skill.values) s: 0};
    for (var k = 0; k < results.length; k++) {
      if (results[k].correct) score[items[k].skill] = score[items[k].skill]! + 1;
    }
    final l = Skill.values.toList()..sort((a, b) => score[a]!.compareTo(score[b]!));
    return l.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdventureBackground(
        scene: Scene.night,
        artId: 'bg.citadel',
        calm: true,
        child: SafeArea(
          child: Column(children: [
            _header(),
            Expanded(child: finished ? _result() : _question()),
          ]),
        ),
      ),
    );
  }

  Widget _header() {
    final drained = (right / trialPassMark).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(children: [
        RoundIconButton(icon: Icons.close_rounded, label: 'Leave the trial', size: 44, onTap: () => Navigator.of(context).pop()),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B2F6B), Color(0xFF1E1A3D)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD45C), width: 2),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('⚡ Storm Trial · ${min(index + 1, trialQuestions)} of $trialQuestions', style: ts(15, color: const Color(0xFFFFE17A)))),
                Text('$right / $trialPassMark', style: ts(15, color: Colors.white)),
              ]),
              const SizedBox(height: 6),
              // the lightning meter: fills toward the pass mark
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(children: [
                  Container(height: 14, color: Colors.white12),
                  FractionallySizedBox(
                    widthFactor: drained,
                    child: Container(height: 14, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFE07A), Color(0xFFFF9F1C)]))),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(width: 56, height: 56, child: Puppet(id: 'gumsum', size: 56, mood: right >= trialPassMark ? 'surprised' : 'villain')),
      ]),
    );
  }

  Widget _question() {
    final it = items[index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF1E1A3D).withValues(alpha: .72), borderRadius: BorderRadius.circular(26)),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('${Skills.of(it.skill).emoji}  ${Skills.of(it.skill).region}', style: ts(14, color: Colors.white70)),
          ),
          Expanded(
            child: ItemView(
              key: ValueKey('trial$index'),
              item: it,
              skin: skinFor(it.skill),
              pack: st.pack,
              allowRetry: false, // one try per question in the Trial
              onDone: _onDone,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _result() {
    if (results.length < items.length || right >= trialPassMark) return const Center(child: CircularProgressIndicator());
    final weak = _weakest();
    return Center(
      child: Panel(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$right / $trialQuestions', style: ts(40, color: C.purpleDark)),
          Text(right >= trialPassMark - 6 ? 'You need $trialPassMark to break the storm, so close!' : 'You need $trialPassMark to break the storm. Practise, then try again!', textAlign: TextAlign.center, style: ts(17, color: C.inkSoft)),
          const SizedBox(height: 12),
          Text('Practise with your Keepers, then try again:', style: ts(15, color: C.ink)),
          const SizedBox(height: 6),
          for (final s in weak) Text('${Skills.of(s).emoji}  ${Skills.of(s).region}', style: ts(18, color: C.ink)),
          const SizedBox(height: 14),
          BigButton(label: 'Back to the map', style: BtnStyle.go, width: 300, onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }
}
