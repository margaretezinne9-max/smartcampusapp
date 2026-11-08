class Course {
  const Course({
    required this.code,
    required this.title,
    required this.units,
    required this.lecturer,
    required this.schedule,
  });

  final String code;
  final String title;
  final int units;
  final String lecturer;
  final String schedule;
}

/// One course result. Uses a 5-point scale; adjust the cut-offs to match
/// Hill City University's grading policy.
class CourseGrade {
  const CourseGrade({
    required this.code,
    required this.title,
    required this.units,
    required this.score,
  });

  final String code;
  final String title;
  final int units;
  final int score;

  String get grade => switch (score) {
    >= 70 => 'A',
    >= 60 => 'B',
    >= 50 => 'C',
    >= 45 => 'D',
    >= 40 => 'E',
    _ => 'F',
  };

  int get points => switch (score) {
    >= 70 => 5,
    >= 60 => 4,
    >= 50 => 3,
    >= 45 => 2,
    >= 40 => 1,
    _ => 0,
  };

  bool get passed => score >= 40;
}

class SemesterResult {
  const SemesterResult({
    required this.session,
    required this.semester,
    required this.grades,
  });

  final String session;
  final String semester;
  final List<CourseGrade> grades;

  String get label => '$session $semester';

  int get totalUnits => grades.fold(0, (sum, g) => sum + g.units);

  int get totalPoints => grades.fold(0, (sum, g) => sum + g.points * g.units);

  double get gpa => totalUnits == 0 ? 0 : totalPoints / totalUnits;
}

extension ResultsSummary on List<SemesterResult> {
  double get cgpa {
    final units = fold<int>(0, (sum, s) => sum + s.totalUnits);
    final points = fold<int>(0, (sum, s) => sum + s.totalPoints);
    return units == 0 ? 0 : points / units;
  }
}
