import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../core/audio.dart';
import '../../core/theme.dart';
import '../../core/tts.dart';
import '../../data/strings.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../game_module.dart';

const reefCreatures = ['🐠', '🐡', '🦑', '🐙', '🦀', '🐚', '🦐', '🐟', '🦞', '🐬'];

/// Game 6 · Word Builder — "Coral's Reef City".
/// The voice says a word (often a made-up creature name). Sound blocks float in the water; the child drags
/// or taps them into the reef slots in order — each block sounds as it locks. The right name hatches a
/// creature that swims into the reef city. Scaffold: the first block is already placed.
class WordBuilderItem extends StatefulWidget {
  final GameCtx ctx;
  final int reefSize; // persistent: creatures named so far
  const WordBuilderItem({super.key, required this.ctx, this.reefSize = 0});
  @override
  State<WordBuilderItem> createState() => _WordBuilderItemState();
}

class _WordBuilderItemState extends State<WordBuilderItem> with TickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final AnimationController _hatch = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final List<String> answer = (it.stimulus ?? it.options[it.correct].label).split(' · ').where((s) => s.isNotEmpty).toList();
  late final List<String> sounds = () {
    final s = (it.replaySay ?? '').split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
    return s.length == answer.length ? s : answer;
  }();
  late final List<String> blocks = _makeBlocks();
  late final List<int?> _slots = List<int?>.filled(answer.length, null);
  final Set<int> _used = {};
  final Set<int> _locked = {};
  final Set<int> _pale = {};
  final List<String> _tags = [];
  int _attempts = 0;
  bool _resolved = false;
  bool _hatched = false;
  bool _disposed = false;

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  bool get demo => widget.ctx.demo;
  String get word => it.options[it.correct].label;
  void _say(String t) => Speaker.instance.speak(t, widget.ctx.pack.tts);

  /// The word's blocks plus 1–2 distractor blocks taken from the other answer words.
  List<String> _makeBlocks() {
    final rng = Random(word.hashCode);
    final extra = <String>[];
    for (final o in it.options) {
      if (o.label == word) continue;
      for (final ch in o.label.split('')) {
        if (!answer.contains(ch) && !extra.contains(ch) && RegExp(r'[a-z]').hasMatch(ch)) extra.add(ch);
      }
    }
    extra.shuffle(rng);
    final want = it.level <= 3 ? 1 : 2;
    return [...answer, ...extra.take(want)]..shuffle(rng);
  }

  @override
  void initState() {
    super.initState();
    if (widget.ctx.scaffold && answer.isNotEmpty) {
      final k = blocks.indexOf(answer.first);
      _slots[0] = k;
      _used.add(k);
      _locked.add(0);
      widget.ctx.feedback(Str.t(lang, 'hint'), true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => demo ? _runDemo() : _say(word));
  }

  @override
  void dispose() {
    _disposed = true;
    _float.dispose();
    _hatch.dispose();
    super.dispose();
  }

  Future<void> _runDemo() async {
    for (var i = 0; i < answer.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (_disposed) return;
      if (_slots[i] != null) continue;
      final k = _free(answer[i]);
      if (k != null) _place(k, slot: i, force: true);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_disposed) _check(force: true);
  }

  int? _free(String unit) {
    for (var k = 0; k < blocks.length; k++) {
      if (blocks[k] == unit && !_used.contains(k)) return k;
    }
    return null;
  }

  void _place(int block, {int? slot, bool force = false}) {
    if (_resolved || (demo && !force) || _used.contains(block)) return;
    final s = slot ?? _slots.indexOf(null);
    if (s < 0 || _locked.contains(s)) return;
    AudioManager.instance.sfx('bubble', volume: .5);
    if (!demo) _say(blocks[block]);
    setState(() {
      final old = _slots[s];
      if (old != null) _used.remove(old);
      _slots[s] = block;
      _used.add(block);
      _pale.remove(s);
    });
    if (!_slots.contains(null)) Future.delayed(const Duration(milliseconds: 450), () => _check(force: force));
  }

  void _remove(int s) {
    if (_resolved || demo || _locked.contains(s) || _slots[s] == null) return;
    AudioManager.instance.sfx('tile_return');
    setState(() {
      _used.remove(_slots[s]);
      _slots[s] = null;
    });
  }

  void _check({bool force = false}) {
    if (_resolved || (demo && !force) || _slots.contains(null) || _disposed) return;
    final got = [for (final s in _slots) blocks[s!]];
    final wrong = [for (var i = 0; i < got.length; i++) if (got[i] != answer[i]) i];
    if (wrong.isEmpty) {
      _win();
      return;
    }
    _attempts++;
    _tags.add('Incorrect blend');
    AudioManager.instance.sfx('miss_soft');
    if (_attempts < 2) {
      setState(() {
        for (var i = 0; i < got.length; i++) {
          if (wrong.contains(i)) {
            _used.remove(_slots[i]);
            _slots[i] = null;
            _pale.add(i);
          } else {
            _locked.add(i);
          }
        }
      });
      widget.ctx.feedback('Say it slowly: ${sounds.join(' … ')}', false);
      _sayParts();
    } else {
      setState(() {
        _resolved = true;
        _used.clear();
        for (var i = 0; i < answer.length; i++) {
          _slots[i] = null;
        }
        for (var i = 0; i < answer.length; i++) {
          final k = _free(answer[i]) ?? blocks.indexOf(answer[i]);
          _slots[i] = k;
          _used.add(k);
        }
        _pale.clear();
      });
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      _say(word);
      _finish(false, 2400);
    }
  }

  Future<void> _sayParts() async {
    for (final s in sounds) {
      if (_disposed) return;
      _say(s);
      await Future.delayed(const Duration(milliseconds: 750));
    }
  }

  Future<void> _win() async {
    final first = _attempts == 0;
    setState(() {
      _resolved = true;
      _hatched = true;
      _pale.clear();
    });
    AudioManager.instance.sfx('magic', volume: .6);
    _hatch.forward(from: 0);
    _say(word);
    if (demo) return;
    widget.ctx.feedback(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
    _finish(first, 2100);
  }

  void _finish(bool first, int delayMs) {
    final r = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: first, ms: _clock.elapsedMilliseconds, tags: [..._tags]);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_disposed && !demo) widget.ctx.done(r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final creature = reefCreatures[(word.hashCode & 0x7fffffff) % reefCreatures.length];
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(10, 4, 10, 6), child: _header()),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(fit: StackFit.expand, children: [
              ArtImage('bg.reef.city', fit: BoxFit.cover, fallback: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6AD4E8), Color(0xFF1E7FA8), Color(0xFF145A7A)])))),
              Positioned(left: 0, right: 0, top: 8, child: _reefCity()),
              Align(alignment: const Alignment(0, -.15), child: _slotsRow()),
              Positioned(left: 8, right: 8, bottom: 14, child: _blockPool()),
              if (_hatched) Positioned.fill(child: IgnorePointer(child: _hatchOverlay(creature))),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _header() => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          SizedBox(width: 56, height: 56, child: ArtImage('char.coral.happy', fallback: const Center(child: Text('🐙', style: TextStyle(fontSize: 38))))),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Build the name you hear, block by block', style: ts(16, color: C.ink)),
              if (!demo) Text('🐚 Reef-o-pedia: ${widget.reefSize} creatures', style: ts(12, color: C.inkSoft, w: FontWeight.w600)),
            ]),
          ),
          RoundIconButton(icon: Icons.volume_up_rounded, label: 'Hear the name', color: C.gold, size: 44, onTap: demo ? () {} : () => _say(word)),
        ]),
      );

  Widget _reefCity() => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (var k = 0; k < min(widget.reefSize, 9); k++)
          AnimatedBuilder(
            animation: _float,
            builder: (_, child) => Transform.translate(offset: Offset(sin((_float.value + k * .2) * 2 * pi) * 6, cos((_float.value + k * .3) * 2 * pi) * 4), child: child),
            child: Text(reefCreatures[k % reefCreatures.length], style: const TextStyle(fontSize: 22)),
          ),
      ]);

  Widget _slotsRow() => LayoutBuilder(builder: (context, box) => _slotsRowFor(box.maxWidth));

  /// Slot width comes from the real board width (not the screen), so long words always fit.
  Widget _slotsRowFor(double maxW) {
    final w = min(70.0, (maxW - 34) / answer.length - 8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCCF9B3C8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE0568A), width: 3),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var s = 0; s < answer.length; s++)
          DragTarget<int>(
            onAcceptWithDetails: (d) => _place(d.data, slot: s),
            builder: (_, cand, _) => GestureDetector(
              onTap: () => _remove(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: w,
                height: 70,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _slots[s] == null ? (cand.isNotEmpty ? const Color(0xFFFFF1F6) : const Color(0x88FFFFFF)) : (_locked.contains(s) || _hatched ? const Color(0xFFCDEFC4) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _pale.contains(s) ? const Color(0xFFE3A3A3) : (_locked.contains(s) || _hatched ? const Color(0xFF4CAF50) : const Color(0xFFB0306A)), width: 2.5),
                ),
                child: _slots[s] == null ? null : FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.all(4), child: Text(blocks[_slots[s]!], style: ts(30, color: C.ink)))),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _blockPool() => Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
        for (var k = 0; k < blocks.length; k++)
          AnimatedOpacity(
            opacity: _used.contains(k) ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _used.contains(k) || _resolved || demo,
              child: AnimatedBuilder(
                animation: _float,
                builder: (_, child) => Transform.translate(offset: Offset(0, sin((_float.value + k * .23) * 2 * pi) * 5), child: child),
                child: Draggable<int>(
                  data: k,
                  feedback: Material(color: Colors.transparent, child: _block(blocks[k], lifted: true)),
                  childWhenDragging: Opacity(opacity: .25, child: _block(blocks[k])),
                  child: GestureDetector(onTap: () => _place(k), child: _block(blocks[k])),
                ),
              ),
            ),
          ),
      ]);

  Widget _block(String unit, {bool lifted = false}) => Container(
        width: 62,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE3EE), Color(0xFFFF9EC0)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB0306A), width: 3),
          boxShadow: [BoxShadow(color: const Color(0x55000000), blurRadius: lifted ? 14 : 6, offset: const Offset(0, 3))],
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.all(4), child: Text(unit, style: ts(28, color: C.ink)))),
      );

  Widget _hatchOverlay(String creature) => AnimatedBuilder(
        animation: _hatch,
        builder: (_, _) {
          final t = _hatch.value;
          final pop = Curves.elasticOut.transform(min(1, t * 1.6));
          final swim = max(0.0, (t - .55) / .45);
          return Align(
            alignment: Alignment(swim * 1.4, .35 - swim * .9),
            child: Transform.scale(
              scale: pop,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(creature, style: const TextStyle(fontSize: 64)),
                if (!demo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text('a $word-${creature == '🐟' || creature == '🐠' || creature == '🐡' ? 'fish' : 'friend'}!', style: ts(16, color: const Color(0xFFB0306A))),
                  ),
              ]),
            ),
          );
        },
      );
}
