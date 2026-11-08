import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../../../core/widgets/royal_page_header.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';
import 'campus_info_sheet.dart';

/// Weekly timetable grouped by day. Tap a class for hall and campus details.
class TimetablePage extends StatelessWidget {
  const TimetablePage({
    super.key,
    required this.user,
    required this.repository,
  });

  final AppUser user;
  final CampusRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamView<List<ClassSlot>>(
      open: () => repository.watchTimetable(user),
      builder: (context, slots) => StreamView<List<Campus>>(
        open: repository.watchCampuses,
        builder: (context, campuses) => _TimetableList(
          slots: slots,
          campuses: campuses,
          isLecturer: user.role == UserRole.lecturer,
        ),
      ),
    );
  }
}

class _TimetableList extends StatelessWidget {
  const _TimetableList({
    required this.slots,
    required this.campuses,
    required this.isLecturer,
  });

  final List<ClassSlot> slots;
  final List<Campus> campuses;
  final bool isLecturer;

  String _subtitle(BuildContext context, ClassSlot s) {
    final place = '${s.hallName}, ${s.campusName}';
    if (!isLecturer) return place;
    final audience = context.tr('{department}, level {level}', {
      'department': s.department,
      'level': '${s.level}',
    });
    return '$place\n$audience';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final today = DateTime.now().weekday;
    final lang = context.lang;

    final byDay = <int, List<ClassSlot>>{};
    for (final s in slots) {
      byDay.putIfAbsent(s.weekday, () => []).add(s);
    }
    final days = byDay.keys.toList()..sort();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            RoyalPageHeader(
              title: context.tr('My timetable'),
              subtitle: context.tr(
                'Your weekly classes, venues and campus locations at a glance.',
              ),
              icon: Icons.calendar_month_rounded,
            ),
            RoyalSectionHeading(context.tr('Weekly schedule')),
            if (slots.isEmpty)
              Text(context.tr('Your timetable is empty for now.')),
            for (final day in days) ...[
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Row(
                  children: [
                    Text(
                      weekdayName(day, lang: lang),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF173D2A),
                      ),
                    ),
                    if (day == today) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(context.tr('Today')),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFDDF3E5),
                        side: BorderSide.none,
                      ),
                    ],
                  ],
                ),
              ),
              for (final s
                  in (byDay[day]!
                    ..sort((a, b) => a.startMinute.compareTo(b.startMinute))))
                Card.outlined(
                  child: ListTile(
                    leading: SizedBox(
                      width: 56,
                      child: Text(
                        '${formatClock(s.startMinute)}\n${formatClock(s.endMinute)}',
                        textAlign: TextAlign.center,
                        style: text.labelLarge,
                      ),
                    ),
                    title: Text('${s.courseCode} - ${s.courseTitle}'),
                    subtitle: Text(_subtitle(context, s)),
                    isThreeLine: isLecturer,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showCampusInfo(
                      context,
                      slot: s,
                      campus: campuses
                          .where((c) => c.id == s.campusId)
                          .firstOrNull,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
