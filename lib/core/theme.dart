import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

class C {
  static const ink = Color(0xFF1E2753);
  static const inkSoft = Color(0xFF4A5380);
  static const purple = Color(0xFF6C4DF0);
  static const purpleDark = Color(0xFF4A32C7);
  static const orange = Color(0xFFFF9A2E);
  static const orangeDark = Color(0xFFE17A0F);
  static const green = Color(0xFF34B36B);
  static const greenDark = Color(0xFF218A4F);
  static const sky = Color(0xFF58B7FF);
  static const cream = Color(0xFFFFF6E0);
  static const parchment = Color(0xFFF8E7BD);
  static const parchmentDark = Color(0xFFD9B56B);
  static const night = Color(0xFF141B45);
  static const pink = Color(0xFFFF6FA5);
  static const gold = Color(0xFFFFC83D);
  static const fox = Color(0xFFF58A2B);
}

class AppTheme {
  static ThemeData build({bool extraSpacing = false, bool highContrast = false}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: C.purple, brightness: Brightness.light),
      scaffoldBackgroundColor: C.night,
    );
    final ls = extraSpacing ? 0.8 : 0.0;
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink, fontFamily: 'Fredoka', fontFamilyFallback: const [
        'NotoSansDevanagari',
        'Noto Sans Devanagari',
        'Kohinoor Devanagari',
        'Devanagari Sangam MN',
        'sans-serif',
      ]).copyWith(
        bodyMedium: TextStyle(letterSpacing: ls, height: extraSpacing ? 1.5 : 1.3),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      }),
    );
  }
}

TextStyle ts(double size, {Color color = C.ink, FontWeight w = FontWeight.w700, double? h, double? ls}) => TextStyle(
      fontFamily: 'Fredoka',
      fontFamilyFallback: const ['NotoSansDevanagari'],
      fontVariations: [FontVariation('wght', (w.value >= 700 ? 600 : w.value.clamp(300, 600)).toDouble())],
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w400,
      height: h,
      letterSpacing: ls,
    );

/// Chunky outlined title text like the reference ("You Did It!", logo).
Widget outlinedText(String t, double size, {Color fill = Colors.white, Color stroke = const Color(0xFF3B2A8F), TextAlign align = TextAlign.center}) => Stack(children: [
      Text(t, textAlign: align, style: ts(size, w: FontWeight.w700).copyWith(foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * .22
        ..strokeJoin = StrokeJoin.round
        ..color = stroke)),
      Text(t, textAlign: align, style: ts(size, color: fill, w: FontWeight.w700)),
    ]);

BoxShadow softShadow([Color c = const Color(0x33000000), double blur = 18, double dy = 8]) =>
    BoxShadow(color: c, blurRadius: blur, offset: Offset(0, dy));
