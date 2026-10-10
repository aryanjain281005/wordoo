import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/assets.dart';
import '../core/theme.dart';
import '../data/skills.dart';
import '../engine/meta.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

/// The Explorer's Room: everything the child has earned, living together in one cosy room —
/// lanterns at the window, books on the shelf, sea creatures in the aquarium, hive bees buzzing,
/// band stickers on the wall and the Story Tree flower pot that blooms for every day played.
class ExplorerRoomScreen extends StatefulWidget {
  const ExplorerRoomScreen({super.key});
  @override
  State<ExplorerRoomScreen> createState() => _ExplorerRoomScreenState();
}

class _ExplorerRoomScreenState extends State<ExplorerRoomScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  List<String> _items(AppState st, String id) {
    final c = collections.firstWhere((c) => c.id == id);
    return [for (final i in c.unlockedAt(st.collectionCount(id))) i.emoji];
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final streak = st.streak;
    final hat = st.avatar.hat >= 0 ? Collectibles.all[st.avatar.hat].emoji : null;
    final room = st.unlocked.where((c) => c.kind == 'room' || c.kind == 'gear' || c.kind == 'friend').map((c) => c.emoji).toList();
    final books = _items(st, 'library'), sea = _items(st, 'sea'), band = _items(st, 'band'), lanterns = _items(st, 'lanterns');
    final bees = min(st.hiveBees, 14);
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A4A),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(children: [
              RoundIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.pop(context)),
              const SizedBox(width: 12),
              Expanded(child: Text('${st.explorerName.isEmpty ? 'My' : '${st.explorerName}’s'} Room', style: ts(26, color: Colors.white))),
              Text('🌸 ${streak.flowers}', style: ts(20, color: Colors.white)),
            ]),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth, h = box.maxHeight;
              final floorY = h * .68;
              return Stack(children: [
                // walls and floor (painted art replaces this when bg.room exists)
                Positioned.fill(child: ArtImage('bg.room', fit: BoxFit.cover, fallback: CustomPaint(painter: _RoomPainter(floorY)))),
                // window with the festival lanterns the child lit
                Positioned(left: w * .08, top: h * .05, width: w * .42, height: h * .27, child: _window(lanterns)),
                // band stickers on the wall
                Positioned(left: w * .56, top: h * .06, width: w * .38, child: _board('Band stickers', band, const Color(0xFFFFE9A8))),
                // bookshelf
                Positioned(left: w * .56, top: h * .30, width: w * .38, child: _shelf(books)),
                // aquarium
                Positioned(left: w * .06, top: h * .37, width: w * .44, height: h * .25, child: _aquarium(sea)),
                // Story Tree flower pot (cosy streak)
                Positioned(right: w * .04, top: floorY - h * .2, width: w * .3, height: h * .22, child: _flowerPot(streak)),
                // room treasures on the floor
                Positioned(
                  left: w * .05,
                  right: w * .38,
                  top: floorY + h * .02,
                  child: Wrap(spacing: 8, children: [for (final e in room.take(6)) Text(e, style: const TextStyle(fontSize: 34))]),
                ),
                // the explorer and companion
                Positioned(
                  left: w * .3,
                  bottom: h * .02,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    AvatarView(hair: st.avatar.hair, outfit: st.avatar.outfit, hatEmoji: hat, height: h * .26),
                    Companion(type: st.avatar.companion, size: h * .13),
                  ]),
                ),
                // hive bees buzzing around
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _t,
                      builder: (_, _) => Stack(children: [
                        for (var i = 0; i < bees; i++) _bee(i, w, h),
                      ]),
                    ),
                  ),
                ),
                if (books.isEmpty && sea.isEmpty && band.isEmpty && lanterns.isEmpty && bees == 0)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: h * .32,
                    child: Panel(child: Text('Play the island games and your room fills up with everything you earn!', textAlign: TextAlign.center, style: ts(17, color: C.inkSoft))),
                  ),
              ]);
            }),
          ),
        ]),
      ),
    );
  }

  Widget _bee(int i, double w, double h) {
    final r = Random(i * 17 + 3);
    final speed = .6 + r.nextDouble() * .8;
    final a = (_t.value * speed + r.nextDouble()) * 2 * pi;
    final cx = w * (.2 + r.nextDouble() * .6), cy = h * (.15 + r.nextDouble() * .5);
    final x = cx + cos(a) * w * .15, y = cy + sin(a * 2) * h * .05;
    return Positioned(left: x, top: y, child: Transform.flip(flipX: cos(a) < 0, child: const Text('🐝', style: TextStyle(fontSize: 20))));
  }

  Widget _window(List<String> lanterns) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B1F4B), Color(0xFF5A3F86)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5A2B), width: 6),
        ),
        child: Stack(children: [
          const Positioned(right: 10, top: 8, child: Text('🌙', style: TextStyle(fontSize: 22))),
          Center(child: Container(width: 5, color: const Color(0xFF8B5A2B))),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: [
                for (final l in lanterns) Text(l, style: const TextStyle(fontSize: 16)),
                if (lanterns.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xCC1B1F4B), borderRadius: BorderRadius.circular(8)),
                    child: Text('🏮 Light lanterns in Letter Archer', textAlign: TextAlign.center, style: ts(12, color: Colors.white70, w: FontWeight.w500)),
                  ),
              ]),
            ),
          ),
        ]),
      );

  Widget _board(String title, List<String> items, Color bg) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 6, offset: Offset(0, 3))]),
        child: Column(children: [
          Text(title, style: ts(12, color: C.inkSoft)),
          Wrap(alignment: WrapAlignment.center, spacing: 2, children: [
            for (final b in items) Text(b, style: const TextStyle(fontSize: 18)),
            if (items.isEmpty) Text('—', style: ts(14, color: C.inkSoft)),
          ]),
        ]),
      );

  Widget _shelf(List<String> books) => Column(children: [
        SizedBox(
          height: 46,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final b in books.take(8)) Text(b, style: const TextStyle(fontSize: 22)),
            if (books.isEmpty) Expanded(child: Text('Story Library books go here', maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(11, color: Colors.white70, w: FontWeight.w500))),
          ]),
        ),
        Container(height: 10, decoration: BoxDecoration(color: const Color(0xFF8B5A2B), borderRadius: BorderRadius.circular(4))),
      ]);

  Widget _aquarium(List<String> sea) => AnimatedBuilder(
        animation: _t,
        builder: (_, _) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xAA9BE7F7), Color(0xCC1E9CC4)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: LayoutBuilder(builder: (_, b) {
            return Stack(children: [
              for (var i = 0; i < sea.length; i++)
                Positioned(
                  left: (b.maxWidth - 30) * ((sin(_t.value * 2 * pi * (.5 + i * .13) + i) + 1) / 2),
                  top: (b.maxHeight - 34) * ((i * .37) % 1),
                  child: Text(sea[i], style: const TextStyle(fontSize: 22)),
                ),
              if (sea.isEmpty) Center(child: Text('Sea Log creatures swim here', textAlign: TextAlign.center, style: ts(12, color: Colors.white, w: FontWeight.w500))),
              const Positioned(left: 4, bottom: 2, child: Text('🐚', style: TextStyle(fontSize: 18))),
            ]);
          }),
        ),
      );

  Widget _flowerPot(CozyStreak s) {
    final shown = min(s.flowers, 12);
    return Column(children: [
      Expanded(
        child: Stack(alignment: Alignment.bottomCenter, children: [
          // a little Story Tree sapling that blooms one flower per day played
          Positioned(bottom: 0, child: Container(width: 8, height: 70, color: const Color(0xFF6B3E1E))),
          Positioned(bottom: 50, child: Container(width: 86, height: 70, decoration: const BoxDecoration(color: Color(0xFF5DBB63), shape: BoxShape.circle))),
          for (var i = 0; i < shown; i++)
            Positioned(
              bottom: 60 + sin(i * 2.4) * 22,
              left: null,
              child: Transform.translate(offset: Offset(cos(i * 2.4) * 30, 0), child: const Text('🌸', style: TextStyle(fontSize: 14))),
            ),
        ]),
      ),
      Container(
        width: 70,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFD9744A), borderRadius: BorderRadius.circular(8)),
        child: Text(s.run > 1 ? '${s.run} days' : 'Day ${s.flowers}', style: ts(11, color: Colors.white)),
      ),
      if (s.rainDayUsed) Text('🌧️ rain day saved it', style: ts(10, color: Colors.white70, w: FontWeight.w500)),
    ]);
  }
}

class _RoomPainter extends CustomPainter {
  final double floorY;
  _RoomPainter(this.floorY);
  @override
  void paint(Canvas canvas, Size size) {
    final wall = Rect.fromLTWH(0, 0, size.width, floorY);
    canvas.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7D9B5), Color(0xFFEFC59A)]).createShader(wall));
    // rangoli-dot wallpaper
    final dot = Paint()..color = const Color(0x22B0465A);
    for (var y = 20.0; y < floorY; y += 34) {
      for (var x = (y ~/ 34).isEven ? 14.0 : 31.0; x < size.width; x += 34) {
        canvas.drawCircle(Offset(x, y), 3, dot);
      }
    }
    final floor = Rect.fromLTWH(0, floorY, size.width, size.height - floorY);
    canvas.drawRect(floor, Paint()..color = const Color(0xFFB07A4F));
    final plank = Paint()
      ..color = const Color(0x338B5A2B)
      ..strokeWidth = 2;
    for (var y = floorY + 22; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), plank);
    }
    // rug
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .5, floorY + (size.height - floorY) * .62), width: size.width * .8, height: (size.height - floorY) * .5), Paint()..color = const Color(0xFFE0568A));
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .5, floorY + (size.height - floorY) * .62), width: size.width * .6, height: (size.height - floorY) * .32), Paint()..color = const Color(0xFFFFC93C));
    canvas.drawRect(Rect.fromLTWH(0, floorY - 6, size.width, 8), Paint()..color = const Color(0xFF8B5A2B));
  }

  @override
  bool shouldRepaint(_RoomPainter o) => o.floorY != floorY;
}

/// Small card used on the map / journal to show the cosy streak.
class StreakChip extends StatelessWidget {
  final CozyStreak streak;
  const StreakChip(this.streak, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(18)),
        child: Text('🌸 ${streak.flowers} ${streak.flowers == 1 ? 'flower' : 'flowers'} on the Story Tree${streak.run > 1 ? ' · ${streak.run}-day run' : ''}', style: ts(14, color: C.ink)),
      );
}

/// Whether painted room art exists (used by tests / dev panel).
bool hasRoomArt() => WordooAssets.instance.art('bg.room') != null;
