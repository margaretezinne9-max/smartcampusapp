import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';

/// A physical campus (main campus, annex) with how to get there.
class Campus {
  const Campus({
    required this.id,
    required this.name,
    required this.address,
    required this.mapsUrl,
    required this.directions,
  });

  final String id;
  final String name;
  final String address;

  /// Opens Google Maps directions. [directions] is the written fallback.
  final String mapsUrl;
  final String directions;

  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'mapsUrl': mapsUrl,
    'directions': directions,
  };

  factory Campus.fromMap(String id, Map<String, dynamic> m) => Campus(
    id: id,
    name: m['name'] as String? ?? '',
    address: m['address'] as String? ?? '',
    mapsUrl: m['mapsUrl'] as String? ?? '',
    directions: m['directions'] as String? ?? '',
  );
}

/// One weekly class: which course, when, in which hall on which campus.
class ClassSlot {
  const ClassSlot({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.lecturerId,
    required this.lecturerName,
    required this.department,
    required this.level,
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    required this.hallName,
    required this.campusId,
    required this.campusName,
  });

  final String id;
  final String courseCode;
  final String courseTitle;
  final String lecturerId;
  final String lecturerName;
  final String department;
  final int level;

  /// 1 = Monday ... 7 = Sunday (same as DateTime.weekday).
  final int weekday;

  /// Minutes after midnight, e.g. 480 = 08:00.
  final int startMinute;
  final int endMinute;
  final String hallName;
  final String campusId;
  final String campusName;

  Map<String, dynamic> toMap() => {
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'lecturerId': lecturerId,
    'lecturerName': lecturerName,
    'department': department,
    'level': level,
    'weekday': weekday,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'hallName': hallName,
    'campusId': campusId,
    'campusName': campusName,
  };

  factory ClassSlot.fromMap(String id, Map<String, dynamic> m) => ClassSlot(
    id: id,
    courseCode: m['courseCode'] as String? ?? '',
    courseTitle: m['courseTitle'] as String? ?? '',
    lecturerId: m['lecturerId'] as String? ?? '',
    lecturerName: m['lecturerName'] as String? ?? '',
    department: m['department'] as String? ?? '',
    level: (m['level'] as num?)?.toInt() ?? 0,
    weekday: (m['weekday'] as num?)?.toInt() ?? 1,
    startMinute: (m['startMinute'] as num?)?.toInt() ?? 0,
    endMinute: (m['endMinute'] as num?)?.toInt() ?? 0,
    hallName: m['hallName'] as String? ?? '',
    campusId: m['campusId'] as String? ?? '',
    campusName: m['campusName'] as String? ?? '',
  );
}

/// Which classes a user may see in their timetable.
/// Students and course reps: their department and level.
/// Lecturers: classes they teach. Admins: everything.
bool slotVisibleTo(ClassSlot slot, AppUser user) {
  switch (user.role) {
    case UserRole.lecturer:
      return slot.lecturerId == user.id;
    case UserRole.student:
    case UserRole.courseRep:
      return user.department != null &&
          user.level != null &&
          slot.department == user.department &&
          slot.level == user.level;
    case UserRole.admin:
      return true;
    case UserRole.bursar:
    case UserRole.aspirant:
      return false;
  }
}

/// One exam sitting. Stores the lecturer and the audience (department and
/// level) like a timetable slot, so each role only sees its own exams.
class Exam {
  const Exam({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.lecturerId,
    required this.department,
    required this.level,
    required this.start,
    required this.durationMinutes,
    required this.hallName,
    required this.campusId,
    required this.campusName,
  });

  final String id;
  final String courseCode;
  final String courseTitle;
  final String lecturerId;
  final String department;
  final int level;
  final DateTime start;
  final int durationMinutes;
  final String hallName;
  final String campusId;
  final String campusName;

  DateTime get end => start.add(Duration(minutes: durationMinutes));

  Exam withId(String newId) => Exam(
    id: newId,
    courseCode: courseCode,
    courseTitle: courseTitle,
    lecturerId: lecturerId,
    department: department,
    level: level,
    start: start,
    durationMinutes: durationMinutes,
    hallName: hallName,
    campusId: campusId,
    campusName: campusName,
  );
}

enum ResourceType {
  notes,
  pastQuestions,
  other;

  static ResourceType parse(String? value) => ResourceType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => ResourceType.other,
  );
}

/// A study resource shared by a lecturer as a link (lecture notes, past
/// questions ...). Links avoid file storage, which needs a paid Firebase plan.
class CourseResource {
  const CourseResource({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.title,
    required this.url,
    required this.type,
    required this.lecturerId,
    required this.lecturerName,
    required this.department,
    required this.level,
    required this.createdAt,
  });

  final String id;
  final String courseCode;
  final String courseTitle;
  final String title;
  final String url;
  final ResourceType type;
  final String lecturerId;
  final String lecturerName;
  final String department;
  final int level;
  final DateTime createdAt;
}

/// Rules shared by exams and resources: students and course reps see their
/// department and level, a lecturer sees what they teach, admins see all.
bool _audienceVisible(
  AppUser user, {
  required String lecturerId,
  required String department,
  required int level,
}) {
  switch (user.role) {
    case UserRole.lecturer:
      return lecturerId == user.id;
    case UserRole.student:
    case UserRole.courseRep:
      return user.department != null &&
          user.level != null &&
          department == user.department &&
          level == user.level;
    case UserRole.admin:
      return true;
    case UserRole.bursar:
    case UserRole.aspirant:
      return false;
  }
}

bool examVisibleTo(Exam exam, AppUser user) => _audienceVisible(
  user,
  lecturerId: exam.lecturerId,
  department: exam.department,
  level: exam.level,
);

bool resourceVisibleTo(CourseResource resource, AppUser user) =>
    _audienceVisible(
      user,
      lecturerId: resource.lecturerId,
      department: resource.department,
      level: resource.level,
    );

/// Resource links must be secure web links.
bool isValidResourceUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null && uri.scheme == 'https' && uri.host.contains('.');
}

/// A student enrolled in a course. [lecturerId] is stored on the record so
/// Firestore rules can let a lecturer see ONLY their own students.
class Enrollment {
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseCode,
    required this.courseTitle,
    required this.lecturerId,
    this.units = 3,
    this.score,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String courseCode;
  final String courseTitle;
  final String lecturerId;

  /// Credit units of the course, used to weight the GPA.
  final int units;

  /// Entered by the course's lecturer, 0 to 100. Null until then.
  final int? score;

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'studentName': studentName,
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'lecturerId': lecturerId,
    'units': units,
    'score': score,
  };

  factory Enrollment.fromMap(String id, Map<String, dynamic> m) => Enrollment(
    id: id,
    studentId: m['studentId'] as String? ?? '',
    studentName: m['studentName'] as String? ?? '',
    courseCode: m['courseCode'] as String? ?? '',
    courseTitle: m['courseTitle'] as String? ?? '',
    lecturerId: m['lecturerId'] as String? ?? '',
    units: (m['units'] as num?)?.toInt() ?? 3,
    score: (m['score'] as num?)?.toInt(),
  );
}

/// A score is a whole number from 0 to 100.
bool isValidScore(int score) => score >= 0 && score <= 100;

enum NoticeCategory {
  notice,
  event;

  static NoticeCategory parse(String? value) => NoticeCategory.values
      .firstWhere((c) => c.name == value, orElse: () => NoticeCategory.notice);
}

/// A notice or calendar event published by an admin.
class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    required this.authorName,
    this.eventDate,
    this.department,
    this.level,
  });

  final String id;
  final String title;
  final String body;
  final NoticeCategory category;
  final DateTime createdAt;
  final String authorName;

  /// Only for events (cultural day, tests, defence day, ...).
  final DateTime? eventDate;

  /// Audience. Null means everyone. See noticeVisibleTo in notice_logic.dart.
  final String? department;
  final int? level;
}

/// A user as seen by the admin in the Users tab.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.level,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? department;
  final int? level;
}
