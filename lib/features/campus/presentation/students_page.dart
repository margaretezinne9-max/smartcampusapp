import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../../auth/domain/app_user.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';

/// A lecturer's own students, grouped by course. Firestore rules make sure a
/// lecturer can only ever read enrolments of the courses they teach.
class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key, required this.user, required this.repository});

  final AppUser user;
  final CampusRepository repository;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return StreamView<List<Enrollment>>(
      open: () => repository.watchEnrollments(user),
      builder: (context, enrollments) {
        final byCourse = <String, List<Enrollment>>{};
        for (final e in enrollments) {
          byCourse.putIfAbsent(e.courseCode, () => []).add(e);
        }
        final codes = byCourse.keys.toList()..sort();

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(context.tr('My students'), style: text.headlineSmall),
                const SizedBox(height: 16),
                if (codes.isEmpty)
                  Text(
                    context.tr('No students are enrolled in your courses yet.'),
                  ),
                for (final code in codes)
                  Card.outlined(
                    child: ExpansionTile(
                      title: Text(
                        '$code - ${byCourse[code]!.first.courseTitle}',
                      ),
                      subtitle: Text(
                        context.tr(
                          byCourse[code]!.length == 1
                              ? '{n} student'
                              : '{n} students',
                          {'n': '${byCourse[code]!.length}'},
                        ),
                      ),
                      children: [
                        for (final e
                            in (byCourse[code]!.toList()..sort(
                              (a, b) => a.studentName.compareTo(b.studentName),
                            )))
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline),
                            title: Text(e.studentName),
                            subtitle: Text(
                              e.score == null
                                  ? context.tr('No score yet')
                                  : context.tr('Score: {score}', {
                                      'score': '${e.score}',
                                    }),
                            ),
                            trailing: IconButton(
                              tooltip: context.tr('Edit score'),
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => ScoreDialog(
                                  repository: repository,
                                  lecturer: user,
                                  enrollment: e,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A lecturer types the score (0 to 100) of one student for one course.
/// Leaving the field empty clears the score.
class ScoreDialog extends StatefulWidget {
  const ScoreDialog({
    super.key,
    required this.repository,
    required this.lecturer,
    required this.enrollment,
  });

  final CampusRepository repository;
  final AppUser lecturer;
  final Enrollment enrollment;

  @override
  State<ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<ScoreDialog> {
  late final _score = TextEditingController(
    text: widget.enrollment.score?.toString() ?? '',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _score.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _score.text.trim();
    final value = raw.isEmpty ? null : int.tryParse(raw);
    if (raw.isNotEmpty && (value == null || !isValidScore(value))) {
      setState(
        () => _error = context.tr('Enter a whole number from 0 to 100.'),
      );
      return;
    }
    final failed = context.tr(
      'Could not save the score. Check your permissions.',
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.setScore(
        lecturer: widget.lecturer,
        enrollmentId: widget.enrollment.id,
        score: value,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = failed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.enrollment;
    return AlertDialog(
      title: Text('${e.courseCode} - ${e.studentName}'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _score,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.tr('Score (0-100)'),
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(context.tr('Save')),
        ),
      ],
    );
  }
}
