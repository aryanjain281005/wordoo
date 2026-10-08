import '../lib/content/en/en_pack.dart';
void main() {
  final p = EnglishGameContent();
  final w = p.words;
  final by = <int, List<String>>{};
  for (final e in w) { by.putIfAbsent(e.step, () => []).add(e.text); }
  print('total ${w.length}, with picture ${w.where((e) => e.emoji != null).length}');
  for (var s = 1; s <= 10; s++) { final l = by[s] ?? []; print('step $s: ${l.length} pics ${w.where((e)=>e.step==s && e.emoji!=null).length}  e.g. ${l.take(10).join(", ")}'); }
  for (final t in ['cat','ship','frog','cake','train','rabbit','elephant','strawberry','the','because','light','bridge','butterfly']) {
    final e = w.firstWhere((x) => x.text == t); print('$t ${e.units} syl${e.syllables} d=${e.difficulty.toStringAsFixed(1)} rime=${e.rime}');
  }
  print(p.nonwords(8, 5, 1).map((e)=>e.text)); print(p.nonwords(10, 5, 2).map((e)=>e.text));
}
