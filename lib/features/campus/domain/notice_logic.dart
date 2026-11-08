import '../../../core/format.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import 'campus_models.dart';

/// Departments and levels an admin can target a notice to.
abstract final class CampusRules {
  static const departments = [
    'Computer Science',
    'Accounting',
    'Law',
    'Nursing Science',
    'Mechanical Engineering',
    'Mass Communication',
  ];

  static const levels = [100, 200, 300, 400, 500];
}

/// Whether [user] should see [notice].
///
/// - A notice with no department and no level is for everyone.
/// - A department target needs the same department.
/// - A level target needs the same level. Lecturers teach several levels, so
///   a level target never hides a notice from them.
/// - Admins see everything.
///
/// This is a display filter, not a security boundary: notices are not secret.
bool noticeVisibleTo(Notice notice, AppUser user) {
  if (user.role == UserRole.admin) return true;

  final department = notice.department;
  if (department != null && user.department != department) return false;

  final level = notice.level;
  if (level != null && user.role != UserRole.lecturer && user.level != level) {
    return false;
  }
  return true;
}

List<Notice> visibleNotices(Iterable<Notice> notices, AppUser user) =>
    notices.where((n) => noticeVisibleTo(n, user)).toList();

/// Events happening from today up to [withinDays] days ahead, soonest first.
List<Notice> upcomingEvents(
  Iterable<Notice> notices,
  DateTime now, {
  int withinDays = 90,
}) {
  final events = notices.where((n) {
    final date = n.eventDate;
    if (n.category != NoticeCategory.event || date == null) return false;
    final days = daysUntil(date, now);
    return days >= 0 && days <= withinDays;
  }).toList()..sort((a, b) => a.eventDate!.compareTo(b.eventDate!));
  return events;
}
