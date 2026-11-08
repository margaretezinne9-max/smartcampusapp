import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../../../core/widgets/future_view.dart';
import '../../../core/widgets/stream_view.dart';
import '../../../core/widgets/royal_page_header.dart';
import '../../auth/domain/app_user.dart';
import '../../campus/domain/campus_models.dart';
import '../../campus/domain/campus_repository.dart';
import '../domain/results_from_enrollments.dart';
import '../domain/student_models.dart';
import '../domain/student_repository.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({
    super.key,
    required this.repository,
    required this.studentId,
  });

  final StudentRepository repository;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return FutureView<List<SemesterResult>>(
      load: () => repository.results(studentId),
      builder: (context, results) => ResultsView(results: results),
    );
  }
}

class ResultsView extends StatefulWidget {
  const ResultsView({required this.results});

  final List<SemesterResult> results;

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (widget.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF3E5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF075B36),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('No results have been published yet.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your academic results will appear here once they are released.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF718078)),
              ),
            ],
          ),
        ),
      );
    }

    final current = widget.results[_selected];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            RoyalPageHeader(
              title: context.tr('Academic results'),
              subtitle: context.tr(
                'Review your semester performance and course grades.',
              ),
              icon: Icons.workspace_premium_rounded,
            ),
            RoyalSectionHeading(context.tr('Select semester')),
            DropdownMenu<int>(
              initialSelection: _selected,
              expandedInsets: EdgeInsets.zero,
              label: Text(context.tr('Semester')),
              dropdownMenuEntries: [
                for (var i = 0; i < widget.results.length; i++)
                  DropdownMenuEntry(
                    value: i,
                    label: context.tr(widget.results[i].label),
                  ),
              ],
              onSelected: (i) {
                if (i != null) setState(() => _selected = i);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: context.tr('Semester GPA'),
                    value: current.gpa.toStringAsFixed(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'CGPA',
                    value: widget.results.cgpa.toStringAsFixed(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final g in current.grades) _GradeTile(grade: g),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: text.headlineMedium),
            Text(label, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _GradeTile extends StatelessWidget {
  const _GradeTile({required this.grade});

  final CourseGrade grade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = grade.passed ? scheme.primaryContainer : scheme.errorContainer;
    final fg = grade.passed
        ? scheme.onPrimaryContainer
        : scheme.onErrorContainer;

    return Card.outlined(
      child: ListTile(
        title: Text('${grade.code}  ${grade.title}'),
        subtitle: Text(
          context.tr('{units} units, score {score}', {
            'units': '${grade.units}',
            'score': '${grade.score}',
          }),
        ),
        trailing: CircleAvatar(
          backgroundColor: bg,
          foregroundColor: fg,
          child: Text(grade.grade),
        ),
      ),
    );
  }
}

/// Results built live from the scores that lecturers enter. A student only ever
/// reads their own enrolments (enforced by the Firestore rules).
class LiveResultsPage extends StatelessWidget {
  const LiveResultsPage({
    super.key,
    required this.user,
    required this.repository,
  });

  final AppUser user;
  final CampusRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Enrollment>>(
      open: () => repository.watchMyEnrollments(user),
      builder: (context, enrollments) =>
          ResultsView(results: resultsFromEnrollments(enrollments)),
    );
  }
}
