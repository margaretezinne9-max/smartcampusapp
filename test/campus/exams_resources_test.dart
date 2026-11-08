import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/auth/domain/app_user.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/campus/data/in_memory_campus_repository.dart';
import 'package:smart_campus_portal/features/campus/domain/campus_models.dart';

AppUser user(
  UserRole role, {
  String id = 'hcu-student-001',
  String? department = 'Computer Science',
  int? level = 400,
}) =>
    AppUser(
      id: id,
      name: 'Test ${role.label}',
      email: 'test@hcu.edu',
      role: role,
      department: department,
      level: level,
    );

void main() {
  late InMemoryCampusRepository repo;
  final lecturer = user(UserRole.lecturer, id: 'hcu-lecturer-001');

  setUp(() => repo = InMemoryCampusRepository());

  group('exams', () {
    test('a student sees the exams of their department and level', () async {
      expect(await repo.watchExams(user(UserRole.student)).first, hasLength(5));
      expect(
        await repo.watchExams(user(UserRole.student, level: 300)).first,
        isEmpty,
      );
    });

    test('a lecturer sees only the exams of their courses', () async {
      expect(await repo.watchExams(lecturer).first, hasLength(5));
      expect(
        await repo.watchExams(user(UserRole.lecturer, id: 'someone-else')).first,
        isEmpty,
      );
    });

    test('an admin sees all exams; a bursar and an aspirant see none', () async {
      expect(await repo.watchExams(user(UserRole.admin)).first, hasLength(5));
      expect(await repo.watchExams(user(UserRole.bursar)).first, isEmpty);
      expect(await repo.watchExams(user(UserRole.aspirant)).first, isEmpty);
    });

    test('demo exams are in the future and have a duration and a place', () async {
      final exams = await repo.watchExams(user(UserRole.admin)).first;

      for (final e in exams) {
        expect(e.start.isAfter(DateTime.now()), isTrue);
        expect(e.durationMinutes, greaterThan(0));
        expect(e.hallName, isNotEmpty);
        expect(e.end.isAfter(e.start), isTrue);
      }
    });

    test('an exam added by the admin reaches students at once', () async {
      final course = (await repo.watchTimetable(user(UserRole.admin)).first).first;
      final seen = expectLater(
        repo.watchExams(user(UserRole.student)),
        emitsThrough(predicate<List<Exam>>((l) => l.length == 6)),
      );

      await repo.addExam(Exam(
        id: '',
        courseCode: course.courseCode,
        courseTitle: course.courseTitle,
        lecturerId: course.lecturerId,
        department: course.department,
        level: course.level,
        start: DateTime.now().add(const Duration(days: 60)),
        durationMinutes: 90,
        hallName: 'Hall X',
        campusId: course.campusId,
        campusName: course.campusName,
      ));

      await seen;
    });

    test('a deleted exam disappears', () async {
      final exams = await repo.watchExams(user(UserRole.admin)).first;

      await repo.deleteExam(exams.first.id);

      expect(await repo.watchExams(user(UserRole.admin)).first, hasLength(4));
    });
  });

  group('resources', () {
    Future<ClassSlot> csc401() async => (await repo.watchTimetable(lecturer).first)
        .firstWhere((s) => s.courseCode == 'CSC 401');

    test('a student sees the resources of their department and level', () async {
      final resources = await repo.watchResources(user(UserRole.student)).first;

      expect(resources, hasLength(4));
      expect(resources.map((r) => r.type), contains(ResourceType.pastQuestions));
    });

    test('a student of another level sees none', () async {
      expect(
        await repo.watchResources(user(UserRole.student, level: 100)).first,
        isEmpty,
      );
    });

    test('a lecturer shares a link and students see it first', () async {
      await repo.addResource(
        lecturer: lecturer,
        course: await csc401(),
        title: 'Chapter 3 slides',
        url: 'https://example.com/ch3',
        type: ResourceType.notes,
      );

      final resources = await repo.watchResources(user(UserRole.student)).first;
      expect(resources.first.title, 'Chapter 3 slides');
      expect(resources.first.lecturerName, lecturer.name);
      expect(resources.first.courseCode, 'CSC 401');
    });

    test('a link that is not https is rejected', () async {
      expect(
        () async => repo.addResource(
          lecturer: lecturer,
          course: await csc401(),
          title: 'Insecure',
          url: 'http://example.com/x',
          type: ResourceType.other,
        ),
        throwsArgumentError,
      );
    });

    test('an empty title is rejected', () async {
      expect(
        () async => repo.addResource(
          lecturer: lecturer,
          course: await csc401(),
          title: '   ',
          url: 'https://example.com/x',
          type: ResourceType.other,
        ),
        throwsArgumentError,
      );
    });

    test("a lecturer cannot share for someone else's course", () async {
      final other = user(UserRole.lecturer, id: 'someone-else');

      expect(
        () async => repo.addResource(
          lecturer: other,
          course: await csc401(),
          title: 'Sneaky',
          url: 'https://example.com/x',
          type: ResourceType.notes,
        ),
        throwsStateError,
      );
    });

    test('a deleted resource disappears', () async {
      final first = (await repo.watchResources(lecturer).first).first;

      await repo.deleteResource(first.id);

      final after = await repo.watchResources(lecturer).first;
      expect(after.any((r) => r.id == first.id), isFalse);
    });

    test('isValidResourceUrl accepts only secure web links', () {
      expect(isValidResourceUrl('https://drive.google.com/file/d/abc'), isTrue);
      expect(isValidResourceUrl('http://example.com'), isFalse);
      expect(isValidResourceUrl('javascript:alert(1)'), isFalse);
      expect(isValidResourceUrl('https://'), isFalse);
      expect(isValidResourceUrl('not a link'), isFalse);
    });
  });
}
