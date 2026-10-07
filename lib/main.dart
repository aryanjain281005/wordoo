import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'data/strings.dart';
import 'screens/app_shell.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => AppState()..load(), child: const ReadleApp()));
}

class ReadleApp extends StatelessWidget {
  const ReadleApp({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final scale = [1.0, 1.15, 1.3][st.textSize.clamp(0, 2)];
    return MaterialApp(
      title: '${Brand.name} — ${Brand.tagline}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(extraSpacing: st.extraSpacing),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: Material(type: MaterialType.transparency, child: child!),
      ),
      home: const AppShell(),
    );
  }
}
