import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../domain/campus_models.dart';
import '../domain/study_planner.dart';

/// Day-by-day study plan built from the upcoming exams. The student chooses
/// how long they can study each day; closer exams get more of that time.
class StudyPlannerPage extends StatefulWidget {
  const StudyPlannerPage({super.key, required this.exams});

  final List<Exam> exams;

  @override
  State<StudyPlannerPage> createState() => _StudyPlannerPageState();
}

class _StudyPlannerPageState extends State<StudyPlannerPage> {
  static const _options = [60, 120, 180, 240];
  int _minutesPerDay = 120;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final lang = context.lang;

    final plan = buildStudyPlan(
      exams: widget.exams,
      now: now,
      minutesPerDay: _minutesPerDay,
    );
    final days = <DateTime, List<StudyBlock>>{};
    for (final b in plan) {
      days.putIfAbsent(b.date, () => []).add(b);
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Study planner'))),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                context.tr('How much can you study each day?'),
                style: text.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in _options)
                    ChoiceChip(
                      label: Text(formatMinutes(m)),
                      selected: _minutesPerDay == m,
                      onSelected: (_) => setState(() => _minutesPerDay = m),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('The closer an exam is, the more time it gets.'),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (plan.isEmpty)
                Text(context.tr('No upcoming exams to plan for.')),
              for (final entry in days.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    '${dayLabel(entry.key, now, lang: lang)} - ${formatDay(entry.key, lang: lang)}',
                    style: text.titleSmall,
                  ),
                ),
                for (final b in entry.value)
                  Card.outlined(
                    child: ListTile(
                      dense: true,
                      title: Text(
                        '${b.exam.courseCode} - ${b.exam.courseTitle}',
                      ),
                      trailing: Text(formatMinutes(b.minutes)),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
