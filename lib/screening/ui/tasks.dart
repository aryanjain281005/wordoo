import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/tts.dart';
import '../../widgets/common.dart';
import '../bank.dart';
import '../battery.dart';
import '../models.dart';
import '../speech_engine.dart';
import '../voxlexi.dart';

typedef Done = void Function(List<ItemResponse> r);

/// Shared plumbing for all screening tasks: timing, replays, neutral feedback.
abstract class TaskState<T extends StatefulWidget> extends State<T> {
  final sw = Stopwatch()..start();
  int replays = 0;
  bool locked = false;
  ScreenBank get bank;
  void say(String t) => Speaker.instance.speak(t, bank.tts);
  void replay(String t) {
    replays++;
    say(t);
  }
}

Widget promptBar(String text, {VoidCallback? onReplay, Color color = Colors.white}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Flexible(child: Text(text, textAlign: TextAlign.center, style: ts(22, color: color).copyWith(shadows: color == Colors.white ? const [Shadow(color: Color(0x66000000), blurRadius: 6)] : null))),
        if (onReplay != null) ...[const SizedBox(width: 10), RoundIconButton(icon: Icons.volume_up_rounded, label: 'Hear again', color: C.gold, onTap: onReplay, size: 52)],
      ]),
    );

Widget parchment({required Widget child, EdgeInsets pad = const EdgeInsets.all(16)}) => Container(
      width: double.infinity,
      padding: pad,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFBEBC5), Color(0xFFF1D79C)]),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.parchmentDark, width: 4),
        boxShadow: [softShadow(const Color(0x44000000), 16, 8)],
      ),
      child: child,
    );

class _OptCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool picked;
  final double height;
  const _OptCard({required this.child, required this.onTap, this.picked = false, this.height = 110});
  @override
  State<_OptCard> createState() => _OptCardState();
}

class _OptCardState extends State<_OptCard> {
  bool down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => down = true),
        onTapCancel: () => setState(() => down = false),
        onTapUp: (_) => setState(() => down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.height,
          transform: Matrix4.translationValues(0, down ? 4 : 0, 0),
          decoration: BoxDecoration(
            color: widget.picked ? const Color(0xFFEDE6FF) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: widget.picked ? C.purple : const Color(0xFFD8D2F0), width: 3.5),
            boxShadow: [BoxShadow(color: (widget.picked ? C.purple : const Color(0xFFB8B2D8)).withValues(alpha: .9), offset: Offset(0, down ? 2 : 6), blurRadius: 0)],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: widget.child,
        ),
      );
}

// =====================================================================
// Choice tasks: rhyme, first sound, sound magic, letter–sound, sentence→picture
// =====================================================================
class ChoiceTask extends StatefulWidget {
  final SItem item;
  final SubtestDef def;
  final ScreenBank bank;
  final Done onDone;
  final void Function(String msg)? onSay;
  const ChoiceTask({super.key, required this.item, required this.def, required this.bank, required this.onDone, this.onSay});
  @override
  State<ChoiceTask> createState() => _ChoiceTaskState();
}

class _ChoiceTaskState extends TaskState<ChoiceTask> {
  @override
  ScreenBank get bank => widget.bank;
  late final List<int> order = List.generate(widget.item.options.length, (i) => i)..shuffle(Random(widget.item.id.hashCode));
  int? picked;
  int? playing;

  String get spoken {
    final it = widget.item;
    switch (widget.def.task) {
      case TaskType.letterChoice:
        return bank.code == 'hi' ? '${it.say}  —  कौन सा अक्षर?' : 'Which letter says ${it.say}?';
      case TaskType.sentencePicture:
      case TaskType.passage:
        return ''; // reading items are not read aloud
      default:
        return it.say ?? '';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => say(spoken));
  }

  void _pick(int i) {
    if (locked) return;
    final opt = widget.item.options[i];
    if (widget.def.task == TaskType.audioChoice && playing != i) {
      // first tap plays the option, second tap chooses it
      setState(() => playing = i);
      say(opt.say ?? opt.label);
      return;
    }
    setState(() {
      picked = i;
      locked = true;
    });
    widget.onSay?.call(bank.ui['nice']!);
    final correct = i == widget.item.correct;
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      widget.onDone([
        ItemResponse(itemId: widget.item.id, subtest: widget.def.id, score: correct ? 1 : 0, ms: sw.elapsedMilliseconds, replays: replays, tag: correct ? null : _tag()),
      ]);
    });
  }

  String _tag() => switch (widget.def.id) {
        'rhyme' => 'Rhyme confusion',
        'firstSound' => 'Wrong first sound',
        'phonemeManip' => 'Sound deletion / replacement error',
        'letterSound' => widget.item.difficulty >= 2 ? 'Similar letter / matra confusion' : 'Wrong letter',
        _ => 'Wrong detail',
      };

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final task = widget.def.task;
    final reading = task == TaskType.sentencePicture || (task == TaskType.passage && it.passage != null && it.questions.isEmpty);
    return LayoutBuilder(builder: (context, c) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
        child: Column(children: [
          if (!reading) promptBar(task == TaskType.letterChoice ? (bank.code == 'hi' ? 'आवाज़ सुनो, अक्षर चुनो' : 'Listen, then tap the letter') : (it.say ?? ''), onReplay: () => replay(spoken)),
          const SizedBox(height: 14),
          if (it.emoji != null && it.subtest == 'rhyme')
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [softShadow()]),
              child: Text(it.emoji!, style: const TextStyle(fontSize: 64)),
            ),
          if (it.subtest == 'firstSound')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [softShadow()]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.hearing_rounded, color: C.purple, size: 34), const SizedBox(width: 8), Text(bank.code == 'hi' ? it.target! : '/${it.target}/', style: ts(36, color: C.ink))]),
            ),
          if (reading)
            parchment(child: Column(children: [
              Text(bank.code == 'hi' ? 'पढ़ो और सही चित्र चुनो' : 'Read, then tap the matching picture', style: ts(16, color: const Color(0xFF6B4423), w: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(it.passage!, textAlign: TextAlign.center, style: ts(30, color: C.ink, h: 1.4)),
            ])),
          const SizedBox(height: 18),
          if (task == TaskType.audioChoice)
            Row(children: [
              for (var k = 0; k < order.length; k++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _OptCard(
                      picked: picked == order[k] || playing == order[k],
                      onTap: () => _pick(order[k]),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(playing == order[k] ? Icons.check_circle_rounded : Icons.volume_up_rounded, size: 44, color: playing == order[k] ? C.green : C.purple),
                        Text('${k + 1}', style: ts(22, color: C.inkSoft)),
                      ]),
                    ),
                  ),
                ),
            ])
          else
            Row(children: [
              for (final i in order)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _OptCard(
                      picked: picked == i,
                      height: task == TaskType.letterChoice ? 96 : 118,
                      onTap: () => _pick(i),
                      child: it.options[i].emoji != null
                          ? FittedBox(child: Text(it.options[i].emoji!, style: const TextStyle(fontSize: 60)))
                          : FittedBox(child: Text(it.options[i].label, style: ts(44, color: C.ink))),
                    ),
                  ),
                ),
            ]),
          if (task == TaskType.audioChoice)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(bank.code == 'hi' ? 'एक बार दबाकर सुनो, दोबारा दबाकर चुनो' : 'Tap once to hear, tap again to choose', style: ts(15, color: Colors.white).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 4)])),
            ),
        ]),
      );
    });
  }
}

// =====================================================================
// Questions after a story (listening) or a passage (reading, middle)
// =====================================================================
class QuestionsTask extends StatefulWidget {
  final SItem item;
  final SubtestDef def;
  final ScreenBank bank;
  final Done onDone;
  final bool listening;
  final void Function(String msg)? onSay;
  const QuestionsTask({super.key, required this.item, required this.def, required this.bank, required this.onDone, required this.listening, this.onSay});
  @override
  State<QuestionsTask> createState() => _QuestionsTaskState();
}

class _QuestionsTaskState extends TaskState<QuestionsTask> {
  @override
  ScreenBank get bank => widget.bank;
  int q = -1; // -1 = story stage
  final results = <ItemResponse>[];
  int? picked;
  final qsw = Stopwatch();

  @override
  void initState() {
    super.initState();
    if (widget.listening) WidgetsBinding.instance.addPostFrameCallback((_) => say(widget.item.passage!));
  }

  void _startQuestions() {
    Speaker.instance.stop();
    setState(() => q = 0);
    qsw.start();
    say(widget.item.questions[0].q);
  }

  void _answer(int i) {
    if (picked != null) return;
    final qq = widget.item.questions[q];
    setState(() => picked = i);
    widget.onSay?.call(bank.ui['nice']!);
    results.add(ItemResponse(itemId: '${widget.item.id}.q$q', subtest: widget.def.id, score: i == qq.correct ? 1 : 0, ms: qsw.elapsedMilliseconds, replays: replays, tag: i == qq.correct ? null : qq.tag));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (q + 1 >= widget.item.questions.length) {
        widget.onDone(results);
      } else {
        setState(() {
          q++;
          picked = null;
        });
        qsw.reset();
        say(widget.item.questions[q].q);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    if (q < 0) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        child: Column(children: [
          promptBar(widget.listening ? (bank.code == 'hi' ? 'ध्यान से सुनो' : 'Listen carefully') : (bank.code == 'hi' ? 'ध्यान से पढ़ो' : 'Read carefully'), onReplay: widget.listening ? () => replay(it.passage!) : null),
          const SizedBox(height: 14),
          parchment(
            child: widget.listening
                ? Column(children: [
                    const Text('📖👂', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    Text(bank.code == 'hi' ? 'मीलो कहानी सुना रहा है…' : 'Milo is telling a story…', style: ts(20, color: const Color(0xFF6B4423))),
                  ])
                : Text(it.passage!, style: ts(22, color: C.ink, w: FontWeight.w500, h: 1.6)),
          ),
          const SizedBox(height: 20),
          BigButton(label: bank.ui['next']!, icon: Icons.arrow_forward_rounded, style: BtnStyle.go, width: 220, onTap: _startQuestions),
        ]),
      );
    }
    final qq = it.questions[q];
    final hasEmoji = qq.options.first.emoji != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
      child: Column(children: [
        promptBar(qq.q, onReplay: () => replay(qq.q)),
        const SizedBox(height: 16),
        if (hasEmoji)
          Row(children: [
            for (var i = 0; i < qq.options.length; i++)
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _OptCard(
                  picked: picked == i,
                  onTap: () => _answer(i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FittedBox(child: Text(qq.options[i].emoji!, style: const TextStyle(fontSize: 50))),
                    const SizedBox(height: 4),
                    FittedBox(child: Text(qq.options[i].label, style: ts(14, color: C.inkSoft))),
                  ]),
                ),
              )),
          ])
        else
          for (var i = 0; i < qq.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptCard(
                height: 72,
                picked: picked == i,
                onTap: () => _answer(i),
                child: Row(children: [
                  Text(['A', 'B', 'C'][i], style: ts(22, color: C.purple)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(qq.options[i].label, style: ts(19))),
                ]),
              ),
            ),
      ]),
    );
  }
}

// =====================================================================
// Spelling with letter / akshara tiles
// =====================================================================
class TilesTask extends StatefulWidget {
  final SItem item;
  final SubtestDef def;
  final ScreenBank bank;
  final Done onDone;
  final void Function(String msg)? onSay;
  const TilesTask({super.key, required this.item, required this.def, required this.bank, required this.onDone, this.onSay});
  @override
  State<TilesTask> createState() => _TilesTaskState();
}

class _TilesTaskState extends TaskState<TilesTask> {
  @override
  ScreenBank get bank => widget.bank;
  late final List<String> tiles = [...widget.item.answer, ...widget.item.distractors]..shuffle(Random(widget.item.id.hashCode));
  late final List<int?> slots = List.filled(widget.item.answer.length, null);
  final used = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => say(widget.item.target!));
  }

  void _place(int k) {
    if (locked || used.contains(k)) return;
    final s = slots.indexOf(null);
    if (s < 0) return;
    setState(() {
      slots[s] = k;
      used.add(k);
    });
  }

  void _remove(int s) {
    if (locked || slots[s] == null) return;
    setState(() {
      used.remove(slots[s]);
      slots[s] = null;
    });
  }

  String _classify(List<String> got, List<String> want) {
    if (got.length != want.length) return got.length < want.length ? 'Missing unit' : 'Extra unit';
    final diff = [for (var i = 0; i < want.length; i++) if (got[i] != want[i]) i];
    if (diff.length == 2 && diff[1] == diff[0] + 1 && got[diff[0]] == want[diff[1]] && got[diff[1]] == want[diff[0]]) return 'Swapped order';
    if (bank.code == 'hi' && diff.every((i) => got[i].runes.first == want[i].runes.first)) return 'Wrong matra';
    if (bank.code == 'en' && diff.every((i) => 'aeiou'.contains(want[i]) && 'aeiou'.contains(got[i]))) return 'Wrong vowel';
    return bank.code == 'hi' ? 'Wrong akshara' : 'Wrong letter';
  }

  void _check() {
    if (locked) return;
    locked = true;
    final got = [for (final s in slots) tiles[s!]];
    final ok = got.join() == widget.item.answer.join();
    widget.onSay?.call(bank.ui['nice']!);
    widget.onDone([
      ItemResponse(itemId: widget.item.id, subtest: widget.def.id, score: ok ? 1 : 0, ms: sw.elapsedMilliseconds, replays: replays, tag: ok ? null : _classify(got, widget.item.answer)),
    ]);
  }

  Widget _tile(String label, {required bool filled, double size = 58, bool ghost = false}) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: !filled ? const Color(0x33805A28) : (ghost ? Colors.white.withValues(alpha: .25) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: !filled ? const Color(0x66805A28) : Colors.white, width: 2.5),
          boxShadow: filled && !ghost ? const [BoxShadow(color: Color(0xFFB8B2D8), offset: Offset(0, 5))] : null,
        ),
        child: Padding(padding: const EdgeInsets.all(4), child: FittedBox(child: Text(label, style: ts(32, color: ghost ? Colors.white54 : C.ink)))),
      );

  @override
  Widget build(BuildContext context) {
    final full = slots.every((s) => s != null);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
      child: Column(children: [
        parchment(
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(child: Text(widget.def.l(bank.code), textAlign: TextAlign.center, style: ts(20, color: const Color(0xFF6B4423)))),
              const SizedBox(width: 10),
              RoundIconButton(icon: Icons.volume_up_rounded, label: 'Hear again', color: C.gold, onTap: () => replay(widget.item.target!), size: 50),
            ]),
            const SizedBox(height: 8),
            if (widget.item.emoji != null) Text(widget.item.emoji!, style: const TextStyle(fontSize: 66)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (var s = 0; s < slots.length; s++) GestureDetector(onTap: () => _remove(s), child: _tile(slots[s] == null ? '' : tiles[slots[s]!], filled: slots[s] != null)),
            ]),
          ]),
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          for (var k = 0; k < tiles.length; k++) GestureDetector(onTap: () => _place(k), child: _tile(tiles[k], filled: true, ghost: used.contains(k))),
        ]),
        const SizedBox(height: 18),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: full ? 1 : 0,
          child: IgnorePointer(ignoring: !full, child: BigButton(label: bank.ui['done']!, icon: Icons.check_rounded, style: BtnStyle.go, width: 200, onTap: _check)),
        ),
      ]),
    );
  }
}

// =====================================================================
// Speaking tasks (scored by the device — VoxLexi pipeline, no adult)
// =====================================================================
class MicButton extends StatelessWidget {
  final bool listening;
  final double level;
  final VoidCallback onTap;
  const MicButton({super.key, required this.listening, required this.level, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final pulse = listening ? (12 + level.clamp(0, 10) * 3.2) : 0.0;
    return Semantics(
      button: true,
      label: 'Microphone',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: listening ? const [Color(0xFFFF8FA8), Color(0xFFE5483F)] : const [Color(0xFF9B7DFF), Color(0xFF6C4DF0)]),
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [BoxShadow(color: (listening ? const Color(0xFFE5483F) : C.purple).withValues(alpha: .45), blurRadius: 18 + pulse, spreadRadius: pulse / 3)],
          ),
          child: Icon(listening ? Icons.graphic_eq_rounded : Icons.mic_rounded, color: Colors.white, size: 56),
        ),
      ),
    );
  }
}

/// Picture naming, word reading, nonword reading.
class ReadAloudTask extends StatefulWidget {
  final SItem item;
  final SubtestDef def;
  final ScreenBank bank;
  final Done onDone;
  final void Function(String msg)? onSay;
  const ReadAloudTask({super.key, required this.item, required this.def, required this.bank, required this.onDone, this.onSay});
  @override
  State<ReadAloudTask> createState() => _ReadAloudTaskState();
}

class _ReadAloudTaskState extends TaskState<ReadAloudTask> {
  @override
  ScreenBank get bank => widget.bank;
  bool listening = false;
  double level = 0;
  int tries = 0;

  bool get naming => widget.def.id == 'pictureNaming';

  @override
  void initState() {
    super.initState();
    if (naming) WidgetsBinding.instance.addPostFrameCallback((_) => say(widget.def.l(bank.code)));
  }

  Future<void> _listen() async {
    if (listening || locked) return;
    await Speaker.instance.stop();
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() => listening = true);
    final m = await SpeechEngine.instance.capture(
      locale: bank.asr,
      listenFor: const Duration(seconds: 7),
      pauseFor: const Duration(milliseconds: 1800),
      onLevel: (l) {
        if (mounted) setState(() => level = l);
      },
    );
    if (!mounted) return;
    setState(() {
      listening = false;
      level = 0;
    });
    final heard = m.transcript.trim().isNotEmpty || m.alternates.any((a) => a.trim().isNotEmpty);
    if (!heard && tries == 0) {
      tries++;
      widget.onSay?.call(bank.ui['again']!);
      return;
    }
    locked = true;
    final nonword = widget.def.id == 'nonwordReading';
    final sim = heard ? VoxLexi.bestMatch(widget.item.target!, m, accept: widget.item.accept, phonetic: nonword || bank.code == 'en') : 0.0;
    final score = VoxLexi.scoreFromMatch(sim, nonword: nonword);
    String? tag;
    if (!heard) {
      tag = 'No response';
    } else if (score < 1) {
      tag = switch (widget.def.id) {
        'nonwordReading' => 'Incorrect blend',
        'wordReading' => m.latencyMs > 4000 ? 'Slow / hesitant reading' : 'Misread word',
        _ => 'Naming difficulty',
      };
    }
    widget.onSay?.call(bank.ui['thanks']!);
    widget.onDone([
      ItemResponse(itemId: widget.item.id, subtest: widget.def.id, score: score, ms: sw.elapsedMilliseconds, replays: replays, tag: tag, speech: m),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      child: Column(children: [
        promptBar(widget.def.l(bank.code), onReplay: naming ? () => replay(widget.def.l(bank.code)) : null),
        const SizedBox(height: 16),
        parchment(
          pad: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Center(
            child: naming
                ? Text(it.emoji ?? '', style: const TextStyle(fontSize: 110))
                : FittedBox(child: Text(it.target!, style: ts(64, color: C.ink, ls: bank.code == 'en' ? 2 : 0))),
          ),
        ),
        const SizedBox(height: 26),
        MicButton(listening: listening, level: level, onTap: _listen),
        const SizedBox(height: 10),
        Text(listening ? bank.ui['listening']! : bank.ui['tapMic']!, style: ts(17, color: Colors.white).copyWith(shadows: const [Shadow(color: Color(0x88000000), blurRadius: 4)])),
      ]),
    );
  }
}

/// Long speaking turns (RAN grid, oral reading, semantic fluency) — keeps listening across
/// recognizer restarts until the child taps Done or time runs out.
mixin LongCapture<T extends StatefulWidget> on TaskState<T> {
  bool listening = false;
  bool stopRequested = false;
  double level = 0;
  int elapsed = 0;
  Timer? ticker;

  Future<({String text, List<String> alts, int speechMs, int pauses, int pauseMs, int totalMs})> captureLong(Duration total, {bool dictation = true}) async {
    await Speaker.instance.stop();
    await Future.delayed(const Duration(milliseconds: 250));
    stopRequested = false;
    final start = DateTime.now();
    setState(() => listening = true);
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => elapsed = DateTime.now().difference(start).inSeconds);
    });
    final parts = <String>[], alts = <String>[];
    var speechMs = 0, pauses = 0, pauseMs = 0, segments = 0;
    while (!stopRequested) {
      final left = total - DateTime.now().difference(start);
      if (left.inMilliseconds < 800) break;
      final m = await SpeechEngine.instance.capture(
        locale: bank.asr,
        listenFor: left,
        pauseFor: const Duration(seconds: 4),
        dictation: dictation,
        onLevel: (l) {
          if (mounted) setState(() => level = l);
        },
      );
      if (m.transcript.trim().isNotEmpty) {
        parts.add(m.transcript.trim());
        alts.addAll(m.alternates);
        segments++;
      }
      speechMs += m.durationMs;
      pauses += m.pauses;
      pauseMs += m.pauseMs;
      if (m.transcript.trim().isEmpty && DateTime.now().difference(start).inSeconds > 8 && segments > 0) break;
    }
    ticker?.cancel();
    final totalMs = DateTime.now().difference(start).inMilliseconds;
    if (mounted) {
      setState(() {
        listening = false;
        level = 0;
      });
    }
    return (text: parts.join(' '), alts: alts, speechMs: speechMs, pauses: pauses + max(0, segments - 1).toInt(), pauseMs: pauseMs, totalMs: totalMs);
  }

  void requestStop() {
    stopRequested = true;
    SpeechEngine.instance.stop();
  }

  @override
  void dispose() {
    ticker?.cancel();
    if (listening) SpeechEngine.instance.stop();
    super.dispose();
  }
}

class RanTask extends StatefulWidget {
  final SItem item;
  final SubtestDef def;
  final ScreenBank bank;
  final Done onDone;
  final void Function(String msg)? onSay;
  const RanTask({super.key, required this.item, required this.def, required this.bank, required this.onDone, this.onSay});
  @override
  State<RanTask> createState() => _RanTaskState();
}

class _RanTaskState extends TaskState<RanTask> with LongCapture<RanTask> {
  @override
  ScreenBank get bank => widget.bank;
  static const _pattern = [0, 1, 2, 3, 4, 2, 4, 0, 3, 1, 3, 0, 4, 1, 2, 1, 3, 2, 0, 4];
  bool practiced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => say('${widget.item.options.map((o) => o.label).join(', ')}.  ${widget.def.l(bank.code)}'));
  }

  Future<void> _go() async {
    final r = await captureLong(const Duration(seconds: 45));
    final names = [for (final i in _pattern) widget.item.options[i].label];
    final acc = VoxLexi.ranAccuracy(r.text, names, widget.item.accept);
    final secs = max(1.0, (r.speechMs > 2000 ? r.speechMs : r.totalMs) / 1000.0);
    final rate = acc * names.length / secs;
    locked = true;
    widget.onSay?.call(bank.ui['thanks']!);
    widget.onDone([
      ItemResponse(
          itemId: widget.item.id,
          subtest: widget.def.id,
          score: acc,
          ms: sw.elapsedMilliseconds,
          rate: double.parse(rate.toStringAsFixed(2)),
          tag: acc < .7 ? 'Naming errors / skipped items' : null,
          speech: SpeechMetrics(transcript: r.text, durationMs: r.speechMs, pauses: r.pauses, pauseMs: r.pauseMs)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.item.options;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
      child: Column(children: [
        promptBar(practiced ? widget.def.l(bank.code) : (bank.code == 'hi' ? 'पहले इनके नाम सीखो' : 'First, learn the names'), onReplay: () => replay(o.map((x) => x.label).join(', '))),
        const SizedBox(height: 12),
        if (!practiced) ...[
          parchment(
            child: Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 10, children: [
              for (final x in o)
                GestureDetector(
                  onTap: () => say(x.label),
                  child: Column(children: [Text(x.emoji!, style: const TextStyle(fontSize: 48)), Text(x.label, style: ts(16, color: C.ink))]),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          BigButton(label: bank.ui['ready']!, style: BtnStyle.go, width: 220, onTap: () => setState(() => practiced = true)),
        ] else ...[
          parchment(
            pad: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [for (final i in _pattern) FittedBox(child: Text(o[i].emoji!, style: const TextStyle(fontSize: 40)))],
            ),
          ),
          const SizedBox(height: 18),
          if (!listening)
            BigButton(label: bank.ui['go']!, icon: Icons.mic_rounded, style: BtnStyle.go, width: 220, onTap: locked ? null : _go)
          else
            Column(children: [
              MicButton(listening: true, level: level, onTap: requestStop),
              const SizedBox(height: 8),
              Text('⏱ ${elapsed}s', style: ts(18, color: Colors.white)),
              const SizedBox(height: 8),
              BigButton(label: bank.ui['done']!, style: BtnStyle.soft, height: 52, onTap: requestStop),
            ]),
        ],
      ]),
    );
  }
}

class OralReadingTask extends StatefulWidget {
  final SItem item;
  final SubtestDef def;
  final ScreenBank bank;
  final Done onDone;
  final GradeBand band;
  final void Function(String msg)? onSay;
  const OralReadingTask({super.key, required this.item, required this.def, required this.bank, required this.onDone, required this.band, this.onSay});
  @override
  State<OralReadingTask> createState() => _OralReadingTaskState();
}

class _OralReadingTaskState extends TaskState<OralReadingTask> with LongCapture<OralReadingTask> {
  @override
  ScreenBank get bank => widget.bank;

  Future<void> _go() async {
    final limit = widget.band == GradeBand.junior ? const Duration(seconds: 45) : const Duration(seconds: 75);
    final r = await captureLong(limit);
    final cmp = VoxLexi.compareSequences(widget.item.passage!, r.text);
    final acc = cmp.correct / cmp.total;
    final secs = max(1.0, (r.speechMs > 2000 ? r.speechMs : r.totalMs) / 1000.0);
    final wcpm = cmp.correct / (secs / 60.0);
    final expectedWpm = widget.def.norm(widget.band).rateMean!;
    final risk = VoxLexi.fluencyRisk(actualSec: secs, expectedSec: cmp.total / (expectedWpm / 60), pauses: r.pauses, pauseSec: r.pauseMs / 1000);
    locked = true;
    widget.onSay?.call(bank.ui['thanks']!);
    widget.onDone([
      ItemResponse(
        itemId: widget.item.id,
        subtest: widget.def.id,
        score: acc,
        ms: sw.elapsedMilliseconds,
        rate: double.parse(wcpm.toStringAsFixed(1)),
        tag: risk >= .66 ? 'Slow reading with many pauses' : (acc < .7 ? 'Many words missed or misread' : null),
        speech: SpeechMetrics(transcript: r.text, durationMs: r.speechMs, pauses: r.pauses, pauseMs: r.pauseMs, confidence: risk),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
      child: Column(children: [
        promptBar(widget.def.l(bank.code)),
        const SizedBox(height: 12),
        parchment(child: Text(widget.item.passage!, style: ts(widget.band == GradeBand.junior ? 28 : 22, color: C.ink, w: FontWeight.w500, h: 1.6))),
        const SizedBox(height: 18),
        if (!listening)
          BigButton(label: bank.ui['go']!, icon: Icons.mic_rounded, style: BtnStyle.go, width: 220, onTap: locked ? null : _go)
        else
          Column(children: [
            MicButton(listening: true, level: level, onTap: requestStop),
            const SizedBox(height: 8),
            Text('⏱ ${elapsed}s', style: ts(18, color: Colors.white)),
            const SizedBox(height: 8),
            BigButton(label: bank.ui['done']!, style: BtnStyle.soft, height: 52, onTap: requestStop),
          ]),
      ]),
    );
  }
}

class FluencyTask extends StatefulWidget {
  final SItem item;
  final SubtestDef def;
  final ScreenBank bank;
  final Done onDone;
  final void Function(String msg)? onSay;
  const FluencyTask({super.key, required this.item, required this.def, required this.bank, required this.onDone, this.onSay});
  @override
  State<FluencyTask> createState() => _FluencyTaskState();
}

class _FluencyTaskState extends TaskState<FluencyTask> with LongCapture<FluencyTask> {
  @override
  ScreenBank get bank => widget.bank;
  int found = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => say(widget.item.say!));
  }

  Future<void> _go() async {
    final r = await captureLong(const Duration(seconds: 60));
    final lex = widget.item.target == 'foods' ? bank.foods : bank.animals;
    final c = VoxLexi.countCategory(r.text, r.alts, lex);
    locked = true;
    widget.onSay?.call(bank.ui['thanks']!);
    widget.onDone([
      ItemResponse(itemId: widget.item.id, subtest: widget.def.id, score: 1, ms: sw.elapsedMilliseconds, rate: c.count.toDouble(), speech: SpeechMetrics(transcript: r.text, durationMs: r.speechMs, pauses: r.pauses, pauseMs: r.pauseMs)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final left = max(0, 60 - elapsed);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
      child: Column(children: [
        promptBar(widget.item.say!, onReplay: () => replay(widget.item.say!)),
        const SizedBox(height: 16),
        parchment(child: Column(children: [
          Text(widget.item.target == 'foods' ? '🍎🍌🥕🍕🥛🍪' : '🦁🐘🐒🐶🐄🦜', style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 10),
          Text(listening ? '⏱ $left' : (bank.code == 'hi' ? '60 सेकंड' : '60 seconds'), style: ts(36, color: const Color(0xFF6B4423))),
        ])),
        const SizedBox(height: 20),
        if (!listening)
          BigButton(label: bank.ui['go']!, icon: Icons.mic_rounded, style: BtnStyle.go, width: 220, onTap: locked ? null : _go)
        else
          Column(children: [
            MicButton(listening: true, level: level, onTap: requestStop),
            const SizedBox(height: 10),
            BigButton(label: bank.ui['done']!, style: BtnStyle.soft, height: 52, onTap: requestStop),
          ]),
      ]),
    );
  }
}
