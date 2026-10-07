import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../core/tts.dart';
import '../data/lang.dart';
import '../data/strings.dart';
import '../models/models.dart';
import 'common.dart';

enum GameSkin { plain, orchestra, archer, rocket, detective, hive, quest }

GameSkin skinFor(Skill s) => switch (s) {
      Skill.phonological => GameSkin.orchestra,
      Skill.gpc => GameSkin.archer,
      Skill.decoding => GameSkin.rocket,
      Skill.wordRecognition => GameSkin.detective,
      Skill.spelling => GameSkin.hive,
      Skill.comprehension => GameSkin.quest,
    };

/// Renders one [Item] in the visual style of its game, handles first-attempt scoring,
/// gentle retries, scaffolding and feedback. Used by both games and the hidden assessment.
class ItemView extends StatefulWidget {
  final Item item;
  final GameSkin skin;
  final LangPack pack;
  final bool scaffold;
  final bool allowRetry;
  final bool demo;
  final bool autoSpeak;
  final void Function(String msg, bool good)? onFeedback;
  final void Function(ItemResult r) onDone;
  const ItemView({
    super.key,
    required this.item,
    required this.skin,
    required this.pack,
    required this.onDone,
    this.onFeedback,
    this.scaffold = false,
    this.allowRetry = true,
    this.demo = false,
    this.autoSpeak = true,
  });
  @override
  State<ItemView> createState() => _ItemViewState();
}

class _ItemViewState extends State<ItemView> {
  final _clock = Stopwatch()..start();
  int _attempts = 0;
  bool _resolved = false;
  int? _correctShown;
  final Set<int> _faded = {};
  final Map<int, int> _shake = {};
  final List<String> _tags = [];
  int _arrowKey = 0;
  int? _arrowTo;
  Timer? _ticker;
  int _elapsed = 0;
  int _unitFlash = -1;

  // build state
  late List<int?> _slots;
  late Set<int> _locked;
  final Set<int> _usedTiles = {};
  bool _wrongBuild = false;

  Item get it => widget.item;
  String get lang => widget.pack.code;
  void _say(String t) => Speaker.instance.speak(t, widget.pack.tts);

  @override
  void initState() {
    super.initState();
    _slots = List<int?>.filled(it.answer.length, null);
    _locked = {};
    if (it.kind == ItemKind.choice && widget.scaffold && it.options.length > 2) {
      // scaffold: quietly remove one wrong choice
      final wrong = [for (var i = 0; i < it.options.length; i++) if (i != it.correct) i];
      _faded.add(wrong.first);
    }
    if (it.kind == ItemKind.build && widget.scaffold && it.answer.isNotEmpty) {
      // scaffold: first tile already placed
      final idx = it.tiles.indexOf(it.answer.first);
      _slots[0] = idx;
      _locked.add(0);
      _usedTiles.add(idx);
    }
    if (it.timed && !widget.demo) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !_resolved) setState(() => _elapsed = _clock.elapsed.inSeconds);
      });
    }
    if (widget.autoSpeak) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _say(it.say));
    }
    if (widget.scaffold) widget.onFeedback?.call(Str.t(lang, 'hint'), true);
    if (widget.demo) _runDemo();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _runDemo() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    if (it.kind == ItemKind.choice) {
      _tapChoice(it.correct, demo: true);
    } else {
      for (var i = 0; i < it.answer.length; i++) {
        await Future.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        final idx = it.tiles.indexOf(it.answer[i], 0);
        final real = List.generate(it.tiles.length, (k) => k).firstWhere((k) => it.tiles[k] == it.answer[i] && !_usedTiles.contains(k), orElse: () => idx);
        _placeTile(real, demo: true);
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _checkBuild(demo: true);
    }
  }

  void _finish(bool firstTryCorrect, {int delayMs = 1200}) {
    final ms = _clock.elapsedMilliseconds;
    final tags = [..._tags];
    if (it.timed && firstTryCorrect && ms > Cfg.slowResponseMs) tags.add('Slow response');
    final r = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: firstTryCorrect, ms: ms, tags: tags);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted && !widget.demo) widget.onDone(r);
    });
  }

  // ---------------- choice ----------------
  void _tapChoice(int i, {bool demo = false}) {
    if (_resolved || (widget.demo && !demo)) return;
    if (_faded.contains(i)) return;
    final o = it.options[i];
    if (widget.skin == GameSkin.archer) {
      _arrowKey++;
      _arrowTo = i;
    }
    if (o.say != null && it.skill != Skill.comprehension) _say(o.say!);
    if (i == it.correct) {
      setState(() {
        _resolved = true;
        _correctShown = i;
      });
      final first = _attempts == 0;
      widget.onFeedback?.call(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
      if (!demo) _finish(first);
    } else {
      _attempts++;
      if (o.tag != null) _tags.add(o.tag!);
      _shake[i] = (_shake[i] ?? 0) + 1;
      final canRetry = widget.allowRetry && _attempts < 2 && (it.options.length - _faded.length - 1) > 1;
      setState(() {
        _faded.add(i);
        if (!canRetry) {
          _resolved = true;
          _correctShown = it.correct;
        }
      });
      if (canRetry) {
        widget.onFeedback?.call(Str.t(lang, 'almost'), false);
      } else {
        widget.onFeedback?.call(Str.t(lang, widget.allowRetry ? 'another' : 'moveOn'), false);
        _finish(false, delayMs: 1700);
      }
    }
  }

  // ---------------- build ----------------
  void _placeTile(int tileIdx, {bool demo = false}) {
    if (_resolved || (widget.demo && !demo)) return;
    if (_usedTiles.contains(tileIdx)) return;
    final slot = _slots.indexOf(null);
    if (slot < 0) return;
    _say(it.tiles[tileIdx]);
    setState(() {
      _slots[slot] = tileIdx;
      _usedTiles.add(tileIdx);
      _wrongBuild = false;
    });
  }

  void _removeSlot(int s) {
    if (_resolved || widget.demo || _locked.contains(s) || _slots[s] == null) return;
    setState(() {
      _usedTiles.remove(_slots[s]);
      _slots[s] = null;
      _wrongBuild = false;
    });
  }

  void _checkBuild({bool demo = false}) {
    if (_resolved || (widget.demo && !demo)) return;
    final got = [for (final s in _slots) s == null ? '' : it.tiles[s]];
    final ok = got.length == it.answer.length && [for (var i = 0; i < got.length; i++) got[i] == it.answer[i]].every((x) => x);
    if (ok) {
      setState(() => _resolved = true);
      final first = _attempts == 0;
      widget.onFeedback?.call(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
      _say(it.replaySay ?? '');
      if (!demo) _finish(first, delayMs: 1500);
      return;
    }
    _attempts++;
    _tags.add(widget.pack.spellingError(got, it.answer));
    if (widget.allowRetry && _attempts < 2) {
      setState(() {
        _wrongBuild = true;
        // keep correct pieces in place, clear the rest — a scaffold, not a punishment
        for (var i = 0; i < _slots.length; i++) {
          if (got[i] == it.answer[i]) {
            _locked.add(i);
          } else {
            _usedTiles.remove(_slots[i]);
            _slots[i] = null;
          }
        }
      });
      widget.onFeedback?.call(Str.t(lang, 'almost'), false);
    } else {
      // reveal the correct word kindly
      setState(() {
        _resolved = true;
        _usedTiles.clear();
        for (var i = 0; i < it.answer.length; i++) {
          final k = List.generate(it.tiles.length, (x) => x).firstWhere((x) => it.tiles[x] == it.answer[i] && !_usedTiles.contains(x));
          _slots[i] = k;
          _usedTiles.add(k);
        }
      });
      widget.onFeedback?.call(Str.t(lang, widget.allowRetry ? 'another' : 'moveOn'), false);
      _say(it.replaySay ?? '');
      _finish(false, delayMs: 2200);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final isStory = it.passage != null;
    return LayoutBuilder(builder: (context, c) {
      final narrow = c.maxWidth < 520;
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight - 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isStory) _storyCard() else if (it.kind == ItemKind.choice) _prompt(narrow),
              const SizedBox(height: 14),
              if (it.kind == ItemKind.choice) _choices(c.maxWidth) else _build(c.maxWidth),
            ],
          ),
        ),
      );
    });
  }

  Widget _speaker() => RoundIconButton(
        icon: Icons.volume_up_rounded,
        label: 'Hear it again',
        color: C.gold,
        onTap: () {
          _say(it.replaySay ?? it.say);
          if (it.skill == Skill.decoding && it.stimulus != null) _flashUnits();
        },
      );

  Future<void> _flashUnits() async {
    final n = it.stimulus!.split(' · ').length;
    for (var i = 0; i < n; i++) {
      if (!mounted) return;
      setState(() => _unitFlash = i);
      await Future.delayed(const Duration(milliseconds: 650));
    }
    if (mounted) setState(() => _unitFlash = -1);
  }

  Widget _prompt(bool narrow) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Flexible(child: Text(it.prompt, textAlign: TextAlign.center, style: ts(narrow ? 24 : 30, color: Colors.white, h: 1.2).copyWith(shadows: const [Shadow(color: Color(0x66000000), blurRadius: 6)]))),
        const SizedBox(width: 12),
        _speaker(),
      ]),
      const SizedBox(height: 12),
      if (it.timed && !widget.demo)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(20)),
            child: Text('⏱ ${_elapsed}s', style: ts(16, color: C.inkSoft)),
          ),
        ),
      if (it.emoji != null && it.skill != Skill.spelling)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: .7, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), shape: BoxShape.circle, boxShadow: [softShadow()]),
            child: Text(it.emoji!, style: const TextStyle(fontSize: 64)),
          ),
        ),
      if (it.stimulus != null && it.skill == Skill.decoding) _unitTiles(),
      if (it.stimulus != null && it.skill == Skill.phonological && it.level >= 3 && it.level == 3)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(it.stimulus!, style: ts(40, color: Colors.white)),
        ),
      if (widget.scaffold && it.hint.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: C.gold.withValues(alpha: .95), borderRadius: BorderRadius.circular(20)),
            child: Text('💡 ${it.hint}', style: ts(16, color: C.ink)),
          ),
        ),
    ]);
  }

  Widget _unitTiles() {
    final units = it.stimulus!.split(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < units.length; i++)
            GestureDetector(
              onTap: () => _say(widget.pack.sayUnit(units[i])),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: _unitFlash == i ? C.gold : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: C.purple, width: 3),
                  boxShadow: [softShadow(const Color(0x33000000), 8, 4)],
                ),
                child: Text(units[i], style: ts(40, color: C.ink)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _storyCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 640),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.parchment,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.parchmentDark, width: 3),
        boxShadow: [softShadow()],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(it.emoji ?? '📖', style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 12),
          _speaker(),
        ]),
        const SizedBox(height: 10),
        Text(it.passage!, textAlign: TextAlign.center, style: ts(21, w: FontWeight.w600, h: 1.5)),
        const Divider(height: 26, color: C.parchmentDark, thickness: 2),
        Text(it.stimulus ?? '', textAlign: TextAlign.center, style: ts(24, color: C.purpleDark)),
      ]),
    );
  }

  Widget _choices(double maxW) {
    final n = it.options.length;
    final useColumn = widget.skin == GameSkin.quest || it.options.any((o) => o.emoji == null && o.label.runes.length > 6 && widget.skin != GameSkin.archer);
    final tiles = <Widget>[];
    for (var i = 0; i < n; i++) {
      if (_faded.contains(i) && !_resolved && it.options.length > 2 && widget.scaffold && i == _faded.first && _attempts == 0) {
        tiles.add(const SizedBox.shrink());
        continue;
      }
      tiles.add(_optionTile(i, useColumn));
    }
    Widget body;
    if (useColumn) {
      body = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(children: [for (final t in tiles) Padding(padding: const EdgeInsets.only(bottom: 12), child: t)]),
      );
    } else {
      body = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [for (final t in tiles) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: t))],
        ),
      );
    }
    if (widget.skin == GameSkin.archer) {
      return SizedBox(
        height: 250,
        width: min(maxW, 640),
        child: LayoutBuilder(builder: (_, c) {
          final shown = [for (var i = 0; i < n; i++) i];
          return Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: Align(alignment: Alignment.topCenter, child: body)),
            if (_arrowTo != null)
              TweenAnimationBuilder<double>(
                key: ValueKey(_arrowKey),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (_, t, __) {
                  final tx = c.maxWidth * (shown.indexOf(_arrowTo!) + .5) / n;
                  final x = lerpDouble(c.maxWidth / 2, tx, t)! - 18;
                  final y = lerpDouble(c.maxHeight - 10, 100, t)!;
                  return Positioned(left: x, top: y, child: Transform.rotate(angle: (tx - c.maxWidth / 2) / c.maxWidth * .9, child: const Text('🏹', style: TextStyle(fontSize: 34))));
                },
              ),
          ]);
        }),
      );
    }
    return body;
  }

  double? lerpDouble(double a, double b, double t) => a + (b - a) * t;

  Widget _optionTile(int i, bool column) {
    final o = it.options[i];
    final isCorrect = _correctShown == i;
    final faded = _faded.contains(i) && !isCorrect;
    final shake = _shake[i] ?? 0;
    Widget content;
    if (widget.skin == GameSkin.archer) {
      content = AspectRatio(
        aspectRatio: 1,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: Size.infinite, painter: _TargetPainter(faded: faded, hit: isCorrect)),
          Padding(
            padding: const EdgeInsets.all(26),
            child: FittedBox(child: Text(o.label, style: ts(46, color: C.ink))),
          ),
        ]),
      );
    } else if (o.emoji != null && it.skill != Skill.wordRecognition) {
      content = Center(child: FittedBox(child: Text(o.emoji!, style: const TextStyle(fontSize: 70))));
    } else {
      content = Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(o.label, style: ts(column ? 30 : 34, color: C.ink))));
    }

    final base = widget.skin == GameSkin.archer
        ? content
        : AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: column ? 76 : 120,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isCorrect ? const Color(0xFFD9FBE3) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: isCorrect ? C.green : _skinColor(), width: 3.5),
              boxShadow: [BoxShadow(color: (isCorrect ? C.green : _skinColor()).withValues(alpha: .85), offset: const Offset(0, 6), blurRadius: 0), softShadow(const Color(0x33000000), 12, 8)],
            ),
            child: Row(children: [
              if (column && widget.skin == GameSkin.quest) Padding(padding: const EdgeInsets.only(right: 10), child: Text(['A', 'B', 'C', 'D'][i], style: ts(22, color: C.purple))),
              Expanded(child: content),
              if (isCorrect) const Icon(Icons.check_circle_rounded, color: C.green, size: 32),
            ]),
          );

    return Semantics(
      button: true,
      label: o.label,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('o$i-$shake'),
        tween: Tween(begin: shake == 0 ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 380),
        builder: (_, t, ch) => Transform.translate(offset: Offset(sin(t * pi * 4) * 9 * (1 - t), 0), child: ch),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: faded ? .35 : 1,
          child: GestureDetector(onTap: () => _tapChoice(i), child: base),
        ),
      ),
    );
  }

  Color _skinColor() => switch (widget.skin) {
        GameSkin.orchestra => const Color(0xFF2FA866),
        GameSkin.rocket => const Color(0xFF1E88E5),
        GameSkin.detective => C.orange,
        GameSkin.quest => const Color(0xFFE0568A),
        _ => C.purple,
      };

  Widget _build(double maxW) {
    final n = it.answer.length;
    final slotSize = min(64.0, (min(maxW, 640) - 60) / max(n, 4) - 8);
    final tileSize = min(62.0, (min(maxW, 640) - 24) / 5 - 10);
    return Column(children: [
      Container(
        width: min(maxW, 640) - 8,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFBEBC5), Color(0xFFF1D79C)]),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: C.parchmentDark, width: 4),
          boxShadow: [softShadow(const Color(0x44000000), 16, 8)],
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: Text(it.prompt, textAlign: TextAlign.center, style: ts(22, color: const Color(0xFF6B4423)))),
            const SizedBox(width: 10),
            _speaker(),
          ]),
          const SizedBox(height: 10),
          if (it.emoji != null) Text(it.emoji!, style: const TextStyle(fontSize: 72)),
          if (widget.scaffold && it.hint.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('💡 ${it.hint}', textAlign: TextAlign.center, style: ts(15, color: const Color(0xFF6B4423), w: FontWeight.w500))),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var s = 0; s < n; s++)
                GestureDetector(
                  onTap: () => _removeSlot(s),
                  child: _Hex(
                    size: slotSize,
                    filled: _slots[s] != null,
                    locked: _locked.contains(s) || (_resolved && _slots[s] != null),
                    wrong: _wrongBuild,
                    label: _slots[s] == null ? '' : it.tiles[_slots[s]!],
                  ),
                ),
            ],
          ),
        ]),
      ),
      const SizedBox(height: 22),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var k = 0; k < it.tiles.length; k++)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _usedTiles.contains(k) ? .18 : 1,
              child: GestureDetector(
                onTap: () => _placeTile(k),
                child: _Hex(size: tileSize, filled: true, tile: true, label: it.tiles[k]),
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: (_slots.every((s) => s != null) && !_resolved) ? 1 : 0,
        child: IgnorePointer(
          ignoring: !(_slots.every((s) => s != null) && !_resolved),
          child: BigButton(label: Str.t(lang, 'check'), icon: Icons.check_rounded, style: BtnStyle.go, onTap: _checkBuild, width: 200),
        ),
      ),
    ]);
  }
}

class _Hex extends StatelessWidget {
  final double size;
  final bool filled, locked, wrong, tile;
  final String label;
  const _Hex({required this.size, required this.filled, this.locked = false, this.wrong = false, this.tile = false, this.label = ''});
  @override
  Widget build(BuildContext context) {
    final lipColor = locked ? C.greenDark : const Color(0xFFB8B2D8);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: !filled ? const Color(0x33805A28) : (locked ? const Color(0xFFD9FBE3) : Colors.white),
        borderRadius: BorderRadius.circular(size * .24),
        border: Border.all(color: !filled ? const Color(0x66805A28) : (locked ? C.green : (wrong ? C.orange : Colors.white)), width: filled ? 3 : 2.5),
        boxShadow: filled ? [BoxShadow(color: lipColor, offset: const Offset(0, 5), blurRadius: 0), softShadow(const Color(0x33000000), 8, 6)] : null,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FittedBox(child: Text(label, style: ts(34, color: C.ink))),
      ),
    );
  }
}

class _TargetPainter extends CustomPainter {
  final bool faded, hit;
  _TargetPainter({this.faded = false, this.hit = false});
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.shortestSide / 2;
    final cols = [const Color(0xFFE5483F), Colors.white, const Color(0xFFE5483F), Colors.white, const Color(0xFFFFD34D)];
    canvas.drawCircle(c + const Offset(0, 5), r, Paint()..color = const Color(0x33000000));
    for (var i = 0; i < cols.length; i++) {
      canvas.drawCircle(c, r * (1 - i * .19), Paint()..color = cols[i]);
    }
    canvas.drawCircle(c, r * .62, Paint()..color = Colors.white.withValues(alpha: .92));
    if (hit) {
      canvas.drawCircle(c, r, Paint()
        ..color = C.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7);
    }
  }

  @override
  bool shouldRepaint(_TargetPainter o) => o.hit != hit;
}
