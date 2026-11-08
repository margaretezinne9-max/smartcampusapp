import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/student/data/mock_student_repository.dart';
import 'package:smart_campus_portal/features/student/domain/student_models.dart';

CourseGrade grade(int score, {int units = 3}) =>
    CourseGrade(code: 'TST 101', title: 'Test', units: units, score: score);

void main() {
  group('grade boundaries (5-point scale)', () {
    const expected = {
      100: 'A', 70: 'A',
      69: 'B', 60: 'B',
      59: 'C', 50: 'C',
      49: 'D', 45: 'D',
      44: 'E', 40: 'E',
      39: 'F', 0: 'F',
    };

    expected.forEach((score, letter) {
      test('score $score is grade $letter', () {
        expect(grade(score).grade, letter);
      });
    });

    test('40 passes and 39 fails', () {
      expect(grade(40).passed, isTrue);
      expect(grade(39).passed, isFalse);
    });
  });

  group('GPA', () {
    test('is weighted by course units', () {
      // A (5) x 3 units + C (3) x 3 units = 24 points over 6 units
      final semester = SemesterResult(
        session: '2025/2026',
        semester: 'First Semester',
        grades: [grade(75), grade(55)],
      );

      expect(semester.totalUnits, 6);
      expect(semester.gpa, closeTo(4.0, 0.001));
    });

    test('is zero for a semester with no grades', () {
      const empty = SemesterResult(
        session: '2025/2026',
        semester: 'First Semester',
        grades: [],
      );

      expect(empty.gpa, 0);
    });

    test('CGPA weights every unit across semesters', () {
      // Semester 1: one 3-unit A  -> 15 points
      // Semester 2: one 2-unit C  ->  6 points
      // CGPA = 21 / 5 units = 4.2
      final results = [
        SemesterResult(
            session: 'a', semester: '1', grades: [grade(80, units: 3)]),
        SemesterResult(
            session: 'a', semester: '2', grades: [grade(55, units: 2)]),
      ];

      expect(results.cgpa, closeTo(4.2, 0.001));
    });

    test('CGPA of no results is zero', () {
      expect(<SemesterResult>[].cgpa, 0);
    });
  });

  group('MockStudentRepository', () {
    final repo = MockStudentRepository();

    test('returns the current courses', () async {
      final courses = await repo.currentCourses('student-1');

      expect(courses, isNotEmpty);
      expect(courses.every((c) => c.units > 0), isTrue);
    });

    test('returns results with the newest semester first', () async {
      final results = await repo.results('student-1');

      expect(results.first.label, '2025/2026 Second Semester');
      expect(results.cgpa, inInclusiveRange(0, 5));
    });
  });
}
