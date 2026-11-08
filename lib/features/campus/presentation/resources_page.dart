import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../../../core/widgets/royal_page_header.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';

IconData _iconFor(ResourceType type) => switch (type) {
  ResourceType.notes => Icons.description_outlined,
  ResourceType.pastQuestions => Icons.quiz_outlined,
  ResourceType.other => Icons.link,
};

String _labelFor(ResourceType type) => switch (type) {
  ResourceType.notes => 'Notes',
  ResourceType.pastQuestions => 'Past questions',
  ResourceType.other => 'Other',
};

/// Notes and past questions shared by lecturers, as links. Students see the
/// resources of their department and level; a lecturer sees and manages their
/// own.
class ResourcesPage extends StatelessWidget {
  const ResourcesPage({
    super.key,
    required this.user,
    required this.repository,
  });

  final AppUser user;
  final CampusRepository repository;

  bool get _isLecturer => user.role == UserRole.lecturer;

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.tr('Could not open the link.');
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _isLecturer
          ? FloatingActionButton.extended(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    AddResourceDialog(repository: repository, lecturer: user),
              ),
              icon: const Icon(Icons.add),
              label: Text(context.tr('Add resource')),
            )
          : null,
      body: StreamView<List<CourseResource>>(
        open: () => repository.watchResources(user),
        builder: (context, resources) {
          final sorted = [...resources]
            ..sort((a, b) {
              final byCourse = a.courseCode.compareTo(b.courseCode);
              return byCourse != 0
                  ? byCourse
                  : b.createdAt.compareTo(a.createdAt);
            });

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                children: [
                  RoyalPageHeader(
                    title: context.tr('Study resources'),
                    subtitle: context.tr(
                      'Find lecture notes, past questions and helpful course materials.',
                    ),
                    icon: Icons.menu_book_rounded,
                  ),
                  RoyalSectionHeading(context.tr('Your learning library')),
                  if (sorted.isEmpty)
                    Text(context.tr('No resources have been shared yet.')),
                  for (final r in sorted)
                    Card.outlined(
                      child: ListTile(
                        isThreeLine: true,
                        leading: Icon(_iconFor(r.type)),
                        title: Text(r.title),
                        subtitle: Text(
                          '${r.courseCode} - ${r.courseTitle}\n'
                          '${context.tr(_labelFor(r.type))}, ${r.lecturerName}',
                        ),
                        onTap: () => _open(context, r.url),
                        trailing: (_isLecturer && r.lecturerId == user.id)
                            ? IconButton(
                                tooltip: context.tr('Delete resource'),
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    repository.deleteResource(r.id),
                              )
                            : const Icon(Icons.open_in_new),
                      ),
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

class AddResourceDialog extends StatefulWidget {
  const AddResourceDialog({
    super.key,
    required this.repository,
    required this.lecturer,
  });

  final CampusRepository repository;

  /// The dialog loads this lecturer's own timetable: they can only share
  /// resources for the courses they teach.
  final AppUser lecturer;

  @override
  State<AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends State<AddResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _url = TextEditingController();
  // The lecturer's own timetable, listened to once by the course picker.
  late final Stream<List<ClassSlot>> _timetable = widget.repository
      .watchTimetable(widget.lecturer);
  List<ClassSlot> _courses = const [];
  String? _courseCode;
  ResourceType _type = ResourceType.notes;
  bool _busy = false;
  String? _error;

  static List<ClassSlot> _distinct(List<ClassSlot> slots) {
    final byCode = <String, ClassSlot>{};
    for (final s in slots) {
      byCode.putIfAbsent(s.courseCode, () => s);
    }
    return byCode.values.toList()
      ..sort((a, b) => a.courseCode.compareTo(b.courseCode));
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final course = _courses
        .where((c) => c.courseCode == _courseCode)
        .firstOrNull;
    if (course == null) {
      setState(() => _error = context.tr('Choose a course.'));
      return;
    }
    final failed = context.tr(
      'Could not save the resource. Check your permissions.',
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.addResource(
        lecturer: widget.lecturer,
        course: course,
        title: _title.text,
        url: _url.text,
        type: _type,
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
      title: Text(context.tr('Add resource')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<List<ClassSlot>>(
                  stream: _timetable,
                  builder: (context, snapshot) {
                    _courses = _distinct(snapshot.data ?? const []);
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
                      onChanged: (code) => setState(() => _courseCode = code),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SegmentedButton<ResourceType>(
                  segments: [
                    for (final t in ResourceType.values)
                      ButtonSegment(
                        value: t,
                        label: Text(context.tr(_labelFor(t))),
                      ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(labelText: context.tr('Title')),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty || v.trim().length > 120)
                      ? context.tr('Enter a title.')
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: context.tr('Link (https://...)'),
                  ),
                  validator: (v) => (v == null || !isValidResourceUrl(v))
                      ? context.tr('Enter a secure link starting with https://')
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: scheme.error)),
                ],
              ],
            ),
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
