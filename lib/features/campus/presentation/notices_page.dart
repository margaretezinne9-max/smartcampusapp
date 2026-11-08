import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../../../core/widgets/royal_page_header.dart';
import '../../auth/domain/app_user.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';
import '../domain/notice_logic.dart';
import 'notice_card.dart';

/// Notices and events, newest first, updating live. Each user only sees the
/// notices meant for their department and level. Admins ([canManage]) see
/// everything and can publish and delete.
class NoticesPage extends StatelessWidget {
  const NoticesPage({
    super.key,
    required this.user,
    required this.repository,
    this.canManage = false,
  });

  final AppUser user;
  final CampusRepository repository;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PublishNoticeDialog(
                  repository: repository,
                  authorName: user.name,
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(context.tr('Publish notice')),
            )
          : null,
      body: StreamView<List<Notice>>(
        open: repository.watchNotices,
        builder: (context, all) {
          final notices = visibleNotices(all, user);
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                children: [
                  RoyalPageHeader(
                    title: context.tr('Campus notices'),
                    subtitle: context.tr(
                      'Important updates and announcements from your university.',
                    ),
                    icon: Icons.campaign_rounded,
                  ),
                  RoyalSectionHeading(context.tr('Latest updates')),
                  if (notices.isEmpty)
                    Text(context.tr('No notices have been published.')),
                  for (final n in notices)
                    NoticeCard(
                      notice: n,
                      onDelete: canManage
                          ? () => repository.deleteNotice(n.id)
                          : null,
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

class PublishNoticeDialog extends StatefulWidget {
  const PublishNoticeDialog({
    super.key,
    required this.repository,
    required this.authorName,
  });

  final CampusRepository repository;
  final String authorName;

  @override
  State<PublishNoticeDialog> createState() => _PublishNoticeDialogState();
}

class _PublishNoticeDialogState extends State<PublishNoticeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  NoticeCategory _category = NoticeCategory.notice;
  DateTime? _eventDate;
  String? _department;
  int? _level;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _publish() async {
    final failMessage = context.tr(
      'Could not publish. Check your connection and permissions.',
    );
    if (!_formKey.currentState!.validate()) return;
    if (_category == NoticeCategory.event && _eventDate == null) {
      setState(() => _error = context.tr('Pick the event date.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.publishNotice(
        title: _title.text.trim(),
        body: _body.text.trim(),
        category: _category,
        eventDate: _category == NoticeCategory.event ? _eventDate : null,
        department: _department,
        level: _level,
        authorName: widget.authorName,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = failMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(context.tr('Publish a notice')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<NoticeCategory>(
                  segments: [
                    ButtonSegment(
                      value: NoticeCategory.notice,
                      label: Text(context.tr('Notice')),
                      icon: const Icon(Icons.campaign_outlined),
                    ),
                    ButtonSegment(
                      value: NoticeCategory.event,
                      label: Text(context.tr('Event')),
                      icon: const Icon(Icons.event_outlined),
                    ),
                  ],
                  selected: {_category},
                  onSelectionChanged: (s) =>
                      setState(() => _category = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(labelText: context.tr('Title')),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? context.tr('Enter a title.')
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _body,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: context.tr('Details')),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? context.tr('Enter the details.')
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _department,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('Audience'),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(context.tr('All departments')),
                    ),
                    for (final d in CampusRules.departments)
                      DropdownMenuItem<String?>(value: d, child: Text(d)),
                  ],
                  onChanged: (v) => setState(() => _department = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  // ignore: deprecated_member_use
                  value: _level,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(context.tr('All levels')),
                    ),
                    for (final l in CampusRules.levels)
                      DropdownMenuItem<int?>(
                        value: l,
                        child: Text(context.tr('Level {n}', {'n': '$l'})),
                      ),
                  ],
                  onChanged: (v) => setState(() => _level = v),
                ),
                if (_category == NoticeCategory.event) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      _eventDate == null
                          ? context.tr('Pick event date')
                          : formatDay(_eventDate!, lang: context.lang),
                    ),
                  ),
                ],
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
          onPressed: _busy ? null : _publish,
          child: Text(context.tr('Publish')),
        ),
      ],
    );
  }
}
