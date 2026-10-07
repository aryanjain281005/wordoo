import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Light grown-up gate so children don't wander into the report by accident.
Future<bool> askParentGate(BuildContext context) async {
  final rng = Random();
  final a = 4 + rng.nextInt(5), b = 3 + rng.nextInt(6);
  final ctrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Panel(
        color: const Color(0xFFFFF9E8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Grown-ups only', style: ts(26)),
          const SizedBox(height: 8),
          Text('What is $a + $b ?', style: ts(22, color: C.purple)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: ts(26),
            decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))),
            onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v.trim()) == a + b),
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            BigButton(label: 'Back', style: BtnStyle.soft, height: 52, fontSize: 18, onTap: () => Navigator.pop(ctx, false)),
            const SizedBox(width: 12),
            BigButton(label: 'Open', height: 52, fontSize: 18, onTap: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim()) == a + b)),
          ]),
        ]),
      )),
    ),
  );
  return ok ?? false;
}
