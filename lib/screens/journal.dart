import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../engine/campaign.dart';
import '../state/app_state.dart';
import '../story/beats.dart';
import '../story/play_scene.dart';
import '../story/puppets.dart';
import '../core/assets.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../engine/meta.dart';
import 'collection.dart';
import 'explorer_room.dart';
import 'library.dart';

/// Explorer's Journal: the story so far, island by island, and story scenes to watch again.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  static const scenes = [
    ('prologue', 'How it began', '🌳'),
    ('star_bridge', 'The Star Bridge', '🌉'),
    ('season_opener', 'A new season', '✨'),
  ];

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final c = st.campaign;
    return Scaffold(
      body: AdventureBackground(
        scene: Scene.night,
        calm: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                RoundIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(child: Text('Explorer’s Journal', style: ts(28, color: Colors.white))),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Panel(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text('Season ${c.season}', style: ts(24)),
                            const Spacer(),
                            Text([for (final i in IslandId.values) if (st.gems.contains(gemId(c.season, i))) islandGem[i]!.$1].join(' '), style: const TextStyle(fontSize: 20)),
                          ]),
                          const SizedBox(height: 4),
                          Text(st.gumsumLightness == 0 ? 'Gumsum is still a little grey cloud. Every season of reading makes him brighter.' : 'Gumsum the cloud is ${(st.gumsumLightness * 100).round()}% brighter than at the start.', style: ts(16, color: C.inkSoft, w: FontWeight.w500)),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      Center(child: StreakChip(st.streak)),
                      const SizedBox(height: 12),
                      for (final i in IslandId.values) ...[
                        _island(st, i),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 8),
                      Text('Watch again', style: ts(22, color: Colors.white)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final (id, title, emoji) in scenes)
                          if (st.seenScenes.contains(id))
                            BigButton(label: '$emoji  $title', style: BtnStyle.soft, height: 50, fontSize: 17, onTap: () => playScene(context, id)),
                        if (scenes.every((s) => !st.seenScenes.contains(s.$1)))
                          Text('Story scenes you watch will appear here.', style: ts(16, color: Colors.white70, w: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 16),
                      BigButton(label: 'Story Library (${st.libraryBooks.length})', icon: Icons.local_library_rounded, style: BtnStyle.primary, height: 52, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LibraryScreen()))),
                      const SizedBox(height: 10),
                      BigButton(label: 'My room', icon: Icons.house_rounded, style: BtnStyle.soft, height: 52, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExplorerRoomScreen()))),
                      const SizedBox(height: 10),
                      BigButton(label: 'My treasures', icon: Icons.backpack_rounded, style: BtnStyle.go, height: 52, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectionScreen()))),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _island(AppState st, IslandId i) {
    final c = st.campaign;
    final s = c.islands[i]!;
    final need = c.nodesNeeded(i);
    final g = storyCast[islandGuardian[i]];
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        SizedBox(
          width: 52,
          height: 52,
          child: ArtImage('char.${islandGuardian[i]}.happy', fallback: Center(child: Text(g?.emoji ?? '🏝️', style: const TextStyle(fontSize: 34)))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Campaign.islandName(i), style: ts(19)),
            Text('${tierName(s.tier)} · ${s.nodes.clamp(0, need)}/$need quests${g != null ? ' · with ${g.name}' : ''}', style: ts(15, color: C.inkSoft, w: FontWeight.w500)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: (s.nodes / need).clamp(0, 1).toDouble(), minHeight: 10, backgroundColor: const Color(0xFFE6E2F5), color: g?.color ?? C.ink),
            ),
          ]),
        ),
      ]),
    );
  }
}
