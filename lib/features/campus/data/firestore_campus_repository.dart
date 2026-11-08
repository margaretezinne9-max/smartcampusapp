import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';
import '../domain/demo_data.dart';

/// Real-time Firestore implementation.
///
/// Collections: users, campuses, timetable, notices, enrollments.
/// WHO may read or write each one is decided by firestore.rules, not here.
class FirestoreCampusRepository implements CampusRepository {
  FirestoreCampusRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;

  @override
  Stream<List<ClassSlot>> watchTimetable(AppUser user) {
    Query<Map<String, dynamic>> query = _db.collection('timetable');

    if (user.role == UserRole.lecturer) {
      query = query.where('lecturerId', isEqualTo: user.id);
    } else if (user.role == UserRole.student ||
        user.role == UserRole.courseRep) {
      final department = user.department;
      final level = user.level;
      if (department == null || level == null) {
        return Stream.value(const <ClassSlot>[]);
      }
      query = query
          .where('department', isEqualTo: department)
          .where('level', isEqualTo: level);
    } else if (user.role != UserRole.admin) {
      return Stream.value(const <ClassSlot>[]);
    }

    return query.snapshots().map(
      (snap) =>
          snap.docs.map((d) => ClassSlot.fromMap(d.id, d.data())).toList(),
    );
  }

  @override
  Stream<List<Campus>> watchCampuses() => _db
      .collection('campuses')
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => Campus.fromMap(d.id, d.data())).toList(),
      );

  @override
  Stream<List<Notice>> watchNotices() => _db
      .collection('notices')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => _notice(d.id, d.data())).toList());

  @override
  Stream<List<Enrollment>> watchEnrollments(AppUser lecturer) => _db
      .collection('enrollments')
      .where('lecturerId', isEqualTo: lecturer.id)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => Enrollment.fromMap(d.id, d.data())).toList(),
      );

  @override
  Stream<List<Enrollment>> watchMyEnrollments(AppUser student) => _db
      .collection('enrollments')
      .where('studentId', isEqualTo: student.id)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => Enrollment.fromMap(d.id, d.data())).toList(),
      );

  @override
  Future<void> setScore({
    required AppUser lecturer,
    required String enrollmentId,
    required int? score,
  }) async {
    if (score != null && !isValidScore(score)) {
      throw ArgumentError('A score must be from 0 to 100.');
    }
    // The rules allow a lecturer to change only `score`, and only on the
    // enrolments of their own courses.
    await _db.collection('enrollments').doc(enrollmentId).update({
      'score': score,
    });
  }

  @override
  Stream<List<UserProfile>> watchUsers() => _db
      .collection('users')
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) {
          final m = d.data();
          return UserProfile(
            id: d.id,
            name: m['name'] as String? ?? '',
            email: m['email'] as String? ?? '',
            role: UserRole.parse(m['role'] as String?),
            department: m['department'] as String?,
            level: (m['level'] as num?)?.toInt(),
          );
        }).toList(),
      );

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
    await _db.collection('notices').add({
      'title': title,
      'body': body,
      'category': category.name,
      if (eventDate != null) 'eventDate': Timestamp.fromDate(eventDate),
      if (department != null) 'department': department,
      if (level != null) 'level': level,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteNotice(String id) =>
      _db.collection('notices').doc(id).delete();

  @override
  Future<void> updateUserRole(String userId, UserRole role) =>
      _db.collection('users').doc(userId).update({'role': role.name});

  @override
  Future<void> seedDemoData() async {
    final users = await _db.collection('users').get();
    final batch = _db.batch();
    final students = <DemoStudent>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? lecturer;

    for (final doc in users.docs) {
      final data = doc.data();
      final role = UserRole.parse(data['role'] as String?);
      if (role == UserRole.lecturer) {
        lecturer ??= doc;
        batch.update(doc.reference, {'department': DemoData.department});
      } else if (role == UserRole.student || role == UserRole.courseRep) {
        students.add(DemoStudent(doc.id, data['name'] as String? ?? 'Student'));
        batch.update(doc.reference, {
          'department': DemoData.department,
          'level': DemoData.level,
        });
      }
    }

    final data = DemoData.build(
      lecturerId: lecturer?.id ?? 'unassigned',
      lecturerName: (lecturer?.data()['name'] as String?) ?? 'Course lecturer',
      students: students,
      now: DateTime.now(),
    );

    for (final c in data.campuses) {
      batch.set(_db.collection('campuses').doc(c.id), c.toMap());
    }
    for (final s in data.slots) {
      batch.set(_db.collection('timetable').doc(s.id), s.toMap());
    }
    // One chat room per course (id = course code without spaces). The rules
    // use lecturerId to decide who may read and post.
    for (final s in data.slots) {
      batch.set(
        _db.collection('chatRooms').doc(s.courseCode.replaceAll(' ', '')),
        {
          'courseCode': s.courseCode,
          'courseTitle': s.courseTitle,
          'lecturerId': s.lecturerId,
          'lecturerName': s.lecturerName,
        },
      );
    }
    for (final e in data.enrollments) {
      batch.set(_db.collection('enrollments').doc(e.id), e.toMap());
    }
    for (final n in data.notices) {
      batch.set(_db.collection('notices').doc(n.id), {
        'title': n.title,
        'body': n.body,
        'category': n.category.name,
        if (n.eventDate != null) 'eventDate': Timestamp.fromDate(n.eventDate!),
        if (n.department != null) 'department': n.department,
        if (n.level != null) 'level': n.level,
        'authorName': n.authorName,
        'createdAt': Timestamp.fromDate(n.createdAt),
      });
    }
    for (final e in data.exams) {
      batch.set(_db.collection('exams').doc(e.id), _examMap(e));
    }
    for (final r in data.resources) {
      batch.set(
        _db.collection('resources').doc(r.id),
        _resourceMap(r, serverTime: false),
      );
    }
    await batch.commit();
  }

  /// Same audience rules as the timetable, as a Firestore query.
  /// Null means the user may not see this collection at all.
  Query<Map<String, dynamic>>? _audienceQuery(String collection, AppUser user) {
    final base = _db.collection(collection);
    if (user.role == UserRole.lecturer) {
      return base.where('lecturerId', isEqualTo: user.id);
    }
    if (user.role == UserRole.student || user.role == UserRole.courseRep) {
      final department = user.department;
      final level = user.level;
      if (department == null || level == null) return null;
      return base
          .where('department', isEqualTo: department)
          .where('level', isEqualTo: level);
    }
    return user.role == UserRole.admin ? base : null;
  }

  Exam _exam(String id, Map<String, dynamic> m) => Exam(
    id: id,
    courseCode: m['courseCode'] as String? ?? '',
    courseTitle: m['courseTitle'] as String? ?? '',
    lecturerId: m['lecturerId'] as String? ?? '',
    department: m['department'] as String? ?? '',
    level: (m['level'] as num?)?.toInt() ?? 0,
    start: _date(m['start']) ?? DateTime.now(),
    durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 120,
    hallName: m['hallName'] as String? ?? '',
    campusId: m['campusId'] as String? ?? '',
    campusName: m['campusName'] as String? ?? '',
  );

  Map<String, dynamic> _examMap(Exam e) => {
    'courseCode': e.courseCode,
    'courseTitle': e.courseTitle,
    'lecturerId': e.lecturerId,
    'department': e.department,
    'level': e.level,
    'start': Timestamp.fromDate(e.start),
    'durationMinutes': e.durationMinutes,
    'hallName': e.hallName,
    'campusId': e.campusId,
    'campusName': e.campusName,
  };

  Map<String, dynamic> _resourceMap(
    CourseResource r, {
    required bool serverTime,
  }) => {
    'courseCode': r.courseCode,
    'courseTitle': r.courseTitle,
    'title': r.title,
    'url': r.url,
    'type': r.type.name,
    'lecturerId': r.lecturerId,
    'lecturerName': r.lecturerName,
    'department': r.department,
    'level': r.level,
    'createdAt': serverTime
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(r.createdAt),
  };

  @override
  Stream<List<Exam>> watchExams(AppUser user) {
    final query = _audienceQuery('exams', user);
    if (query == null) return Stream.value(const <Exam>[]);
    return query.snapshots().map(
      (snap) => snap.docs.map((d) => _exam(d.id, d.data())).toList(),
    );
  }

  @override
  Future<void> addExam(Exam exam) async {
    await _db.collection('exams').add(_examMap(exam));
  }

  @override
  Future<void> deleteExam(String id) =>
      _db.collection('exams').doc(id).delete();

  @override
  Stream<List<CourseResource>> watchResources(AppUser user) {
    final query = _audienceQuery('resources', user);
    if (query == null) return Stream.value(const <CourseResource>[]);
    return query.snapshots().map(
      (snap) => snap.docs.map((d) {
        final m = d.data();
        return CourseResource(
          id: d.id,
          courseCode: m['courseCode'] as String? ?? '',
          courseTitle: m['courseTitle'] as String? ?? '',
          title: m['title'] as String? ?? '',
          url: m['url'] as String? ?? '',
          type: ResourceType.parse(m['type'] as String?),
          lecturerId: m['lecturerId'] as String? ?? '',
          lecturerName: m['lecturerName'] as String? ?? '',
          department: m['department'] as String? ?? '',
          level: (m['level'] as num?)?.toInt() ?? 0,
          // Just added: no server time yet, show it as "now".
          createdAt: _date(m['createdAt']) ?? DateTime.now(),
        );
      }).toList(),
    );
  }

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
    await _db
        .collection('resources')
        .add(
          _resourceMap(
            CourseResource(
              id: '',
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
            serverTime: true,
          ),
        );
  }

  @override
  Future<void> deleteResource(String id) =>
      _db.collection('resources').doc(id).delete();

  Notice _notice(String id, Map<String, dynamic> m) => Notice(
    id: id,
    title: m['title'] as String? ?? '',
    body: m['body'] as String? ?? '',
    category: NoticeCategory.parse(m['category'] as String?),
    eventDate: _date(m['eventDate']),
    // A just-published notice has no server time yet; show it as "now".
    createdAt: _date(m['createdAt']) ?? DateTime.now(),
    authorName: m['authorName'] as String? ?? '',
    department: m['department'] as String?,
    level: (m['level'] as num?)?.toInt(),
  );
}
