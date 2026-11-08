import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../../auth/domain/app_user.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';
import 'exams_page.dart';

/// Admin: schedule and remove exams. Students and lecturers see them live.
class ExamsAdminPage extends StatelessWidget {
  const ExamsAdminPage({
    super.key,
    required this.user,
    required this.repository,
  });

  final AppUser user;
  final CampusRepository repository;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => AddExamDialog(repository: repository, user: user),
        ),
        icon: const Icon(Icons.add),
        label: Text(context.tr('Add exam')),
      ),
      body: StreamView<List<Exam>>(
        open: () => repository.watchExams(user),
        builder: (context, exams) {
          final now = DateTime.now();
          final sorted = [...exams]..sort((a, b) => a.start.compareTo(b.start));
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                children: [
                  Text(context.tr('Exams'), style: text.headlineSmall),
                  const SizedBox(height: 16),
                  if (sorted.isEmpty)
                    Text(context.tr('No exams have been scheduled yet.')),
                  for (final e in sorted)
                    ExamCard(
                      exam: e,
                      now: now,
                      onDelete: () => repository.deleteExam(e.id),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AddExamDialog extends StatefulWidget {
  const AddExamDialog({
    super.key,
    required this.repository,
    required this.user,
  });

  final CampusRepository repository;

  /// The dialog loads the timetable for this user. Each course is picked from
  /// it so the exam automatically gets the right lecturer, department, level.
  final AppUser user;

  @override
  State<AddExamDialog> createState() => _AddExamDialogState();
}

class _AddExamDialogState extends State<AddExamDialog> {
  final _hall = TextEditingController();
  // The timetable, listened to once by the course picker.
  late final Stream<List<ClassSlot>> _timetable = widget.repository
      .watchTimetable(widget.user);
  List<ClassSlot> _courses = const [];
  String? _courseCode;
  DateTime? _date;
  TimeOfDay? _time;
  int _duration = 120;
  bool _busy = false;
  String? _error;

  static List<ClassSlot> _distinctCourses(List<ClassSlot> slots) {
    final byCode = <String, ClassSlot>{};
    for (final s in slots) {
      byCode.putIfAbsent(s.courseCode, () => s);
    }
    return byCode.values.toList()
      ..sort((a, b) => a.courseCode.compareTo(b.courseCode));
  }

  @override
  void dispose() {
    _hall.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final course = _courses
        .where((c) => c.courseCode == _courseCode)
        .firstOrNull;
    final date = _date;
    final time = _time;
    if (course == null || date == null || time == null) {
      setState(
        () => _error = context.tr('Choose a course, a date and a time.'),
      );
      return;
    }
    final failed = context.tr(
      'Could not save the exam. Check your permissions.',
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.addExam(
        Exam(
          id: '',
          courseCode: course.courseCode,
          courseTitle: course.courseTitle,
          lecturerId: course.lecturerId,
          department: course.department,
          level: course.level,
          start: DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
          durationMinutes: _duration,
          hallName: _hall.text.trim().isEmpty
              ? course.hallName
              : _hall.text.trim(),
          campusId: course.campusId,
          campusName: course.campusName,
        ),
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
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(context.tr('Add exam')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<List<ClassSlot>>(
                stream: _timetable,
                builder: (context, snapshot) {
                  _courses = _distinctCourses(snapshot.data ?? const []);
                  return DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _courseCode,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.tr('Course'),
                    ),
                    items: [
                      for (final c in _courses)
                        DropdownMenuItem(
                          value: c.courseCode,
                          child: Text(
                            '${c.courseCode} - ${c.courseTitle}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (code) => setState(() {
                      _courseCode = code;
                      final slot = _courses
                          .where((c) => c.courseCode == code)
                          .firstOrNull;
                      _hall.text = slot?.hallName ?? '';
                    }),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _date == null
                      ? context.tr('Pick the date')
                      : formatDay(_date!, lang: context.lang),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(
                  _time == null
                      ? context.tr('Pick the start time')
                      : formatClock(_time!.hour * 60 + _time!.minute),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                // ignore: deprecated_member_use
                value: _duration,
                decoration: InputDecoration(labelText: context.tr('Duration')),
                items: [
                  for (final d in const [60, 90, 120, 180])
                    DropdownMenuItem(value: d, child: Text(formatMinutes(d))),
                ],
                onChanged: (d) => setState(() => _duration = d ?? 120),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hall,
                decoration: InputDecoration(labelText: context.tr('Hall')),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
            ],
          ),
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
