import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/auth/domain/app_user.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/campus/data/in_memory_campus_repository.dart';
import 'package:smart_campus_portal/features/campus/domain/campus_models.dart';
import 'package:smart_campus_portal/features/student/domain/results_from_enrollments.dart';

AppUser user(UserRole role, String id) => AppUser(
      id: id,
      name: 'Test ${role.label}',
      email: 'test@hcu.edu',
      role: role,
    );

Enrollment enrollment(String code, int units, int? score) => Enrollment(
      id: code,
      studentId: 's1',
      studentName: 'Ada',
      courseCode: code,
      courseTitle: 'Title $code',
      lecturerId: 'l1',
      units: units,
      score: score,
    );

void main() {
  final lecturer = user(UserRole.lecturer, 'hcu-lecturer-001');
  final student = user(UserRole.student, 'hcu-student-001');

  late InMemoryCampusRepository repo;
  setUp(() => repo = InMemoryCampusRepository());

  group('who sees which enrolments', () {
    test('a student sees their own courses', () async {
      final mine = await repo.watchMyEnrollments(student).first;

      expect(mine, hasLength(5));
      expect(mine.every((e) => e.studentId == student.id), isTrue);
    });

    test('a course rep sees only their own, not the student\'s', () async {
      final rep = user(UserRole.courseRep, 'hcu-courseRep-001');

      final mine = await repo.watchMyEnrollments(rep).first;

      expect(mine, hasLength(5));
      expect(mine.every((e) => e.studentId == rep.id), isTrue);
    });

    test('someone not enrolled sees nothing', () async {
      expect(
        await repo.watchMyEnrollments(user(UserRole.student, 'other')).first,
        isEmpty,
      );
    });

    test('demo enrolments carry the credit units of each course', () async {
      final mine = await repo.watchMyEnrollments(student).first;

      expect(mine.firstWhere((e) => e.courseCode == 'CSC 499').units, 6);
      expect(mine.firstWhere((e) => e.courseCode == 'GST 401').units, 2);
      expect(mine.firstWhere((e) => e.courseCode == 'CSC 401').units, 3);
    });
  });

  group('entering scores', () {
    Future<String> idOf(String code) async =>
        (await repo.watchMyEnrollments(student).first)
            .firstWhere((e) => e.courseCode == code)
            .id;

    test('a lecturer enters a score and the student sees it', () async {
      await repo.setScore(
        lecturer: lecturer,
        enrollmentId: await idOf('CSC 401'),
        score: 72,
      );

      final mine = await repo.watchMyEnrollments(student).first;
      expect(mine.firstWhere((e) => e.courseCode == 'CSC 401').score, 72);
      expect(mine.where((e) => e.score != null), hasLength(1));
    });

    test('the lecturer sees the score in their own list too', () async {
      await repo.setScore(
        lecturer: lecturer,
        enrollmentId: await idOf('CSC 403'),
        score: 55,
      );

      final theirs = await repo.watchEnrollments(lecturer).first;
      expect(
        theirs.where((e) => e.id == 'hcu-student-001_CSC403').single.score,
        55,
      );
    });

    test('a score can be cleared with null', () async {
      final id = await idOf('CSC 401');
      await repo.setScore(lecturer: lecturer, enrollmentId: id, score: 72);

      await repo.setScore(lecturer: lecturer, enrollmentId: id, score: null);

      final mine = await repo.watchMyEnrollments(student).first;
      expect(mine.firstWhere((e) => e.id == id).score, isNull);
    });

    test('the boundary scores 0 and 100 are accepted', () async {
      final id = await idOf('CSC 401');

      await repo.setScore(lecturer: lecturer, enrollmentId: id, score: 0);
      await repo.setScore(lecturer: lecturer, enrollmentId: id, score: 100);

      final mine = await repo.watchMyEnrollments(student).first;
      expect(mine.firstWhere((e) => e.id == id).score, 100);
    });

    test('a score outside 0 to 100 is rejected', () async {
      final id = await idOf('CSC 401');

      expect(
        () => repo.setScore(lecturer: lecturer, enrollmentId: id, score: 101),
        throwsArgumentError,
      );
      expect(
        () => repo.setScore(lecturer: lecturer, enrollmentId: id, score: -1),
        throwsArgumentError,
      );
    });

    test("a lecturer cannot grade another lecturer's course", () async {
      final other = user(UserRole.lecturer, 'someone-else');

      expect(
        () async => repo.setScore(
          lecturer: other,
          enrollmentId: await idOf('CSC 401'),
          score: 60,
        ),
        throwsStateError,
      );
    });

    test('an unknown enrolment is rejected', () async {
      expect(
        () => repo.setScore(lecturer: lecturer, enrollmentId: 'nope', score: 60),
        throwsStateError,
      );
    });

    test('isValidScore accepts whole numbers from 0 to 100', () {
      expect(isValidScore(0), isTrue);
      expect(isValidScore(100), isTrue);
      expect(isValidScore(101), isFalse);
      expect(isValidScore(-1), isFalse);
    });
  });

  group('resultsFromEnrollments', () {
    test('no scores means no results', () {
      expect(
        resultsFromEnrollments([enrollment('A 1', 3, null), enrollment('B 2', 3, null)]),
        isEmpty,
      );
    });

    test('only graded courses count, sorted by course code', () {
      final results = resultsFromEnrollments([
        enrollment('B 2', 3, 58),
        enrollment('A 1', 3, 72),
        enrollment('C 3', 3, null),
      ]);

      expect(results, hasLength(1));
      expect(results.single.label, 'Current semester');
      expect(results.single.grades.map((g) => g.code), ['A 1', 'B 2']);
    });

    test('the GPA uses the credit units of each course', () {
      // A (5 points) x 3 units + C (3 points) x 3 units = 24 / 6 = 4.0
      final equal = resultsFromEnrollments([
        enrollment('A 1', 3, 72),
        enrollment('B 2', 3, 58),
      ]);
      expect(equal.single.gpa, closeTo(4.0, 0.001));

      // A (5) x 6 units + E (1) x 3 units = 33 / 9 = 3.667
      final weighted = resultsFromEnrollments([
        enrollment('A 1', 6, 80),
        enrollment('B 2', 3, 40),
      ]);
      expect(weighted.single.gpa, closeTo(3.667, 0.001));
    });

    test('a failed course is kept and lowers the GPA', () {
      final results = resultsFromEnrollments([
        enrollment('A 1', 3, 72),
        enrollment('B 2', 3, 30),
      ]);

      expect(results.single.grades.last.passed, isFalse);
      expect(results.single.gpa, closeTo(2.5, 0.001)); // (15 + 0) / 6
    });
  });
}
