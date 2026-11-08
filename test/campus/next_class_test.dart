import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/campus/domain/campus_models.dart';
import 'package:smart_campus_portal/features/campus/domain/next_class.dart';

ClassSlot slot(String code, int weekday, int startHour, int endHour) => ClassSlot(
      id: code,
      courseCode: code,
      courseTitle: 'Test course',
      lecturerId: 'lec-1',
      lecturerName: 'Lecturer',
      department: 'Computer Science',
      level: 400,
      weekday: weekday,
      startMinute: startHour * 60,
      endMinute: endHour * 60,
      hallName: 'Hall 1',
      campusId: 'main',
      campusName: 'Main Campus',
    );

void main() {
  // Reference week: Monday 26 Oct 2026 ... Sunday 1 Nov 2026.
  final monday = slot('MON', DateTime.monday, 8, 10);
  final wednesday = slot('WED', DateTime.wednesday, 12, 14);
  final slots = [monday, wednesday];

  test('returns null when there are no classes', () {
    expect(findNextClass(const [], DateTime(2026, 10, 26, 7)), isNull);
  });

  test('before a class on the same day, that class is next', () {
    final now = DateTime(2026, 10, 26, 7);
    final next = findNextClass(slots, now)!;

    expect(next.slot.courseCode, 'MON');
    expect(next.start, DateTime(2026, 10, 26, 8));
    expect(next.isOngoingAt(now), isFalse);
    expect(next.untilStart(now), const Duration(hours: 1));
  });

  test('a class in progress counts as next and is ongoing', () {
    final now = DateTime(2026, 10, 26, 9);
    final next = findNextClass(slots, now)!;

    expect(next.slot.courseCode, 'MON');
    expect(next.isOngoingAt(now), isTrue);
    expect(next.end, DateTime(2026, 10, 26, 10));
  });

  test('at the exact end time the class is over and the next one is chosen', () {
    final next = findNextClass(slots, DateTime(2026, 10, 26, 10))!;

    expect(next.slot.courseCode, 'WED');
    expect(next.start, DateTime(2026, 10, 28, 12));
  });

  test('picks the earliest upcoming class among several', () {
    final next = findNextClass(slots, DateTime(2026, 10, 27, 9))!;

    expect(next.slot.courseCode, 'WED');
  });

  test('after the last class of the week it wraps to next Monday', () {
    final next = findNextClass(slots, DateTime(2026, 10, 28, 14, 30))!;

    expect(next.slot.courseCode, 'MON');
    expect(next.start, DateTime(2026, 11, 2, 8));
  });

  test('works across a month boundary (Sunday -> Monday)', () {
    final next = findNextClass(slots, DateTime(2026, 11, 1, 12))!;

    expect(next.slot.courseCode, 'MON');
    expect(next.start, DateTime(2026, 11, 2, 8));
  });

  test('a single class that already ended today moves to next week', () {
    final next = findNextClass([monday], DateTime(2026, 10, 26, 15))!;

    expect(next.start, DateTime(2026, 11, 2, 8));
  });

  test('skipOngoing ignores the class already in progress', () {
    final next =
        findNextClass(slots, DateTime(2026, 10, 26, 9), skipOngoing: true)!;

    expect(next.slot.courseCode, 'WED');
    expect(next.start, DateTime(2026, 10, 28, 12));
  });

  test('skipOngoing still returns a class that starts exactly now', () {
    final next =
        findNextClass(slots, DateTime(2026, 10, 26, 8), skipOngoing: true)!;

    expect(next.slot.courseCode, 'MON');
    expect(next.start, DateTime(2026, 10, 26, 8));
  });
}
