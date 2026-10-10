import 'package:flutter/material.dart';
import '../../core/cloud.dart';
import '../../core/theme.dart';
import '../battery.dart';
import '../models.dart';

/// Shows, right after an answer, what the Question Agent did: "+10 new questions added to the database" with a few of them.
class AgentBanner extends StatelessWidget {
  const AgentBanner({super.key});

  static String preview(SItem q) {
    String cut(String s, int n) => s.length <= n ? s : '${s.substring(0, n - 1)}…';
    return switch (q.subtest) {
      'rhyme' => '${q.target} ↔ ${q.options.isEmpty ? '' : q.options.first.label}',
      'firstSound' => 'starts with “${q.target}”',
      'phonemeManip' => cut(q.say ?? '', 30),
      'letterSound' => '${q.say} → ${q.options.isEmpty ? '' : q.options.first.label}',
      'pictureNaming' => '${q.emoji ?? ''} ${q.target}',
      'wordReading' || 'nonwordReading' || 'spelling' => '${q.emoji ?? ''} ${q.target}'.trim(),
      _ => cut(q.passage ?? q.say ?? q.id, 30),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgentEvent?>(
      valueListenable: Cloud.instance.last,
      builder: (_, e, _) => AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: e == null ? const SizedBox(width: double.infinity) : Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 4), child: _card(e)),
      ),
    );
  }

  Widget _card(AgentEvent e) {
    final title = e.subtest.isEmpty ? '' : subtestById(e.subtest).t('en');
    switch (e.status) {
      case 'sending':
        return _shell(
          const Color(0xFF3B3F8F),
          Row(children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFFE17A))),
            const SizedBox(width: 10),
            Expanded(child: Text('☁️ Answer sent · 🧠 Question Agent is writing 10 new questions…', style: ts(13, color: Colors.white, w: FontWeight.w600))),
          ]),
        );
      case 'done':
        return _shell(
          const Color(0xFF1F7A4D),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🧠', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(child: Text('Question Agent added +${e.added} new questions', style: ts(16, color: const Color(0xFFFFE17A)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Text('bank ${e.bankBefore} → ${e.bankAfter}', style: ts(12, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 2),
            Text('$title · ${e.tier} pool · saved in the database${e.ms > 0 ? ' · ${(e.ms / 1000).toStringAsFixed(1)} s' : ''}', style: ts(11, color: Colors.white70, w: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(spacing: 5, runSpacing: 3, children: [
              for (final q in e.questions.take(4))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(9)),
                  child: Text(preview(q), style: ts(11, color: Colors.white, w: FontWeight.w600)),
                ),
              if (e.questions.length > 4) Text('+${e.questions.length - 4} more', style: ts(11, color: Colors.white70, w: FontWeight.w600)),
            ]),
          ]),
        );
      default:
        return _shell(const Color(0xFF5A5F7A), Text('📴 ${e.message}', style: ts(12, color: Colors.white, w: FontWeight.w600)));
    }
  }

  Widget _shell(Color c, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8C46A), width: 1.5)),
        child: child,
      );
}
