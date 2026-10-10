import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/strings.dart';
import '../state/app_state.dart';
import '../widgets/ambient.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';
import '../widgets/hero.dart';
import 'parent_gate.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late final AmbientController _sky = AmbientController(this); // balloons, birds, butterflies and tap fireworks

  @override
  void dispose() {
    _sky.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final returning = st.hasBaseline;
    return HeroScene(
      child: Stack(fit: StackFit.expand, children: [
        SkyAmbience(_sky),
        SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final h = c.maxHeight, w = c.maxWidth;
          return Stack(children: [
            // logo + tagline
            Positioned(
              top: h * .04,
              left: 0,
              right: 0,
              child: Column(children: [
                Pop(child: AnimatedBuilder(animation: _sky, builder: (_, child) => Transform.translate(offset: Offset(0, sin(_sky.time * 1.7) * 5), child: child), child: _Logo(size: (w * .78).clamp(200, 420)))),
                const SizedBox(height: 4),
                Pop(index: 1, child: _Ribbon(text: Brand.tagline.replaceAll('Just for You', 'Just for You!'))),
              ]),
            ),
            // characters on the path
            Positioned(
              bottom: h * .24,
              left: 0,
              right: 0,
              child: Pop(
                index: 2,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  AvatarView(hair: st.avatar.hair, outfit: st.avatar.outfit, height: (w * .5).clamp(120, h * .27).toDouble()),
                  SizedBox(width: w * .02),
                  Padding(padding: const EdgeInsets.only(bottom: 4), child: Companion(type: st.avatar.companion, size: (w * .32).clamp(80, h * .17).toDouble())),
                ]),
              ),
            ),
            // CTA block
            Positioned(
              bottom: 12,
              left: 20,
              right: 20,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Pop(
                  index: 3,
                  child: BigButton(
                    label: returning ? 'Continue Adventure' : 'Let’s Start',
                    style: BtnStyle.go,
                    width: double.infinity,
                    height: 66,
                    fontSize: 28,
                    onTap: () => st.go(returning ? AppScreen.home : AppScreen.parent),
                  ),
                ),
                const SizedBox(height: 10),
                outlinedText('Turn Reading into an Adventure!', 17, stroke: const Color(0xFF2B6A45)),
                const SizedBox(height: 6),
                FittedBox(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _chip(Icons.play_arrow_rounded, 'Play'),
                  _dot(),
                  _chip(Icons.menu_book_rounded, 'Learn'),
                  _dot(),
                  _chip(Icons.spa_rounded, 'Grow'),
                ])),
                TextButton(
                  onPressed: () async {
                    if (!returning) {
                      st.go(AppScreen.parent);
                    } else if (await askParentGate(context)) {
                      st.go(AppScreen.dashboard);
                    }
                  },
                  child: Text('Parent / Grown-Up', style: ts(14, color: Colors.white, w: FontWeight.w500).copyWith(decoration: TextDecoration.underline, decorationColor: Colors.white70, shadows: const [Shadow(color: Color(0x88000000), blurRadius: 4)])),
                ),
              ]),
            ),
          ]);
        }),
      ),
        // taps on the scene: fireworks, balloons pop, birds chirp (buttons below still work normally)
        Positioned.fill(child: AmbientTapLayer(onTap: (p) => skyTap(_sky, p))),
      ]),
    );
  }

  Widget _chip(IconData i, String t) => Row(children: [
        Icon(i, color: Colors.white, size: 18),
        const SizedBox(width: 3),
        Text(t, style: ts(15, color: Colors.white).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 4)])),
      ]);
  Widget _dot() => const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('•', style: TextStyle(color: Colors.white70)));
}

class _Ribbon extends StatelessWidget {
  final String text;
  const _Ribbon({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6C4DF0), Color(0xFF8A6BFF)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [softShadow(const Color(0x55000000), 10, 4)],
        ),
        child: Text(text, style: ts(15, color: Colors.white)),
      );
}

/// The Wordoo logo (fox + star + lettering). [size] is its width.
class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});
  @override
  Widget build(BuildContext context) => Image.asset('assets/art/brand.logo.png', width: size, fit: BoxFit.contain, semanticLabel: Brand.name);
}
