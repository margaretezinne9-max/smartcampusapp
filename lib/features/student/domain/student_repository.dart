import 'student_models.dart';

/// Implement this with your real API. The student pages only depend on it.
abstract interface class StudentRepository {
  Future<List<Course>> currentCourses(String studentId);

  /// Newest semester first.
  Future<List<SemesterResult>> results(String studentId);
}
