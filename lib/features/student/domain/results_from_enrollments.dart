import '../../campus/domain/campus_models.dart';
import 'student_models.dart';

/// Turns a student's enrolments into results. Only courses whose lecturer has
/// entered a score count. All of them form one "Current semester" until the
/// data model carries sessions and semesters.
List<SemesterResult> resultsFromEnrollments(List<Enrollment> enrollments) {
  final graded = enrollments.where((e) => e.score != null).toList()
    ..sort((a, b) => a.courseCode.compareTo(b.courseCode));
  if (graded.isEmpty) return const [];

  return [
    SemesterResult(
      session: 'Current',
      semester: 'semester',
      grades: [
        for (final e in graded)
          CourseGrade(
            code: e.courseCode,
            title: e.courseTitle,
            units: e.units,
            score: e.score!,
          ),
      ],
    ),
  ];
}
