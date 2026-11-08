import '../../../core/live_value.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';
import '../domain/demo_data.dart';

/// Demo backend that needs no internet. Data matches the demo accounts of
/// MockAuthRepository (hcu-student-001, hcu-lecturer-001, ...).
class InMemoryCampusRepository implements CampusRepository {
  InMemoryCampusRepository() {
    _loadDemo();
    _users.value = [
      for (final r in UserRole.values)
        UserProfile(
          id: 'hcu-${r.name}-001',
          name: 'Demo ${r.label}',
          email: '${r.name}@hcu.edu'.toLowerCase(),
          role: r,
          department:
              (r == UserRole.student ||
                  r == UserRole.courseRep ||
                  r == UserRole.lecturer)
              ? DemoData.department
              : null,
          level: (r == UserRole.student || r == UserRole.courseRep)
              ? DemoData.level
              : null,
        ),
    ];
  }

  final _slots = LiveValue<List<ClassSlot>>(const []);
  final _campuses = LiveValue<List<Campus>>(const []);
  final _notices = LiveValue<List<Notice>>(const []);
  final _enrollments = LiveValue<List<Enrollment>>(const []);
  final _users = LiveValue<List<UserProfile>>(const []);
  final _exams = LiveValue<List<Exam>>(const []);
  final _resources = LiveValue<List<CourseResource>>(const []);
  int _noticeCounter = 0;
  int _examCounter = 0;
  int _resourceCounter = 0;

  void _loadDemo() {
    final data = DemoData.build(
      lecturerId: 'hcu-lecturer-001',
      lecturerName: 'Demo Lecturer',
      students: const [
        DemoStudent('hcu-student-001', 'Demo Student'),
        DemoStudent('hcu-courseRep-001', 'Demo Course Rep'),
      ],
      now: DateTime.now(),
    );
    _campuses.value = data.campuses;
    _slots.value = data.slots;
    _enrollments.value = data.enrollments;
    _exams.value = data.exams;
    _resources.value = data.resources;
    _notices.value = [...data.notices]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Stream<List<ClassSlot>> watchTimetable(AppUser user) => _slots.watch().map(
    (all) => all.where((s) => slotVisibleTo(s, user)).toList(),
  );

  @override
  Stream<List<Campus>> watchCampuses() => _campuses.watch();

  @override
  Stream<List<Notice>> watchNotices() => _notices.watch();

  @override
  Stream<List<Enrollment>> watchEnrollments(AppUser lecturer) => _enrollments
      .watch()
      .map((all) => all.where((e) => e.lecturerId == lecturer.id).toList());

  @override
  Stream<List<Enrollment>> watchMyEnrollments(AppUser student) => _enrollments
      .watch()
      .map((all) => all.where((e) => e.studentId == student.id).toList());

  @override
  Future<void> setScore({
    required AppUser lecturer,
    required String enrollmentId,
    required int? score,
  }) async {
    if (score != null && !isValidScore(score)) {
      throw ArgumentError('A score must be from 0 to 100.');
    }
    final target = _enrollments.value
        .where((e) => e.id == enrollmentId)
        .firstOrNull;
    if (target == null || target.lecturerId != lecturer.id) {
      throw StateError('You can only grade students of your own courses.');
    }
    _enrollments.value = [
      for (final e in _enrollments.value)
        if (e.id == enrollmentId)
          Enrollment(
            id: e.id,
            studentId: e.studentId,
            studentName: e.studentName,
            courseCode: e.courseCode,
            courseTitle: e.courseTitle,
            lecturerId: e.lecturerId,
            units: e.units,
            score: score,
          )
        else
          e,
    ];
  }

  @override
  Stream<List<UserProfile>> watchUsers() => _users.watch();

  @override
  Future<void> publishNotice({
    required String title,
    required String body,
    required NoticeCategory category,
    required String authorName,
    DateTime? eventDate,
    String? department,
    int? level,
  }) async {
    _noticeCounter++;
    _notices.value = [
      Notice(
        id: 'local-$_noticeCounter',
        title: title,
        body: body,
        category: category,
        createdAt: DateTime.now(),
        authorName: authorName,
        eventDate: eventDate,
        department: department,
        level: level,
      ),
      ..._notices.value,
    ];
  }

  @override
  Future<void> deleteNotice(String id) async {
    _notices.value = _notices.value.where((n) => n.id != id).toList();
  }

  /// Changes only the list shown to the admin; demo sign-in accounts keep
  /// their fixed roles.
  @override
  Future<void> updateUserRole(String userId, UserRole role) async {
    _users.value = [
      for (final u in _users.value)
        if (u.id == userId)
          UserProfile(
            id: u.id,
            name: u.name,
            email: u.email,
            role: role,
            department: u.department,
            level: u.level,
          )
        else
          u,
    ];
  }

  @override
  Stream<List<Exam>> watchExams(AppUser user) => _exams.watch().map(
    (all) => all.where((e) => examVisibleTo(e, user)).toList(),
  );

  @override
  Future<void> addExam(Exam exam) async {
    _examCounter++;
    _exams.value = [..._exams.value, exam.withId('local-exam-$_examCounter')];
  }

  @override
  Future<void> deleteExam(String id) async {
    _exams.value = _exams.value.where((e) => e.id != id).toList();
  }

  @override
  Stream<List<CourseResource>> watchResources(AppUser user) => _resources
      .watch()
      .map((all) => all.where((r) => resourceVisibleTo(r, user)).toList());

  @override
  Future<void> addResource({
    required AppUser lecturer,
    required ClassSlot course,
    required String title,
    required String url,
    required ResourceType type,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 120) {
      throw ArgumentError('A title must be 1 to 120 characters.');
    }
    if (!isValidResourceUrl(url)) {
      throw ArgumentError('The link must start with https://');
    }
    if (course.lecturerId != lecturer.id) {
      throw StateError('You can only share resources for your own courses.');
    }
    _resourceCounter++;
    _resources.value = [
      CourseResource(
        id: 'local-res-$_resourceCounter',
        courseCode: course.courseCode,
        courseTitle: course.courseTitle,
        title: cleanTitle,
        url: url.trim(),
        type: type,
        lecturerId: lecturer.id,
        lecturerName: lecturer.name,
        department: course.department,
        level: course.level,
        createdAt: DateTime.now(),
      ),
      ..._resources.value,
    ];
  }

  @override
  Future<void> deleteResource(String id) async {
    _resources.value = _resources.value.where((r) => r.id != id).toList();
  }

  @override
  Future<void> seedDemoData() async => _loadDemo();
}
