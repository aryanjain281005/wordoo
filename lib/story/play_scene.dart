import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'cutscene.dart';

/// Plays a story scene and remembers that it was seen (seen scenes can be skipped right away
/// and rewatched from the Explorer's Journal).
Future<void> playScene(BuildContext context, String id) async {
  final st = context.read<AppState>();
  await Navigator.of(context).push(PageRouteBuilder(
    pageBuilder: (_, _, _) => CutsceneScreen(sceneId: id, canSkip: st.seenScenes.contains(id), companion: st.avatar.companion, gumsumLightness: st.gumsumLightness),
    transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 500),
  ));
  st.markSeen(id);
}
