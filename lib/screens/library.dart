import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/content_pack.dart';
import '../core/assets.dart';
import '../core/audio.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../story/story_book.dart';
import '../widgets/art.dart';
import '../widgets/common.dart';

/// The Story Castle Library: every story the child has understood in Story Quest, to read again any time.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final all = st.content.stories.where((s) => isAuthoredStory(s.id)).toList();
    return Scaffold(
      body: AdventureBackground(
        scene: Scene.castle,
        artId: 'bg.island.castle',
        calm: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                RoundIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(child: Text('Story Library', style: ts(28, color: Colors.white).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 8)]))),
                Text('${st.libraryBooks.length}/${all.length}', style: ts(18, color: Colors.white)),
              ]),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .78,
                children: [for (final s in all) _BookTile(story: s, open: st.libraryBooks.contains(s.id))],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final StoryEntry story;
  final bool open;
  const _BookTile({required this.story, required this.open});
  @override
  Widget build(BuildContext context) {
    final cover = ReadleAssets.instance.art('story.${story.id}');
    return GestureDetector(
      onTap: open ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookReader(story: story))) : null,
      child: Semantics(
        button: open,
        label: open ? story.title : 'Locked story',
        child: Container(
          decoration: BoxDecoration(
            color: open ? const Color(0xFFFFF8EA) : const Color(0xFFF1EDF8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD9B98A), width: 3),
            boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: open && cover != null
                    ? Image.asset(cover, fit: BoxFit.cover, width: double.infinity)
                    : Container(
                        width: double.infinity,
                        color: open ? const Color(0xFFFFE3EE) : const Color(0xFFE6E2F5),
                        alignment: Alignment.center,
                        child: Text(open ? story.emoji : '🔒', style: const TextStyle(fontSize: 48)),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(open ? story.title : 'Still lost…', textAlign: TextAlign.center, maxLines: 2, style: ts(16, color: open ? C.ink : C.inkSoft)),
          ]),
        ),
      ),
    );
  }
}

/// Re-read a restored book: page by page, read aloud with highlighting.
class BookReader extends StatefulWidget {
  final StoryEntry story;
  const BookReader({super.key, required this.story});
  @override
  State<BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  late final pages = splitSentences(widget.story.text);
  final _narrator = Narrator();
  int page = 0, lit = -1;
  bool reading = false;

  @override
  void dispose() {
    _narrator.stop();
    AudioManager.instance.stopVoice();
    super.dispose();
  }

  Future<void> _read() async {
    setState(() => reading = true);
    for (var p = page; p < pages.length && reading && mounted; p++) {
      setState(() => page = p);
      await _narrator.read(bookLineId(widget.story.id, p), pages[p], (w) {
        if (mounted) setState(() => lit = w);
      });
    }
    if (mounted) setState(() => reading = false);
  }

  void _go(int d) {
    _narrator.stop();
    AudioManager.instance.stopVoice();
    AudioManager.instance.sfx('page_turn', volume: .5);
    setState(() {
      reading = false;
      lit = -1;
      page = (page + d).clamp(0, pages.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tts = context.read<AppState>().pack.tts;
    return Scaffold(
      body: AdventureBackground(
        scene: Scene.castle,
        artId: 'bg.island.castle',
        calm: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                RoundIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.story.title, style: ts(24, color: Colors.white).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 8)]))),
              ]),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFFF8EA), borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFD9B98A), width: 3)),
                      child: Column(children: [
                        BookPanel(key: ValueKey(page), storyId: widget.story.id, emoji: widget.story.emoji, sentence: pages[page], index: page, litWord: lit, pictureHeight: 230, ttsLocale: tts, storyText: widget.story.text),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          RoundIconButton(icon: Icons.chevron_left_rounded, label: 'Previous page', onTap: () => _go(-1)),
                          Text('${page + 1} / ${pages.length}', style: ts(16, color: C.inkSoft)),
                          RoundIconButton(icon: reading ? Icons.stop_rounded : Icons.volume_up_rounded, label: 'Read to me', color: C.gold, onTap: reading ? () => _go(0) : _read),
                          RoundIconButton(icon: Icons.chevron_right_rounded, label: 'Next page', onTap: () => _go(1)),
                        ]),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
