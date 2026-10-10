// Exports the screening questions that ship with the app to JSON, for the database seed:
//   dart run tool/export_bank.dart        ->  server/seed/questions_en.json   (then: cd server && npm run seed)
import 'dart:convert';
import 'dart:io';
import '../lib/screening/bank_en.dart';

void main() {
  final bank = EnglishScreenBank();
  final out = {
    'lang': 'en',
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'questions': [for (final i in bank.items) i.toJson()],
  };
  File('server/seed/questions_en.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(out));
  stdout.writeln('${bank.items.length} questions exported');
}
