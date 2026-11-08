import '../domain/student_models.dart';
import '../domain/student_repository.dart';

class MockStudentRepository implements StudentRepository {
  @override
  Future<List<Course>> currentCourses(String studentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const [
      Course(
        code: 'CSC 401',
        title: 'Compiler Construction',
        units: 3,
        lecturer: 'Dr. A. Bello',
        schedule: 'Mon 8:00-10:00, LT2',
      ),
      Course(
        code: 'CSC 403',
        title: 'Artificial Intelligence',
        units: 3,
        lecturer: 'Prof. N. Okafor',
        schedule: 'Tue 10:00-12:00, LT1',
      ),
      Course(
        code: 'CSC 405',
        title: 'Computer Networks',
        units: 3,
        lecturer: 'Dr. S. Adeyemi',
        schedule: 'Wed 12:00-14:00, Lab 3',
      ),
      Course(
        code: 'CSC 499',
        title: 'Final Year Project',
        units: 6,
        lecturer: 'Project Supervisor',
        schedule: 'By appointment',
      ),
      Course(
        code: 'GST 401',
        title: 'Entrepreneurship Studies',
        units: 2,
        lecturer: 'Mrs. T. Johnson',
        schedule: 'Fri 9:00-11:00, LT3',
      ),
    ];
  }

  @override
  Future<List<SemesterResult>> results(String studentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const [
      SemesterResult(
        session: '2025/2026',
        semester: 'Second Semester',
        grades: [
          CourseGrade(
            code: 'CSC 302',
            title: 'Operating Systems',
            units: 3,
            score: 72,
          ),
          CourseGrade(
            code: 'CSC 304',
            title: 'Database Systems',
            units: 3,
            score: 65,
          ),
          CourseGrade(
            code: 'CSC 306',
            title: 'Software Engineering',
            units: 3,
            score: 81,
          ),
          CourseGrade(
            code: 'MTH 302',
            title: 'Numerical Analysis',
            units: 3,
            score: 58,
          ),
          CourseGrade(
            code: 'GST 302',
            title: 'Peace and Conflict Studies',
            units: 2,
            score: 68,
          ),
        ],
      ),
      SemesterResult(
        session: '2025/2026',
        semester: 'First Semester',
        grades: [
          CourseGrade(
            code: 'CSC 301',
            title: 'Data Structures',
            units: 3,
            score: 76,
          ),
          CourseGrade(
            code: 'CSC 303',
            title: 'Algorithms',
            units: 3,
            score: 70,
          ),
          CourseGrade(
            code: 'CSC 305',
            title: 'Web Technologies',
            units: 3,
            score: 84,
          ),
          CourseGrade(
            code: 'MTH 301',
            title: 'Linear Algebra',
            units: 3,
            score: 47,
          ),
          CourseGrade(
            code: 'GST 301',
            title: 'Communication Skills',
            units: 2,
            score: 62,
          ),
        ],
      ),
    ];
  }
}
