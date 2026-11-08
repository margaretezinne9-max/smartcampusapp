import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../../../core/widgets/royal_page_header.dart';
import '../../auth/domain/app_user.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';
import 'study_planner_page.dart';

/// One exam with its date, place and a countdown.
class ExamCard extends StatelessWidget {
  const ExamCard({
    super.key,
    required this.exam,
    required this.now,
    this.onDelete,
  });

  final Exam exam;
  final DateTime now;

  /// When set (admins), a delete button is shown.
  final VoidCallback? onDelete;

  String _status(BuildContext context) {
    if (!exam.end.isAfter(now)) return context.tr('Finished');
    if (!exam.start.isAfter(now)) return context.tr('Happening now');
    final days = daysUntil(exam.start, now);
    if (days == 0) return context.tr('Today');
    if (days == 1) return context.tr('Tomorrow');
    return context.tr('In {n} days', {'n': '$days'});
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        isThreeLine: true,
        leading: const Icon(Icons.event_note_outlined),
        title: Text('${exam.courseCode} - ${exam.courseTitle}'),
        subtitle: Text(
          '${formatDay(exam.start, lang: context.lang)}, ${formatTimeRange(exam.start, exam.end)}\n'
          '${exam.hallName}, ${exam.campusName}',
        ),
        trailing: onDelete == null
            ? Text(
                _status(context),
                style: text.labelLarge?.copyWith(color: scheme.primary),
              )
            : IconButton(
                tooltip: context.tr('Delete exam'),
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
      ),
    );
  }
}

/// Royal Emerald featured exam panel on the Home screen.
class NextExamSection extends StatelessWidget {
  const NextExamSection({
    super.key,
    required this.user,
    required this.repository,
    required this.now,
  });

  final AppUser user;
  final CampusRepository repository;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Exam>>(
      open: () => repository.watchExams(user),
      builder: (context, exams) {
        final upcoming = exams.where((e) => e.end.isAfter(now)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
        if (upcoming.isEmpty) return const SizedBox.shrink();
        final exam = upcoming.first;
        final days = daysUntil(exam.start, now);
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF075B36), Color(0xFF033E25)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06472B).withValues(alpha: .20),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFC629),
                    size: 23,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    context.tr('Next exam'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      days <= 0
                          ? context.tr('Today')
                          : context.tr('In {n} days', {'n': '$days'}),
                      style: const TextStyle(
                        color: Color(0xFFFFD45A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                exam.courseTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                exam.courseCode,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _examMeta(
                Icons.calendar_month_outlined,
                formatDay(exam.start, lang: context.lang),
              ),
              const SizedBox(height: 6),
              _examMeta(
                Icons.access_time_rounded,
                formatTimeRange(exam.start, exam.end),
              ),
              const SizedBox(height: 6),
              _examMeta(
                Icons.location_on_outlined,
                '${exam.hallName}, ${exam.campusName}',
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StudyPlannerPage(exams: upcoming),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(context.tr('Start Revision Plan')),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC629),
                    foregroundColor: const Color(0xFF173A25),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _examMeta(IconData icon, String value) => Row(
    children: [
      Icon(icon, size: 15, color: const Color(0xFFFFD45A)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

class _ExamCount extends StatelessWidget {
  const _ExamCount({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE6EEE8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: Color(0xFF075B36),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF66776D)),
        ),
      ],
    ),
  );
}

/// All exams of a student or lecturer, soonest first, with a countdown.
/// Students and course reps also get the study planner.
class ExamsPage extends StatelessWidget {
  const ExamsPage({
    super.key,
    required this.user,
    required this.repository,
    this.canPlan = false,
  });

  final AppUser user;
  final CampusRepository repository;
  final bool canPlan;

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Exam>>(
      open: () => repository.watchExams(user),
      builder: (context, exams) {
        final now = DateTime.now();
        final upcoming = exams.where((e) => e.end.isAfter(now)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
        final finished = exams.where((e) => !e.end.isAfter(now)).toList()
          ..sort((a, b) => b.start.compareTo(a.start));

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                RoyalPageHeader(
                  title: context.tr('Examinations'),
                  subtitle: context.tr(
                    'Stay prepared with your upcoming assessments and revision plan.',
                  ),
                  icon: Icons.school_rounded,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _ExamCount(
                        value: '${upcoming.length}',
                        label: context.tr('Upcoming'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ExamCount(
                        value: '${finished.length}',
                        label: context.tr('Completed'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (canPlan && upcoming.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StudyPlannerPage(exams: upcoming),
                          ),
                        ),
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: Text(context.tr('Study planner')),
                      ),
                    ),
                  ),
                if (exams.isEmpty)
                  Text(context.tr('No exams have been scheduled yet.')),
                for (final e in upcoming) ExamCard(exam: e, now: now),
                for (final e in finished) ExamCard(exam: e, now: now),
              ],
            ),
          ),
        );
      },
    );
  }
}
