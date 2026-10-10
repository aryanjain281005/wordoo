import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/loc.dart';
import '../core/theme.dart';
import '../data/strings.dart';
import '../state/app_state.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

/// "Your First Adventure" — the child sees a broken bridge, not an assessment.
class AdventureIntro extends StatelessWidget {
  const AdventureIntro({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final re = st.hasBaseline;
    final line = Str.t(st.langCode, re ? 'skyBridge' : 'bridge');
    final tr = Tr(st.hindi); // Hindi demo: this bridge screen before the screening
    return AdventureBackground(
      scene: re ? Scene.castle : Scene.forest,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Pop(child: Text(tr(re ? 'Your Next Adventure Awaits!' : 'Your First Adventure'), textAlign: TextAlign.center, style: ts(38, color: Colors.white, w: FontWeight.w900).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 10)]))),
                const SizedBox(height: 18),
                Pop(index: 1, child: _BridgePicture(broken: true)),
                const SizedBox(height: 14),
                Pop(index: 2, child: Companion(type: st.avatar.companion, size: 130, message: tr.f('{companion} says: {line}', {'companion': st.hindi ? 'मिलो' : Brand.companion, 'line': line}), speakLocale: st.pack.tts)),
                const SizedBox(height: 22),
                Pop(
                  index: 3,
                  child: BigButton(
                    label: tr(re ? 'Let’s Go!' : 'Let’s Fix It!'),
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
                  child: Text(tr('For grown-ups: this adventure is a literacy screening (about 15 minutes). The phone listens to reading-aloud activities and scores them automatically. It is not a diagnosis.'),
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

