import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/audio.dart';
import '../core/frame_stats.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../engine/campaign.dart';
import '../engine/levels.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../story/cutscene.dart';
import 'game_screen.dart';
import 'storm_trial.dart';

/// Developer-only test bench (opened by long-pressing the Grown-up Dashboard title).
/// Plays any game at any step WITHOUT changing the child's progress, levels or the retest gate.
class DevPanel extends StatefulWidget {
  final List<Widget> extra; // cutscene launchers etc. added by later phases
  const DevPanel({super.key, this.extra = const []});
  @override
  State<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<DevPanel> {
  int level = 1;

  static const _games = [
    (GameId.soundOrchestra, IslandId.forest, Skill.phonological),
    (GameId.letterArcher, IslandId.valley, Skill.gpc),
    (GameId.wordRocket, IslandId.ocean, Skill.decoding),
    (GameId.wordDetective, IslandId.village, Skill.wordRecognition),
    (GameId.spellingHive, IslandId.treasure, Skill.spelling),
    (GameId.storyQuest, IslandId.castle, Skill.comprehension),
    (GameId.soundNinja, IslandId.forest, Skill.phonological),
    (GameId.soundPortal, IslandId.valley, Skill.gpc),
    (GameId.wordBuilder, IslandId.ocean, Skill.decoding),
    (GameId.wordFlash, IslandId.village, Skill.wordRecognition),
    (GameId.magicWriter, IslandId.treasure, Skill.spelling),
  ];

  Future<void> _play(GameId g, IslandId i, List<Skill> skills) async {
    FrameStats.begin();
    final q = Quest(i, g == GameId.starObservatory ? QuestKind.observatory : QuestKind.standard, 'Dev test · ${levelsOf(g).names[level - 1]}', skills, 6, g, level - 1);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreen(quest: q, devStep: levelStep(g, level))));
    final s = FrameStats.end(Skills.game(g).name);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s), duration: const Duration(seconds: 8)));
  }

  void _trial(int? autoScore) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StormTrialScreen(dev: true, devAutoScore: autoScore)));

  @override
  Widget build(BuildContext context) {
    final sfxCount = ['correct_1', 'miss_soft', 'power_up', 'reward_fanfare', 'tile_snap'].where((id) => ReadleAssets.instance.bundled('assets/sfx/$id.ogg')).length;
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F3B),
      appBar: AppBar(title: const Text('Developer test bench'), backgroundColor: const Color(0xFF262A66), foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Nothing here changes the child’s progress, levels or check-in gate.', style: ts(13, color: Colors.white70, w: FontWeight.w500)),
        const SizedBox(height: 12),
        Text('Level: $level of $levelsPerGame', style: ts(18, color: Colors.white)),
        Slider(value: level.toDouble(), min: 1, max: 4, divisions: 3, label: '$level', onChanged: (v) => setState(() => level = v.round())),
        for (final (g, i, s) in _games)
          Card(
            child: ListTile(
              leading: Text(Skills.game(g).emoji, style: const TextStyle(fontSize: 28)),
              title: Text(Skills.game(g).name),
              subtitle: Text('${Campaign.islandName(i)} · ${levelsOf(g).concept} · L$level: ${levelsOf(g).names[level - 1]}'),
              trailing: const Icon(Icons.play_arrow_rounded),
              onTap: () => _play(g, i, [s]),
            ),
          ),
        Text('Storm Trial (7th island · nothing is saved)', style: ts(16, color: Colors.white, w: FontWeight.w600)),
        Card(
          child: ListTile(
            leading: const Text('⚡', style: TextStyle(fontSize: 28)),
            title: const Text('Storm Trial (play for real)'),
            subtitle: Text('$trialQuestions questions · pass $trialPassMark'),
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: () => _trial(null),
          ),
        ),
        Wrap(spacing: 8, children: [
          ActionChip(label: const Text('Auto-play: score 21 (pass)'), onPressed: () => _trial(trialPassMark)),
          ActionChip(label: const Text('Auto-play: score 20 (retry)'), onPressed: () => _trial(trialPassMark - 1)),
          ActionChip(label: const Text('Auto-play: score 12'), onPressed: () => _trial(12)),
        ]),
        const SizedBox(height: 16),
        Text('Story scenes (does not mark them as seen)', style: ts(16, color: Colors.white, w: FontWeight.w600)),
        Wrap(spacing: 8, children: [
          for (final id in const [
            'prologue', 'island_start_forest', 'rescue_forest', 'island_start_village', 'rescue_village', 'island_start_valley', 'rescue_valley', 'island_start_ocean', 'rescue_ocean',
            'island_start_treasure', 'rescue_treasure', 'island_start_castle', 'rescue_castle', 'trial_warning', 'trial_retry', 'finale', 'star_bridge', 'season_opener',
          ])
            ActionChip(label: Text(id), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CutsceneScreen(sceneId: id, canSkip: true)))),
        ]),
        const SizedBox(height: 16),
        ...widget.extra,
        const SizedBox(height: 16),
        Text('Assets: sound effects ${sfxCount == 5 ? 'OK' : 'missing ($sfxCount/5)'} · voice files: ${AudioManager.instance.hasVoice('g_ready') ? 'generated' : 'placeholder TTS'}', style: ts(13, color: Colors.white70, w: FontWeight.w500)),
        const SizedBox(height: 8),
        BigButton(label: 'Test sounds', style: BtnStyle.soft, height: 48, fontSize: 15, onTap: () async {
          for (final id in ['ui_tap', 'correct_1', 'power_up', 'star_1', 'reward_fanfare']) {
            await AudioManager.instance.sfx(id);
            await Future.delayed(const Duration(milliseconds: 600));
          }
        }),
      ]),
    );
  }
}
