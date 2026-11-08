import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/auth/domain/app_user.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/campus/domain/campus_models.dart';
import 'package:smart_campus_portal/features/campus/domain/notice_logic.dart';

Notice notice(
  String id, {
  String? department,
  int? level,
  NoticeCategory category = NoticeCategory.notice,
  DateTime? eventDate,
}) =>
    Notice(
      id: id,
      title: id,
      body: 'Body',
      category: category,
      createdAt: DateTime(2026, 10, 1),
      authorName: 'Admin',
      eventDate: eventDate,
      department: department,
      level: level,
    );

AppUser user(UserRole role, {String? department, int? level}) => AppUser(
      id: 'u1',
      name: 'Test User',
      email: 'test@hcu.edu',
      role: role,
      department: department,
      level: level,
    );

void main() {
  final csStudent = user(UserRole.student, department: 'Computer Science', level: 400);

  group('who sees a notice', () {
    test('an untargeted notice is for everyone', () {
      final n = notice('all');
      for (final role in UserRole.values) {
        expect(noticeVisibleTo(n, user(role)), isTrue, reason: role.name);
      }
    });

    test('a department notice reaches only that department', () {
      final n = notice('cs', department: 'Computer Science');

      expect(noticeVisibleTo(n, csStudent), isTrue);
      expect(
        noticeVisibleTo(n, user(UserRole.student, department: 'Law', level: 400)),
        isFalse,
      );
      expect(noticeVisibleTo(n, user(UserRole.aspirant)), isFalse);
    });

    test('a level notice reaches only that level', () {
      final n = notice('l400', level: 400);

      expect(noticeVisibleTo(n, csStudent), isTrue);
      expect(
        noticeVisibleTo(
            n, user(UserRole.student, department: 'Computer Science', level: 300)),
        isFalse,
      );
    });

    test('a course rep follows the same rules as a student', () {
      final n = notice('cs400', department: 'Computer Science', level: 400);

      expect(
        noticeVisibleTo(
            n, user(UserRole.courseRep, department: 'Computer Science', level: 400)),
        isTrue,
      );
    });

    test('a lecturer matches on department but is never hidden by level', () {
      final lecturer = user(UserRole.lecturer, department: 'Computer Science');

      expect(noticeVisibleTo(notice('a', level: 100), lecturer), isTrue);
      expect(
        noticeVisibleTo(notice('b', department: 'Computer Science', level: 100), lecturer),
        isTrue,
      );
      expect(noticeVisibleTo(notice('c', department: 'Law'), lecturer), isFalse);
    });

    test('an admin sees every notice', () {
      final n = notice('law', department: 'Law', level: 100);

      expect(noticeVisibleTo(n, user(UserRole.admin)), isTrue);
    });

    test('visibleNotices keeps only the notices meant for the user', () {
      final list = [
        notice('all'),
        notice('cs400', department: 'Computer Science', level: 400),
        notice('law100', department: 'Law', level: 100),
      ];

      expect(visibleNotices(list, csStudent).map((n) => n.id), ['all', 'cs400']);
    });
  });

  group('upcomingEvents', () {
    final now = DateTime(2026, 10, 26, 10);

    test('keeps events from today on, soonest first', () {
      final events = [
        notice('later', category: NoticeCategory.event, eventDate: DateTime(2026, 11, 20)),
        notice('today', category: NoticeCategory.event, eventDate: DateTime(2026, 10, 26)),
        notice('soon', category: NoticeCategory.event, eventDate: DateTime(2026, 10, 30)),
      ];

      expect(upcomingEvents(events, now).map((n) => n.id), ['today', 'soon', 'later']);
    });

    test('drops past events', () {
      final past = notice('past',
          category: NoticeCategory.event, eventDate: DateTime(2026, 10, 25));

      expect(upcomingEvents([past], now), isEmpty);
    });

    test('drops events more than 90 days away', () {
      final far = notice('far',
          category: NoticeCategory.event, eventDate: DateTime(2027, 2, 1));

      expect(upcomingEvents([far], now), isEmpty);
      expect(upcomingEvents([far], now, withinDays: 200), hasLength(1));
    });

    test('ignores ordinary notices and events without a date', () {
      final plain = notice('plain', eventDate: DateTime(2026, 10, 28));
      final undated = notice('undated', category: NoticeCategory.event);

      expect(upcomingEvents([plain, undated], now), isEmpty);
    });
  });
}
