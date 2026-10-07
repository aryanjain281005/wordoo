import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/strings.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import 'parent_gate.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final returning = st.hasBaseline;
    return AdventureBackground(
      scene: Scene.day,
      child: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final compact = c.maxHeight < 640;
          return Column(children: [
            const Spacer(flex: 2),
            Pop(child: _Logo(size: compact ? 64 : 88)),
            const SizedBox(height: 6),
            Pop(index: 1, child: Text(Brand.tagline, textAlign: TextAlign.center, style: ts(compact ? 20 : 24, color: Colors.white).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 8)]))),
            const Spacer(),
            Pop(
              index: 2,
              child: SizedBox(
                height: compact ? 150 : 210,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  AvatarView(hair: st.avatar.hair, outfit: st.avatar.outfit, height: compact ? 140 : 200),
                  const SizedBox(width: 10),
                  Companion(type: st.avatar.companion, size: compact ? 100 : 140),
                ]),
              ),
            ),
            const Spacer(),
            Pop(
              index: 3,
              child: BigButton(
                label: returning ? 'Continue Adventure' : 'Start Your Adventure',
                icon: Icons.auto_awesome_rounded,
                style: BtnStyle.go,
                width: 380,
                height: 72,
                fontSize: 24,
                onTap: () => st.go(returning ? AppScreen.home : AppScreen.parent),
              ),
            ),
            const SizedBox(height: 10),
            Text('Turn reading into an adventure!', style: ts(16, color: Colors.white, w: FontWeight.w600)),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () async {
                if (!returning) {
                  st.go(AppScreen.parent);
                } else if (await askParentGate(context)) {
                  st.go(AppScreen.dashboard);
                }
              },
              child: Text('Parent / Grown-Up', style: ts(15, color: Colors.white70, w: FontWeight.w600).copyWith(decoration: TextDecoration.underline, decorationColor: Colors.white54)),
            ),
            const SizedBox(height: 8),
          ]);
        }),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});
  static const _cols = [Color(0xFFFFC83D), Color(0xFFFF9A2E), Color(0xFFFF6FA5), Color(0xFF58B7FF), Color(0xFF34B36B), Color(0xFFFFC83D)];
  @override
  Widget build(BuildContext context) {
    final letters = Brand.name.split('');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < letters.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i.isEven ? 0 : size * .08),
          child: Stack(children: [
            Text(letters[i], style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * .16
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF3B2A8F))),
            Text(letters[i], style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: _cols[i % _cols.length])),
          ]),
        ),
    ]);
  }
}
