import 'package:flutter/material.dart';
import '../story/play_scene.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

class AvatarCreator extends StatefulWidget {
  const AvatarCreator({super.key});
  @override
  State<AvatarCreator> createState() => _AvatarCreatorState();
}

class _AvatarCreatorState extends State<AvatarCreator> {
  late Avatar a;
  final name = TextEditingController();
  @override
  void initState() {
    super.initState();
    final st = context.read<AppState>();
    a = Avatar(hair: st.avatar.hair, outfit: st.avatar.outfit, companion: st.avatar.companion);
    name.text = st.explorerName.isEmpty ? st.childName : st.explorerName;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Widget _opt(Widget child, bool sel, VoidCallback f) => GestureDetector(
        onTap: () => setState(f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 76,
          height: 76,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: sel ? C.orange : Colors.black12, width: sel ? 5 : 2.5), boxShadow: sel ? [softShadow(C.orange.withValues(alpha: .4), 12, 4)] : null),
          child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Center(child: child)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final st = context.read<AppState>();
    return AdventureBackground(
      scene: Scene.day,
      calm: true,
      child: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 820;
          final preview = Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            Text('Create Your Explorer!', style: ts(wide ? 40 : 30, color: Colors.white, w: FontWeight.w900).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 10)])),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              AvatarView(hair: a.hair, outfit: a.outfit, height: wide ? 300 : 210),
              const SizedBox(width: 6),
              Companion(type: a.companion, size: wide ? 130 : 96),
            ]),
            Container(width: wide ? 280 : 220, height: 18, decoration: BoxDecoration(color: const Color(0xFFB88A5E), borderRadius: BorderRadius.circular(20), boxShadow: [softShadow()])),
          ]);
          final panel = Panel(
            color: Colors.white.withValues(alpha: .96),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hairstyle', style: ts(18)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < 4; i++) _opt(ClipRect(child: Align(alignment: Alignment.topCenter, heightFactor: .45, child: AvatarView(hair: i, outfit: a.outfit, height: 110))), a.hair == i, () => a.hair = i),
              ]),
              const SizedBox(height: 12),
              Text('Outfit', style: ts(18)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < 4; i++)
                  _opt(Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AvatarPainter.outfitMain[i], AvatarPainter.outfitShirt[i]], stops: const [.5, .5], begin: Alignment.centerLeft, end: Alignment.centerRight))), a.outfit == i, () => a.outfit = i),
              ]),
              const SizedBox(height: 12),
              Text('Companion', style: ts(18)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < 3; i++) _opt(SizedBox(width: 58, height: 58, child: CustomPaint(painter: CreaturePainter(i))), a.companion == i, () => a.companion = i),
              ]),
              const SizedBox(height: 12),
              Text('Choose a name for your explorer', style: ts(16, color: C.inkSoft)),
              const SizedBox(height: 6),
              TextField(controller: name, style: ts(22), decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF4F1FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16))),
              const SizedBox(height: 16),
              Center(child: BigButton(label: 'Start My Adventure!', icon: Icons.rocket_launch_rounded, style: BtnStyle.go, width: 320, onTap: () {
                st.saveAvatar(a, name.text);
                if (st.seenScenes.contains('prologue')) {
                  st.go(AppScreen.intro);
                } else {
                  playScene(context, 'prologue').then((_) => st.go(AppScreen.intro));
                }
              })),
            ]),
          );
          if (wide) {
            return Row(children: [
              Expanded(child: Center(child: preview)),
              SizedBox(width: 440, child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: panel))),
            ]);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(children: [preview, const SizedBox(height: 14), panel, const SizedBox(height: Brand.name.length * 0.0 + 10)]),
          );
        }),
      ),
    );
  }
}
