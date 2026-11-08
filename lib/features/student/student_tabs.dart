import 'package:flutter/widgets.dart';

import '../auth/domain/app_user.dart';
import '../campus/campus_service.dart';
import 'data/mock_student_repository.dart';
import 'domain/student_repository.dart';
import 'presentation/courses_page.dart';
import 'presentation/results_page.dart';

// Swap MockStudentRepository for your real API implementation here.
final StudentRepository _repository = MockStudentRepository();

Widget buildStudentCourses(AppUser user) =>
    CoursesPage(repository: _repository, studentId: user.id);

/// Results come from the scores lecturers enter (see LiveResultsPage).
Widget buildStudentResults(AppUser user) =>
    LiveResultsPage(user: user, repository: campusRepository);
