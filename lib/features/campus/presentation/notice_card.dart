import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../domain/campus_models.dart';

class NoticeCard extends StatelessWidget {
  const NoticeCard({super.key, required this.notice, this.onDelete});

  final Notice notice;

  /// When set (admins), a delete button is shown.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isEvent = notice.category == NoticeCategory.event;
    final date = notice.eventDate;
    final lang = context.lang;

    var when = (isEvent && date != null)
        ? context.tr('Event date: {date}', {
            'date': formatDay(date, lang: lang),
          })
        : context.tr('Posted {date}', {
            'date': formatDay(notice.createdAt, lang: lang),
          });

    final audience = [
      if (notice.department != null) notice.department!,
      if (notice.level != null)
        context.tr('Level {n}', {'n': '${notice.level}'}),
    ];
    if (audience.isNotEmpty) {
      when +=
          ' - ${context.tr('For {audience}', {'audience': audience.join(', ')})}';
    }

    return Card.outlined(
      child: ListTile(
        leading: Icon(isEvent ? Icons.event_outlined : Icons.campaign_outlined),
        title: Text(notice.title),
        isThreeLine: true,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notice.body),
            const SizedBox(height: 4),
            Text(when, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        trailing: onDelete == null
            ? null
            : IconButton(
                tooltip: context.tr('Delete notice'),
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
      ),
    );
  }
}
