import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import 'campus_models.dart';

/// Everything the campus screens need. Streams update in real time, which is
/// how a notice published by an admin appears on other devices with no
/// refresh. Two implementations: in-memory (demo/tests) and Firestore.
abstract interface class CampusRepository {
  Stream<List<ClassSlot>> watchTimetable(AppUser user);
  Stream<List<Campus>> watchCampuses();
  Stream<List<Notice>> watchNotices();

  /// A lecturer's own students (enrolments of the courses they teach).
  Stream<List<Enrollment>> watchEnrollments(AppUser lecturer);

  /// A student's own enrolments: their courses and any scores entered.
  Stream<List<Enrollment>> watchMyEnrollments(AppUser student);

  /// A lecturer enters (or clears, with null) the score of one of their
  /// students. Throws [ArgumentError] for a score outside 0 to 100 and
  /// [StateError] when the enrolment is not for one of the lecturer's courses.
  Future<void> setScore({
    required AppUser lecturer,
    required String enrollmentId,
    required int? score,
  });

  /// Admin only.
  Stream<List<UserProfile>> watchUsers();

  Future<void> publishNotice({
    required String title,
    required String body,
    required NoticeCategory category,
    required String authorName,
    DateTime? eventDate,
    String? department,
    int? level,
  });

  Future<void> deleteNotice(String id);
  Future<void> updateUserRole(String userId, UserRole role);

  /// Exams visible to [user] (see [examVisibleTo]).
  Stream<List<Exam>> watchExams(AppUser user);

  /// Admin only.
  Future<void> addExam(Exam exam);
  Future<void> deleteExam(String id);

  /// Study resources visible to [user] (see [resourceVisibleTo]).
  Stream<List<CourseResource>> watchResources(AppUser user);

  /// A lecturer shares a link for one of their own courses ([course] is one
  /// of their timetable slots). Throws [ArgumentError] for an empty title or
  /// a link that is not a secure web link.
  Future<void> addResource({
    required AppUser lecturer,
    required ClassSlot course,
    required String title,
    required String url,
    required ResourceType type,
  });

  Future<void> deleteResource(String id);

  /// Loads sample campuses, timetable, notices and enrolments (admin only).
  Future<void> seedDemoData();
}
