import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../engine/campaign.dart';
import '../engine/meta.dart';
import 'explorer_room.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

/// "Customize & Collect": treasures, badges, hat equip and a little room.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final hat = st.avatar.hat >= 0 ? Collectibles.all[st.avatar.hat].emoji : null;
    final rooms = st.unlocked.where((c) => c.kind == 'room' || c.kind == 'gear' || c.kind == 'friend').toList();
    return Scaffold(
      body: AdventureBackground(
        scene: Scene.castle,
        calm: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                RoundIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(child: Text('Customize & Collect', style: ts(28, color: Colors.white))),
                StarChip(st.stars),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(children: [
                      Panel(
                        child: Row(children: [
                          AvatarView(hair: st.avatar.hair, outfit: st.avatar.outfit, hatEmoji: hat, height: 170),
                          const SizedBox(width: 12),
                          Companion(type: st.avatar.companion, size: 100),
                          const Spacer(),
                          Flexible(child: Text('Collect stars to find treasures!', style: ts(18, color: C.inkSoft), textAlign: TextAlign.center)),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Panel(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Treasures', style: ts(22)),
                          const SizedBox(height: 10),
                          Wrap(spacing: 10, runSpacing: 10, children: [
                            for (final c in Collectibles.all) _treasure(context, st, c),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Panel(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Badges', style: ts(22)),
                          const SizedBox(height: 10),
                          st.badges.where((b) => b != 'sky-seen').isEmpty
                              ? Text('Play a game to earn your first badge!', style: ts(16, color: C.inkSoft))
                              : Wrap(spacing: 8, runSpacing: 8, children: [for (final b in _badgeDefs.where((d) => st.badges.contains(d.id))) bandPill('${b.emoji} ${b.name}', C.purple, size: 16)]),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      _gemsPanel(st),
                      const SizedBox(height: 14),
                      for (final c in collections) ...[_collectionPanel(st, c), const SizedBox(height: 14)],
                      if (st.gifts.isNotEmpty) ...[
                        Panel(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Gifts from Milo', style: ts(22)),
                            Text('For trying hard, even when it was tricky', style: ts(14, color: C.inkSoft, w: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              for (final g in st.gifts) Text(effortGifts.firstWhere((e) => e.$2 == g, orElse: () => ('🎁', g)).$1, style: const TextStyle(fontSize: 34)),
                            ]),
                          ]),
                        ),
                        const SizedBox(height: 14),
                      ],
                      BigButton(
                        label: 'Visit my room',
                        icon: Icons.house_rounded,
                        style: BtnStyle.go,
                        height: 56,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExplorerRoomScreen())),
                      ),
                      if (rooms.isEmpty) const SizedBox.shrink(),
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

  Widget _gemsPanel(AppState st) {
    final season = st.campaign.season;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Story Gems', style: ts(22)),
        Text('One for every island chapter you finish, every season', style: ts(14, color: C.inkSoft, w: FontWeight.w500)),
        const SizedBox(height: 8),
        for (var se = 1; se <= season; se++)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              SizedBox(width: 74, child: Text('Season $se', style: ts(14, color: C.inkSoft))),
              for (final i in IslandId.values)
                Expanded(
                  child: Tooltip(
                    message: islandGem[i]!.$2,
                    child: Opacity(
                      opacity: st.gems.contains(gemId(se, i)) ? 1 : .18,
                      child: Text(islandGem[i]!.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
            ]),
          ),
      ]),
    );
  }

  Widget _collectionPanel(AppState st, CollectionDef c) {
    final n = st.collectionCount(c.id);
    final next = c.nextAt(n);
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${c.emoji}  ${c.name}', style: ts(20)),
          const Spacer(),
          Text('${c.unlockedAt(n).length}/${c.items.length}', style: ts(16, color: C.inkSoft)),
        ]),
        Text(next == null ? 'Complete! From ${c.game}.' : 'From ${c.game} · ${next.at - n} more ${c.unit} for the next one', style: ts(14, color: C.inkSoft, w: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final i in c.items)
            Tooltip(
              message: n >= i.at ? i.name : 'At ${i.at} ${c.unit}',
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: n >= i.at ? const Color(0xFFFFF3C4) : const Color(0xFFEDEBF5), borderRadius: BorderRadius.circular(12)),
                child: Text(n >= i.at ? i.emoji : '?', style: TextStyle(fontSize: n >= i.at ? 26 : 18, color: n >= i.at ? null : Colors.black26, fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
      ]),
    );
  }

  static final _badgeDefs = <BadgeDef>[Badges.first, Badges.day, Badges.week, Badges.levelUp, for (final s in Skills.all) Badges.forSkill(s)];

  Widget _treasure(BuildContext context, AppState st, Collectible c) {
    final owned = st.stars >= c.stars;
    final idx = Collectibles.all.indexOf(c);
    final equipped = c.kind == 'hat' && st.avatar.hat == idx;
    return GestureDetector(
      onTap: owned && c.kind == 'hat' ? () => st.equipHat(equipped ? -1 : idx) : null,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: owned ? const Color(0xFFFFF3C4) : const Color(0xFFEDEBF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: equipped ? C.green : (owned ? C.gold : Colors.black12), width: equipped ? 4 : 2.5),
        ),
        child: Column(children: [
          Text(owned ? c.emoji : '🔒', style: TextStyle(fontSize: 38, color: owned ? null : Colors.grey)),
          const SizedBox(height: 4),
          Text(owned ? c.name : '${c.stars} ⭐', textAlign: TextAlign.center, style: ts(12, color: C.inkSoft)),
          if (owned && c.kind == 'hat') Text(equipped ? 'Wearing' : 'Tap to wear', style: ts(11, color: equipped ? C.greenDark : C.purple)),
        ]),
      ),
    );
  }
}
