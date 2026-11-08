import 'campus_models.dart';

/// Time to study one exam's course on one day.
class StudyBlock {
  const StudyBlock({
    required this.date,
    required this.exam,
    required this.minutes,
  });

  final DateTime date;
  final Exam exam;
  final int minutes;
}

/// Study time is handed out in blocks of this many minutes.
const studyChunkMinutes = 15;

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Builds a day-by-day study plan from today until the last exam.
///
/// Each day, [minutesPerDay] is shared between the exams that are still ahead.
/// The closer an exam, the bigger its share (weight = 1 / days left), so the
/// plan naturally shifts toward the next exam. An exam gets no study time on
/// its own exam day. Exams that already started are ignored.
List<StudyBlock> buildStudyPlan({
  required List<Exam> exams,
  required DateTime now,
  required int minutesPerDay,
}) {
  final upcoming = exams.where((e) => e.start.isAfter(now)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  if (upcoming.isEmpty || minutesPerDay < studyChunkMinutes) return const [];

  final lastDay = _dayOf(upcoming.last.start);
  final chunks = minutesPerDay ~/ studyChunkMinutes;
  final blocks = <StudyBlock>[];

  for (
    var day = _dayOf(now);
    !day.isAfter(lastDay);
    day = DateTime(day.year, day.month, day.day + 1)
  ) {
    // Exams whose exam day is still after this day.
    final open = upcoming.where((e) => _dayOf(e.start).isAfter(day)).toList();
    if (open.isEmpty) continue;

    final weights = [
      for (final e in open) 1 / _dayOf(e.start).difference(day).inDays,
    ];
    final totalWeight = weights.fold<double>(0, (a, b) => a + b);

    final shares = [
      for (final w in weights) (chunks * w / totalWeight).floor(),
    ];

    // Leftover blocks go to the most urgent exams first.
    var left = chunks - shares.fold<int>(0, (a, b) => a + b);
    final byUrgency = List<int>.generate(open.length, (i) => i)
      ..sort((a, b) => weights[b].compareTo(weights[a]));
    for (var i = 0; left > 0; i++, left--) {
      shares[byUrgency[i % byUrgency.length]]++;
    }

    for (var i = 0; i < open.length; i++) {
      if (shares[i] > 0) {
        blocks.add(
          StudyBlock(
            date: day,
            exam: open[i],
            minutes: shares[i] * studyChunkMinutes,
          ),
        );
      }
    }
  }
  return blocks;
}
