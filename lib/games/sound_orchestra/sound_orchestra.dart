import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/assets.dart';
import '../../core/audio.dart';
import '../../core/theme.dart';
import '../../data/strings.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../game_module.dart';

/// The jungle band. Each member stands on a tree stump and "sings" one answer.
class BandMember {
  final String id, name, emoji, sfx;
  final Color color;
  const BandMember(this.id, this.name, this.emoji, this.sfx, this.color);
}

const band = [
  BandMember('tinku', 'Tinku', '🐒', 'wood_knock', Color(0xFFE59A3B)),
  BandMember('koyal', 'Koyal', '🐦', 'glass_ting', Color(0xFF4FA7E0)),
  BandMember('gajju', 'Gajju', '🐘', 'thud_soft', Color(0xFF9C8BD9)),
];

/// How awake the band is during one quest (0..4). Each right answer adds a music layer; a miss loses one.
class OrchestraBand {
  static int level = 0;
  static void reset() => level = 0;
  static void apply() => AudioManager.instance.setMusicLevel(.3 + level * .175);
}

/// Game 1 · Sound Orchestra — "The Jungle Band Lost Its Rhythm".
/// Maestro Bhalu sings a word (or the chorus sings its sounds); the child taps a band member to hear its
/// word and taps ✓ to choose. "Clap the Beat" rounds: tap Gajju's drum once per syllable.
class SoundOrchestraItem extends StatefulWidget {
  final GameCtx ctx;
  const SoundOrchestraItem({super.key, required this.ctx});
  @override
  State<SoundOrchestraItem> createState() => _SoundOrchestraItemState();
}

class _SoundOrchestraItemState extends State<SoundOrchestraItem> with TickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late final AnimationController _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  final _rng = Random();
  int? _selected;
  int? _singing;
  int? _correctShown;
  final Set<int> _faded = {};
  final Map<int, int> _shake = {};
  final List<String> _tags = [];
  final List<_Note> _notes = [];
  int _attempts = 0;
  bool _resolved = false;
  bool _disposed = false;
  int _chorusLit = -1;
  // clap mode
  int _taps = 0;
  int _drumHit = 0;

  Item get it => widget.ctx.item;
  String get lang => widget.ctx.pack.code;
  bool get demo => widget.ctx.demo;
  String get tts => widget.ctx.pack.tts;
  bool get clap => it.id.startsWith('pc:');
  bool get blend => it.id.startsWith('pb:');
  /// Listen-only rounds (levels 3–4) hide the pictures: the child must hear the rhyme.
  bool get listenOnly => it.audioOptions;
  bool get pictures => !listenOnly && it.options.every((o) => o.emoji != null);
  List<String> get _units => (it.replaySay ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    if (demo) {
      OrchestraBand.reset(); // a new quest starts with a sleepy band
    }
    OrchestraBand.apply();
    if (widget.ctx.scaffold && it.options.length > 2 && !clap) {
      _faded.add([for (var i = 0; i < it.options.length; i++) if (i != it.correct) i].first);
      widget.ctx.feedback(Str.t(lang, 'hint'), true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => demo ? _runDemo() : _sing());
  }

  @override
  void dispose() {
    _disposed = true;
    _beat.dispose();
    super.dispose();
  }

  void _say(String t) => AudioManager.instance.say(t, ttsLocale: tts);

  /// Maestro Bhalu sings the challenge; for blends the chorus sings one sound at a time.
  Future<void> _sing() async {
    if (!blend) {
      _say(it.say);
      return;
    }
    _say(it.prompt);
    await Future.delayed(const Duration(milliseconds: 1600));
    for (var i = 0; i < _units.length; i++) {
      if (_disposed) return;
      setState(() => _chorusLit = i);
      AudioManager.instance.sfx(band[i % band.length].sfx, volume: .35);
      _say(_units[i]);
      await Future.delayed(const Duration(milliseconds: 850));
    }
    if (!_disposed) setState(() => _chorusLit = -1);
  }

  Future<void> _runDemo() async {
    await Future.delayed(const Duration(milliseconds: 1300));
    if (_disposed) return;
    if (clap) {
      final n = int.tryParse(it.options[it.correct].label) ?? 1;
      for (var i = 0; i < n; i++) {
        _hitDrum(force: true);
        await Future.delayed(const Duration(milliseconds: 550));
        if (_disposed) return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_disposed) setState(() => _correctShown = it.correct);
      return;
    }
    _tapMember(it.correct, force: true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!_disposed) setState(() => _correctShown = it.correct);
  }

  // ---------------- choosing ----------------
  void _tapMember(int i, {bool force = false}) {
    if (_resolved || (demo && !force) || _faded.contains(i)) return;
    final o = it.options[i];
    AudioManager.instance.sfx(band[i % band.length].sfx, volume: .5);
    if (!demo) _say(o.say ?? o.label);
    setState(() {
      _selected = i;
      _singing = i;
      _notes.add(_Note(i, _rng.nextDouble()));
      if (_notes.length > 8) _notes.removeAt(0);
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!_disposed && _singing == i) setState(() => _singing = null);
    });
    // with pictures, one tap is the answer (children expect that); listen-only rounds use ✓ to choose
    if (!listenOnly && !demo) _choose(i);
  }

  void _choose(int i) {
    if (_resolved || demo) return;
    if (i == it.correct) {
      final first = _attempts == 0;
      setState(() {
        _resolved = true;
        _correctShown = i;
      });
      OrchestraBand.level = min(4, OrchestraBand.level + (first ? 1 : 0));
      OrchestraBand.apply();
      AudioManager.instance.sfx('magic', volume: .5);
      widget.ctx.feedback(first ? Str.good(lang) : Str.t(lang, 'good3'), true);
      _finish(first, 1500);
      return;
    }
    _attempts++;
    final tag = it.options[i].tag;
    if (tag != null) _tags.add(tag);
    OrchestraBand.level = max(0, OrchestraBand.level - 1);
    OrchestraBand.apply();
    final canRetry = _attempts < 2 && (it.options.length - _faded.length - 1) > 1;
    setState(() {
      _shake[i] = (_shake[i] ?? 0) + 1;
      _faded.add(i);
      _selected = null;
      if (!canRetry) {
        _resolved = true;
        _correctShown = it.correct;
      }
    });
    if (canRetry) {
      widget.ctx.feedback(it.hint.isEmpty ? Str.t(lang, 'almost') : it.hint, false);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!_disposed) _sing(); // Bhalu sings it again, slowly
      });
    } else {
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!_disposed) _say(it.options[it.correct].say ?? it.options[it.correct].label);
      });
      _finish(false, 2400);
    }
  }

  // ---------------- clap the beat ----------------
  void _hitDrum({bool force = false}) {
    if (_resolved || (demo && !force) || _taps >= 4) return;
    AudioManager.instance.sfx('thud_soft', volume: .8);
    setState(() {
      _taps++;
      _drumHit++;
    });
  }

  void _clapDone() {
    if (_resolved || demo || _taps == 0) return;
    final k = it.options.indexWhere((o) => o.label == '$_taps');
    if (k >= 0 && k == it.correct) {
      _choose(k);
      return;
    }
    // a count that isn't the answer: kindly count again
    _attempts++;
    _tags.add('Syllable count error');
    OrchestraBand.level = max(0, OrchestraBand.level - 1);
    OrchestraBand.apply();
    if (_attempts < 2) {
      setState(() => _taps = 0);
      widget.ctx.feedback(it.hint, false);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!_disposed) _say(it.stimulus ?? it.say);
      });
    } else {
      setState(() {
        _resolved = true;
        _correctShown = it.correct;
        _taps = int.tryParse(it.options[it.correct].label) ?? _taps;
      });
      widget.ctx.feedback(Str.t(lang, 'another'), false);
      _finish(false, 2400);
    }
  }

  void _finish(bool firstTry, int delayMs) {
    final r = ItemResult(itemId: it.id, skill: it.skill, level: it.level, correct: firstTry, ms: _clock.elapsedMilliseconds, tags: [..._tags]);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_disposed && !demo) widget.ctx.done(r);
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _beat, builder: (_, _) => CustomPaint(painter: _FireflyPainter(OrchestraBand.level, _beat.value))))),
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(children: [
          _maestro(),
          const SizedBox(height: 14),
          if (clap) _drum() else _stage(),
          const SizedBox(height: 10),
          _bandMeter(),
        ]),
      ),
    ]);
  }

  Widget _maestro() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .93), borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        SizedBox(
          width: 74,
          height: 84,
          child: AnimatedBuilder(
            animation: _beat,
            builder: (_, child) => Transform.rotate(angle: sin(_beat.value * 2 * pi) * .05, child: child),
            child: ArtImage('char.bhalu.happy', fallback: const Center(child: Text('🐻', style: TextStyle(fontSize: 54)))),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.prompt, style: ts(19, color: C.ink)),
            if (listenOnly && !clap) Text('Tap a band member to hear their word, then ✓', style: ts(13, color: C.inkSoft, w: FontWeight.w600)),
            if (blend) ...[const SizedBox(height: 6), _chorusDots()],
          ]),
        ),
        if (it.emoji != null && !blend) Text(it.emoji!, style: const TextStyle(fontSize: 46)),
        const SizedBox(width: 4),
        RoundIconButton(icon: Icons.volume_up_rounded, label: 'Sing it again', color: C.gold, size: 44, onTap: demo ? () {} : _sing),
      ]),
    );
  }

  Widget _chorusDots() => Row(children: [
        for (var i = 0; i < _units.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            width: i == _chorusLit ? 30 : 22,
            height: i == _chorusLit ? 30 : 22,
            decoration: BoxDecoration(shape: BoxShape.circle, color: i == _chorusLit ? band[i % band.length].color : const Color(0xFFE6E2F5), boxShadow: i == _chorusLit ? [BoxShadow(color: band[i % band.length].color, blurRadius: 12)] : const []),
            child: Center(child: Text('♪', style: ts(14, color: Colors.white))),
          ),
      ]);

  Widget _stage() {
    final n = it.options.length;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (var i = 0; i < n; i++) Expanded(child: _member(i)),
    ]);
  }

  Widget _member(int i) {
    final m = band[i % band.length];
    final o = it.options[i];
    final faded = _faded.contains(i);
    final sel = _selected == i;
    final right = _correctShown == i;
    final awake = i < OrchestraBand.level + 1;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: faded ? .3 : 1,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('shake$i${_shake[i] ?? 0}'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (_, t, child) => Transform.translate(offset: Offset((_shake[i] ?? 0) == 0 ? 0 : sin(t * pi * 5) * 7 * (1 - t), 0), child: child),
        child: GestureDetector(
          onTap: () => _tapMember(i),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // the picture card the band member is singing
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 92,
              height: 86,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: right ? const Color(0xFFCDEFC4) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: right ? const Color(0xFF4CAF50) : (sel ? m.color : const Color(0xFFD7D0F0)), width: right || sel ? 4 : 2),
                boxShadow: [BoxShadow(color: (sel ? m.color : Colors.black).withValues(alpha: sel ? .5 : .15), blurRadius: sel ? 14 : 6)],
              ),
              child: Center(
                child: pictures ? Text(o.emoji!, style: const TextStyle(fontSize: 46)) : Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.music_note_rounded, size: 30, color: C.inkSoft), Text('${i + 1}', style: ts(22, color: C.ink))]),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 92,
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                // tree stump
                Positioned(
                  bottom: 0,
                  child: SizedBox(
                    width: 92,
                    height: 44,
                    child: ArtImage('prop.orchestra.stump', fit: BoxFit.contain, fallback: Container(margin: const EdgeInsets.only(top: 8), decoration: BoxDecoration(color: const Color(0xFF8B5A2B), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF5E3A17), width: 3)))),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  child: AnimatedBuilder(
                    animation: _beat,
                    builder: (_, child) {
                      final bounce = _singing == i ? -10 * sin(_beat.value * pi).abs() : (awake ? -3 * sin(_beat.value * 2 * pi + i).abs() : 0.0);
                      return Transform.translate(offset: Offset(0, bounce), child: child);
                    },
                    child: ColorFiltered(
                      colorFilter: awake ? const ColorFilter.mode(Colors.transparent, BlendMode.dst) : const ColorFilter.matrix(_grey),
                      child: SizedBox(width: 70, height: 70, child: ArtImage('char.${m.id}.happy', fallback: Center(child: Text(m.emoji, style: const TextStyle(fontSize: 52))))),
                    ),
                  ),
                ),
                for (final n in _notes.where((n) => n.member == i)) _FloatingNote(key: ValueKey(n), seed: n.seed, color: m.color),
              ]),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: listenOnly && sel && !_resolved && !demo
                  ? AnimatedBuilder(
                      animation: _beat,
                      builder: (_, child) => Transform.scale(scale: 1 + .08 * sin(_beat.value * 2 * pi), child: child),
                      child: BigButton(label: '✓', style: BtnStyle.go, width: 86, height: 48, fontSize: 28, onTap: () => _choose(i)),
                    )
                  : Text(m.name, style: ts(14, color: Colors.white, w: FontWeight.w600).copyWith(shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)])),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _drum() {
    final want = _correctShown != null ? int.tryParse(it.options[it.correct].label) : null;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 4; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _taps ? (want != null ? const Color(0xFF4CAF50) : const Color(0xFFFFC93C)) : Colors.white.withValues(alpha: .6),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _hitDrum,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(_drumHit),
          tween: Tween(begin: .88, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Column(children: [
            // painted Gajju already carries his dhol; otherwise elephant + drum
            if (ReadleAssets.instance.art('char.gajju.happy') != null)
              SizedBox(width: 210, height: 210, child: ArtImage('char.gajju.happy', fallback: const SizedBox.shrink()))
            else ...[
              const SizedBox(width: 120, height: 110, child: Center(child: Text('🐘', style: TextStyle(fontSize: 84)))),
              SizedBox(width: 130, height: 110, child: ArtImage('prop.orchestra.drum', fallback: const Center(child: Text('🥁', style: TextStyle(fontSize: 92))))),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 8),
      if (!demo && !_resolved)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          RoundIconButton(icon: Icons.refresh_rounded, label: 'Count again', size: 46, onTap: () => setState(() => _taps = 0)),
          const SizedBox(width: 14),
          Opacity(opacity: _taps == 0 ? .4 : 1, child: BigButton(label: '✓', style: BtnStyle.go, width: 90, height: 52, fontSize: 26, onTap: _clapDone)),
        ]),
    ]);
  }

  Widget _bandMeter() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: i < OrchestraBand.level ? 1 : .25,
              child: Text(const ['🥁', '🎶', '🎺', '🌟'][i], style: const TextStyle(fontSize: 22)),
            ),
          ),
      ]);

  static const _grey = <double>[
    .33, .33, .33, 0, 10, //
    .33, .33, .33, 0, 10,
    .33, .33, .33, 0, 10,
    0, 0, 0, .85, 0,
  ];
}

class _Note {
  final int member;
  final double seed;
  _Note(this.member, this.seed);
}

/// A music note that floats up from a singing band member and fades away.
class _FloatingNote extends StatelessWidget {
  final double seed;
  final Color color;
  const _FloatingNote({super.key, required this.seed, required this.color});
  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            builder: (_, t, _) => Align(
              alignment: Alignment(sin(t * 6 + seed * 6) * .45, .2 - t * 1.6),
              child: Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: Text(seed > .5 ? '♪' : '♫', style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.bold))),
            ),
          ),
        ),
      );
}

/// Fireflies that join the music as the band wakes up.
class _FireflyPainter extends CustomPainter {
  final int level;
  final double t;
  _FireflyPainter(this.level, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final n = level * 4;
    for (var i = 0; i < n; i++) {
      final r = Random(i * 31 + 7);
      final x = (r.nextDouble() * size.width + sin((t + i * .13) * 2 * pi) * 12) % size.width;
      final y = r.nextDouble() * size.height * .9 + cos((t + i * .21) * 2 * pi) * 10;
      final a = .45 + .45 * sin((t * 2 + r.nextDouble()) * pi).abs();
      canvas.drawCircle(Offset(x, y), 7, Paint()..color = const Color(0xFFFFF59D).withValues(alpha: a * .35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(Offset(x, y), 2.4, Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_FireflyPainter o) => o.level != level || o.t != t;
}
