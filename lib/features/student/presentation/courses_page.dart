import 'package:flutter/material.dart';

import '../../../core/widgets/future_view.dart';
import '../domain/student_models.dart';
import '../domain/student_repository.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({
    super.key,
    required this.repository,
    required this.studentId,
  });

  final StudentRepository repository;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return FutureView<List<Course>>(
      load: () => repository.currentCourses(studentId),
      builder: (context, courses) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final units = courses.fold<int>(0, (sum, c) => sum + c.units);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('My courses', style: text.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '${courses.length} courses, $units units this semester',
                  style: text.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (final c in courses) _CourseCard(course: c),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget detail(IconData icon, String value) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  course.code,
                  style: text.labelLarge?.copyWith(color: scheme.primary),
                ),
                const Spacer(),
                Chip(
                  label: Text('${course.units} units'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Text(course.title, style: text.titleMedium),
            detail(Icons.person_outline, course.lecturer),
            detail(Icons.schedule_outlined, course.schedule),
          ],
        ),
      ),
    );
  }
}
