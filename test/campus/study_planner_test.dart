import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/campus/domain/campus_models.dart';
import 'package:smart_campus_portal/features/campus/domain/study_planner.dart';

Exam exam(String code, DateTime start) => Exam(
      id: code,
      courseCode: code,
      courseTitle: 'Title $code',
      lecturerId: 'lec-1',
      department: 'Computer Science',
      level: 400,
      start: start,
      durationMinutes: 120,
      hallName: 'Hall 1',
      campusId: 'main',
      campusName: 'Main Campus',
    );

Map<DateTime, int> minutesPerDate(List<StudyBlock> plan) {
  final totals = <DateTime, int>{};
  for (final b in plan) {
    totals[b.date] = (totals[b.date] ?? 0) + b.minutes;
  }
  return totals;
}

void main() {
  // Monday 26 Oct 2026, 10:00.
  final now = DateTime(2026, 10, 26, 10);

  test('no exams means no plan', () {
    expect(buildStudyPlan(exams: const [], now: now, minutesPerDay: 120), isEmpty);
  });

  test('less than one block of study time per day means no plan', () {
    final plan = buildStudyPlan(
      exams: [exam('A', DateTime(2026, 10, 31, 9))],
      now: now,
      minutesPerDay: 10,
    );

    expect(plan, isEmpty);
  });

  test('one exam: every day before it is a full study day, the exam day is not', () {
    final plan = buildStudyPlan(
      exams: [exam('A', DateTime(2026, 10, 31, 9))],
      now: now,
      minutesPerDay: 120,
    );

    expect(plan, hasLength(5)); // 26, 27, 28, 29, 30 October
    expect(plan.every((b) => b.minutes == 120), isTrue);
    expect(plan.any((b) => b.date == DateTime(2026, 10, 31)), isFalse);
  });

  test('the closer exam gets the bigger share of the day', () {
    final plan = buildStudyPlan(
      exams: [
        exam('NEAR', DateTime(2026, 10, 28, 9)),
        exam('FAR', DateTime(2026, 11, 5, 9)),
      ],
      now: now,
      minutesPerDay: 120,
    );

    final today = plan.where((b) => b.date == DateTime(2026, 10, 26)).toList();
    final near = today.firstWhere((b) => b.exam.courseCode == 'NEAR');
    final far = today.firstWhere((b) => b.exam.courseCode == 'FAR');
    expect(near.minutes, 105);
    expect(far.minutes, 15);
  });

  test('every study day uses exactly the time the student has', () {
    final plan = buildStudyPlan(
      exams: [
        exam('A', DateTime(2026, 10, 29, 9)),
        exam('B', DateTime(2026, 11, 3, 9)),
        exam('C', DateTime(2026, 11, 9, 9)),
      ],
      now: now,
      minutesPerDay: 180,
    );

    expect(minutesPerDate(plan).values.every((m) => m == 180), isTrue);
  });

  test('after one exam is over, all the time goes to the remaining exam', () {
    final plan = buildStudyPlan(
      exams: [
        exam('A', DateTime(2026, 10, 28, 9)),
        exam('B', DateTime(2026, 11, 5, 9)),
      ],
      now: now,
      minutesPerDay: 120,
    );

    final examDay = plan.where((b) => b.date == DateTime(2026, 10, 28)).toList();
    expect(examDay, hasLength(1));
    expect(examDay.single.exam.courseCode, 'B');
    expect(examDay.single.minutes, 120);
  });

  test('exams that already started are ignored', () {
    final plan = buildStudyPlan(
      exams: [exam('OLD', DateTime(2026, 10, 26, 8))],
      now: now,
      minutesPerDay: 120,
    );

    expect(plan, isEmpty);
  });

  test('blocks in a day are listed with the soonest exam first', () {
    final plan = buildStudyPlan(
      exams: [
        exam('FAR', DateTime(2026, 11, 5, 9)),
        exam('NEAR', DateTime(2026, 10, 28, 9)),
      ],
      now: now,
      minutesPerDay: 120,
    );

    final today = plan.where((b) => b.date == DateTime(2026, 10, 26)).toList();
    expect(today.first.exam.courseCode, 'NEAR');
  });
}
