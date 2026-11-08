import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/auth/domain/app_user.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/campus/data/in_memory_campus_repository.dart';
import 'package:smart_campus_portal/features/campus/domain/campus_models.dart';
import 'package:smart_campus_portal/features/campus/domain/demo_data.dart';

AppUser user(
  UserRole role, {
  String id = 'hcu-student-001',
  String? department = 'Computer Science',
  int? level = 400,
}) =>
    AppUser(
      id: id,
      name: 'Test User',
      email: 'test@hcu.edu',
      role: role,
      department: department,
      level: level,
    );

void main() {
  late InMemoryCampusRepository repo;

  setUp(() => repo = InMemoryCampusRepository());

  group('demo data', () {
    final data = DemoData.build(
      lecturerId: 'lec-1',
      lecturerName: 'Lecturer',
      students: const [DemoStudent('s1', 'Ada'), DemoStudent('s2', 'Bayo')],
      now: DateTime(2026, 10, 22),
    );

    test('has the expected amount of sample data', () {
      expect(data.campuses, hasLength(2));
      expect(data.slots, hasLength(5));
      expect(data.enrollments, hasLength(10)); // 2 students x 5 courses
      expect(data.notices, hasLength(9));
    });

    test('ids are unique so loading it twice never duplicates', () {
      expect(data.slots.map((s) => s.id).toSet(), hasLength(5));
      expect(data.enrollments.map((e) => e.id).toSet(), hasLength(10));
    });

    test('every class has a hall and a known campus', () {
      final campusIds = data.campuses.map((c) => c.id).toSet();
      for (final s in data.slots) {
        expect(s.hallName, isNotEmpty);
        expect(campusIds, contains(s.campusId));
        expect(s.lecturerId, 'lec-1');
      }
    });

    test('includes notices targeted to one department and level', () {
      final targeted = data.notices.where((n) => n.department != null);

      expect(targeted, hasLength(2));
      expect(targeted.every((n) => n.level != null), isTrue);
    });

    test('events are in the future and have a date', () {
      final events =
          data.notices.where((n) => n.category == NoticeCategory.event);
      expect(events, isNotEmpty);
      for (final e in events) {
        expect(e.eventDate!.isAfter(DateTime(2026, 10, 22)), isTrue);
      }
    });
  });

  group('timetable visibility (access control)', () {
    Future<List<ClassSlot>> slotsFor(AppUser u) =>
        repo.watchTimetable(u).first;

    test('a student sees their own department and level', () async {
      expect(await slotsFor(user(UserRole.student)), hasLength(5));
    });

    test('a student in another level sees nothing', () async {
      expect(await slotsFor(user(UserRole.student, level: 300)), isEmpty);
    });

    test('a student with no department sees nothing', () async {
      expect(
        await slotsFor(user(UserRole.student, department: null, level: null)),
        isEmpty,
      );
    });

    test('a course rep sees the class timetable like a student', () async {
      expect(await slotsFor(user(UserRole.courseRep)), hasLength(5));
    });

    test('a lecturer sees only classes they teach', () async {
      final mine = user(UserRole.lecturer, id: 'hcu-lecturer-001');
      final other = user(UserRole.lecturer, id: 'someone-else');

      expect(await slotsFor(mine), hasLength(5));
      expect(await slotsFor(other), isEmpty);
    });

    test('an admin sees everything; bursar and aspirant see nothing', () async {
      expect(await slotsFor(user(UserRole.admin)), hasLength(5));
      expect(await slotsFor(user(UserRole.bursar)), isEmpty);
      expect(await slotsFor(user(UserRole.aspirant)), isEmpty);
    });
  });

  group('enrolments (a lecturer sees only their own students)', () {
    test('the course lecturer sees all enrolments', () async {
      final lecturer = user(UserRole.lecturer, id: 'hcu-lecturer-001');

      expect(await repo.watchEnrollments(lecturer).first, hasLength(10));
    });

    test('another lecturer sees none', () async {
      final other = user(UserRole.lecturer, id: 'someone-else');

      expect(await repo.watchEnrollments(other).first, isEmpty);
    });
  });

  group('notices', () {
    test('a published notice reaches listeners in real time, newest first',
        () async {
      final stream = repo.watchNotices();
      final seen = expectLater(
        stream,
        emitsThrough(predicate<List<Notice>>(
          (list) => list.isNotEmpty && list.first.title == 'Exam timetable released',
        )),
      );

      await repo.publishNotice(
        title: 'Exam timetable released',
        body: 'See the notice board.',
        category: NoticeCategory.notice,
        authorName: 'Admin',
      );

      await seen;
    });

    test('an event keeps its date', () async {
      final date = DateTime(2026, 12, 5);
      await repo.publishNotice(
        title: 'Convocation',
        body: 'Main Campus field.',
        category: NoticeCategory.event,
        eventDate: date,
        authorName: 'Admin',
      );

      final first = (await repo.watchNotices().first).first;
      expect(first.eventDate, date);
    });

    test('a deleted notice disappears', () async {
      await repo.publishNotice(
        title: 'Temporary',
        body: 'x',
        category: NoticeCategory.notice,
        authorName: 'Admin',
      );
      final added = (await repo.watchNotices().first).first;

      await repo.deleteNotice(added.id);

      final after = await repo.watchNotices().first;
      expect(after.any((n) => n.id == added.id), isFalse);
    });

    test('loading demo data restores the sample notices', () async {
      for (final n in await repo.watchNotices().first) {
        await repo.deleteNotice(n.id);
      }
      expect(await repo.watchNotices().first, isEmpty);

      await repo.seedDemoData();

      expect(await repo.watchNotices().first, hasLength(9));
    });
  });

  test('an admin can change a user role', () async {
    await repo.updateUserRole('hcu-student-001', UserRole.lecturer);

    final users = await repo.watchUsers().first;
    expect(users.firstWhere((u) => u.id == 'hcu-student-001').role,
        UserRole.lecturer);
  });
}
