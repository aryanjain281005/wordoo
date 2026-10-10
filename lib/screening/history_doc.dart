import 'adaptive.dart';
import 'models.dart';

String _indicator(Indicator i) => switch (i) { Indicator.low => 'low_indicators', Indicator.some => 'some_indicators', Indicator.elevated => 'elevated_indicators' };

/// One finished screening (baseline or weekly check-in) as a single nested document for the `screenings` collection:
/// subtest scores, construct bands and the observation strings of the report, plus the path the adaptive screening took.
Map<String, dynamic> screeningDoc({
  required String studentId,
  required String childName,
  required ScreeningReport report,
  required bool baseline,
  List<TraceStep> trace = const [],
}) =>
    {
      'student_id': studentId,
      'child_name': childName,
      'grade_band': report.band == GradeBand.junior ? 'Junior' : 'Middle',
      'test_date': report.date.toUtc().toIso8601String(),
      'kind': baseline ? 'baseline' : 'weekly_check',
      'indicator': _indicator(report.indicator),
      'construct_scores': {
        for (final c in report.constructs) c.construct.name: {'percentile': c.percentile, 'band': c.band.name},
      },
      'observations': report.observations,
      'strengths': report.strengths,
      'needs': report.needs,
      'lang': report.lang,
      'form': report.pool,
      'minutes': report.minutes,
      'speech_available': report.speechAvailable,
      'subtests': [
        for (final s in report.subtests)
          {'id': s.id, 'construct': s.construct.name, 'accuracy': s.accuracy, 'rate': s.rate, 'percentile': s.percentile, 'band': s.band.name, 'items': s.items, 'measured': s.measured},
      ],
      'adaptive_trace': [for (final t in trace) t.toJson()],
    };
