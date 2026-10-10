import 'package:flutter/material.dart';
import 'story/story_lines.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/audio.dart';
import 'core/cloud.dart';
import 'core/theme.dart';
import 'data/strings.dart';
import 'screens/app_shell.dart';
import 'state/app_state.dart';
import 'widgets/art.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // smoothness over size: keep plenty of decoded pictures ready, so going back to a screen never re-decodes
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = 512 << 20
    ..maximumSize = 2000;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  AudioManager.instance.init();
  StoryLines.instance.load();
  Cloud.instance.init('en'); // question bank copy + refresh from the Wordoo server (optional: the app works offline)
  runApp(ChangeNotifierProvider(create: (_) => AppState()..load(), child: const WordooApp()));
}

class WordooApp extends StatelessWidget {
  const WordooApp({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final scale = [1.0, 1.15, 1.3][st.textSize.clamp(0, 2)];
    return MaterialApp(
      title: '${Brand.name} — ${Brand.tagline}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(extraSpacing: st.extraSpacing),
      builder: (context, child) => Stack(children: [
        Positioned.fill(
          child: _PhoneFrame(
            textScale: scale,
            child: Material(type: MaterialType.transparency, child: child!),
          ),
        ),
        const Positioned(left: 0, top: 0, child: GpuWarmUp()), // effects used by the games are prepared during the start screen
      ]),
      home: const AppShell(),
    );
  }
}

/// Mobile-first: on phones the app fills the screen; on laptops/tablets it is shown
/// inside a phone-shaped frame so the demo looks exactly like the handset experience.
class _PhoneFrame extends StatelessWidget {
  final Widget child;
  final double textScale;
  const _PhoneFrame({required this.child, required this.textScale});
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final wide = mq.size.width > 560;
    final h = wide ? (mq.size.height - 24).clamp(560.0, 900.0) : mq.size.height;
    final w = wide ? (h * 0.52).clamp(340.0, 430.0) : mq.size.width;
    final inner = MediaQuery(
      data: mq.copyWith(size: Size(w, h), textScaler: TextScaler.linear(textScale)),
      child: child,
    );
    if (!wide) return inner;
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment(0, -.4), radius: 1.2, colors: [Color(0xFF2B2F6B), Color(0xFF0E1130)]),
      ),
      alignment: Alignment.center,
      child: Container(
        width: w + 16,
        height: h + 16,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0D20),
          borderRadius: BorderRadius.circular(46),
          border: Border.all(color: const Color(0xFF3A3F7A), width: 3),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 40, offset: Offset(0, 20))],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(38), child: SizedBox(width: w, height: h, child: inner)),
      ),
    );
  }
}
