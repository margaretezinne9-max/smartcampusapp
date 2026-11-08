import 'package:flutter/material.dart';

import '../auth/domain/app_user.dart';
import '../auth/domain/user_role.dart';
import '../feedback/feedback_tabs.dart';
import '../student/student_tabs.dart';
import 'campus_service.dart';
import 'presentation/admin_home_page.dart';
import 'presentation/campus_home_page.dart';
import 'presentation/exams_admin_page.dart';
import 'presentation/events_page.dart';
import 'presentation/exams_page.dart';
import 'presentation/notices_page.dart';
import 'presentation/resources_page.dart';
import 'presentation/students_page.dart';
import 'presentation/timetable_page.dart';
import 'presentation/users_page.dart';

// Builders used by RoleRegistry. Each receives the signed-in user.

/// Home for students, course reps and lecturers. Less-used screens are
/// shortcuts here because the bottom bar holds at most 5 tabs.
Widget buildCampusHome(AppUser user) {
  final isStudent = user.role == UserRole.student;
  final isStudentLike = isStudent || user.role == UserRole.courseRep;

  return CampusHomePage(
    user: user,
    repository: campusRepository,
    shortcuts: [
      HomeShortcut(
        label: 'Campus events',
        icon: Icons.celebration_outlined,
        pageBuilder: () => EventsPage(user: user, repository: campusRepository),
      ),
      HomeShortcut(
        label: 'All notices',
        icon: Icons.campaign_outlined,
        pageBuilder: () =>
            NoticesPage(user: user, repository: campusRepository),
      ),
      HomeShortcut(
        label: isStudentLike ? 'Exams and study planner' : 'Exams',
        icon: Icons.event_note_outlined,
        pageBuilder: () => ExamsPage(
          user: user,
          repository: campusRepository,
          canPlan: isStudentLike,
        ),
      ),
      HomeShortcut(
        label: 'Study resources',
        icon: Icons.menu_book_outlined,
        pageBuilder: () =>
            ResourcesPage(user: user, repository: campusRepository),
      ),
      if (isStudent)
        HomeShortcut(
          label: 'Results',
          icon: Icons.assessment_outlined,
          pageBuilder: () => buildStudentResults(user),
        ),
      HomeShortcut(
        label: 'Feedback',
        icon: Icons.rate_review_outlined,
        pageBuilder: () => buildFeedback(user),
      ),
    ],
  );
}

Widget buildTimetable(AppUser user) =>
    TimetablePage(user: user, repository: campusRepository);

Widget buildLecturerStudents(AppUser user) =>
    StudentsPage(user: user, repository: campusRepository);

Widget buildAdminHome(AppUser user) => AdminHomePage(
  user: user,
  repository: campusRepository,
  shortcuts: [
    HomeShortcut(
      label: 'Manage exams',
      icon: Icons.event_note_outlined,
      pageBuilder: () =>
          ExamsAdminPage(user: user, repository: campusRepository),
    ),
    HomeShortcut(
      label: 'Feedback and survey results',
      icon: Icons.rate_review_outlined,
      pageBuilder: () => buildFeedbackAdmin(user),
    ),
  ],
);

Widget buildAdminNotices(AppUser user) =>
    NoticesPage(user: user, repository: campusRepository, canManage: true);

Widget buildAdminUsers(AppUser user) =>
    UsersPage(repository: campusRepository, currentUserId: user.id);
