import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/audio.dart';
import '../core/tts.dart';
import 'art.dart';

enum BtnStyle { primary, go, soft, ghost }

class BigButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final BtnStyle style;
  final double? width;
  final double height;
  final double fontSize;
  const BigButton(
      {super.key,
      required this.label,
      this.onTap,
      this.icon,
      this.style = BtnStyle.primary,
      this.width,
      this.height = 64,
      this.fontSize = 22});
  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final (top, bottom, edge, fg) = switch (widget.style) {
      BtnStyle.primary => (const Color(0xFF9B7DFF), const Color(0xFF6C4DF0), const Color(0xFF3D26A8), Colors.white),
      BtnStyle.go => (const Color(0xFFFFC04D), const Color(0xFFFF8A1F), const Color(0xFFC25A00), Colors.white),
      BtnStyle.soft => (Colors.white, const Color(0xFFEDE9FF), const Color(0xFFB9B0E8), C.purpleDark),
      BtnStyle.ghost => (const Color(0x22FFFFFF), const Color(0x11FFFFFF), const Color(0x44FFFFFF), Colors.white),
    };
    final lip = _down ? 2.0 : 6.0;
    final r = widget.height / 2;
    final label = Text(widget.label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: ts(widget.fontSize, color: fg, w: FontWeight.w700).copyWith(
            shadows: widget.style == BtnStyle.soft || widget.style == BtnStyle.ghost ? null : [Shadow(color: edge.withValues(alpha: .7), offset: const Offset(0, 2), blurRadius: 0)]));
    final btn = Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                AudioManager.instance.sfx('ui_tap', volume: .5);
                widget.onTap!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : .5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            width: widget.width,
            height: widget.height + 6,
            padding: EdgeInsets.only(top: 6 - lip),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                color: edge,
                boxShadow: widget.style == BtnStyle.ghost ? null : [softShadow(edge.withValues(alpha: .35), 14, 8)],
              ),
              padding: EdgeInsets.only(bottom: lip),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
                  border: Border.all(color: Colors.white.withValues(alpha: widget.style == BtnStyle.soft ? .9 : .5), width: 2),
                ),
                child: Stack(children: [
                  // glossy highlight
                  Positioned(
                    left: r * .6,
                    right: r * .6,
                    top: 3,
                    height: widget.height * .34,
                    child: DecoratedBox(decoration: BoxDecoration(color: Colors.white.withValues(alpha: .32), borderRadius: BorderRadius.circular(r))),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (widget.icon != null) ...[Icon(widget.icon, color: fg, size: widget.fontSize + 4), const SizedBox(width: 8)],
                        Flexible(child: label),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
    return widget.width == null ? IntrinsicWidth(child: btn) : btn;
  }
}

/// Parchment / glass panel used instead of plain rectangular cards.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final Color? border;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.color = Colors.white, this.radius = 28, this.border});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border ?? Colors.white, width: 3),
          boxShadow: [softShadow(const Color(0x33101840), 22, 10)],
        ),
        child: Material(type: MaterialType.transparency, child: child), // ripples of switches/tiles show on the panel
      );
}

class SpeechBubble extends StatelessWidget {
  final String text;
  final bool tailLeft;
  final double maxWidth;
  final double fontSize;
  const SpeechBubble({super.key, required this.text, this.tailLeft = true, this.maxWidth = 320, this.fontSize = 20});
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomRight: Radius.circular(tailLeft ? 24 : 6),
            bottomLeft: Radius.circular(tailLeft ? 6 : 24),
          ),
          boxShadow: [softShadow(const Color(0x33101840), 16, 6)],
        ),
        child: Text(text, style: ts(fontSize, color: C.ink, h: 1.25)),
      ),
    );
  }
}

/// The fox (or chosen companion) — idles gently, blinks, wags its tail.
class Companion extends StatefulWidget {
  final int type;
  final double size;
  final String? message;
  final bool bubbleRight; // bubble to the right of creature
  final bool vertical;
  final String? speakLocale; // when set, speaks the message
  final bool happy;
  const Companion({
    super.key,
    this.type = 0,
    this.size = 120,
    this.message,
    this.bubbleRight = true,
    this.vertical = false,
    this.speakLocale,
    this.happy = true,
  });
  @override
  State<Companion> createState() => _CompanionState();
}

class _CompanionState extends State<Companion> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  bool _blink = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) async {
      if (!mounted) return;
      setState(() => _blink = true);
      await Future.delayed(const Duration(milliseconds: 140));
      if (mounted) setState(() => _blink = false);
    });
    _maybeSpeak();
  }

  @override
  void didUpdateWidget(Companion old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message) _maybeSpeak();
  }

  void _maybeSpeak() {
    if (widget.speakLocale != null && widget.message != null) {
      Speaker.instance.speak(widget.message!, widget.speakLocale!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creature = AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, sin(_c.value * pi) * -4),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(painter: CreaturePainter(widget.type, wag: _c.value * 2 - 1, blink: _blink, happy: widget.happy)),
        ),
      ),
    );
    final bubble = widget.message == null
        ? null
        : GestureDetector(
            onTap: widget.speakLocale == null ? null : _maybeSpeak,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(key: ValueKey(widget.message), child: SpeechBubble(text: widget.message!, tailLeft: widget.bubbleRight && !widget.vertical)),
            ),
          );
    if (bubble == null) return creature;
    if (widget.vertical) {
      return Column(mainAxisSize: MainAxisSize.min, children: [bubble, const SizedBox(height: 6), creature]);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: widget.bubbleRight ? [creature, const SizedBox(width: 6), Flexible(child: bubble)] : [Flexible(child: bubble), const SizedBox(width: 6), creature],
    );
  }
}

class GameProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const GameProgressBar({super.key, required this.value, this.color = C.green, this.height = 16});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .35), borderRadius: BorderRadius.circular(height)),
      child: LayoutBuilder(
        builder: (_, c) => Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: c.maxWidth * value.clamp(0, 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height),
              gradient: LinearGradient(colors: [color.withValues(alpha: .8), color]),
            ),
          ),
        ),
      ),
    );
  }
}

class StarChip extends StatelessWidget {
  final int stars;
  const StarChip(this.stars, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: C.ink.withValues(alpha: .85),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: C.gold, width: 2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text('$stars', key: ValueKey(stars), style: ts(20, color: Colors.white)),
          ),
        ]),
      );
}

/// Level shown as playful pips — never as a score.
class PowerPips extends StatelessWidget {
  final int level;
  final int max;
  final String emoji;
  const PowerPips({super.key, required this.level, this.max = 4, this.emoji = '⚡'});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= max; i++)
            AnimatedScale(
              scale: i <= level ? 1 : .8,
              duration: const Duration(milliseconds: 400),
              child: Opacity(opacity: i <= level ? 1 : .25, child: Text(emoji, style: const TextStyle(fontSize: 18))),
            ),
        ],
      );
}

/// Simple round icon button with a minimum 56px touch target.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final Color color;
  final double size;
  const RoundIconButton({super.key, required this.icon, required this.onTap, required this.label, this.color = Colors.white, this.size = 56});
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          // the touch area is never smaller than 48 dp (accessibility), even when the circle is drawn smaller
          child: SizedBox(
            width: max(size, 48),
            height: max(size, 48),
            child: Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [softShadow(const Color(0x33101840), 12, 5)],
                ),
                child: Icon(icon, color: C.purpleDark, size: size * .5),
              ),
            ),
          ),
        ),
      );
}

/// Soft entrance animation for lists / cards.
class Pop extends StatelessWidget {
  final Widget child;
  final int index;
  const Pop({super.key, required this.child, this.index = 0});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + index * 90),
        curve: Curves.easeOutBack,
        builder: (_, v, ch) => Opacity(opacity: v.clamp(0, 1), child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: ch)),
        child: child,
      );
}

Widget bandPill(String label, Color color, {double size = 15}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(20), border: Border.all(color: color, width: 1.8)),
      child: Text(label, style: ts(size, color: Color.lerp(color, Colors.black, .35)!, w: FontWeight.w800)),
    );
