import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/widgets/royal_page_header.dart';
import '../../../core/widgets/stream_view.dart';
import '../../auth/domain/app_user.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';
import '../domain/notice_logic.dart';

/// Dedicated, inviting events directory backed by the same live notice stream.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key, required this.user, required this.repository});

  final AppUser user;
  final CampusRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Notice>>(
      open: repository.watchNotices,
      builder: (context, all) {
        final now = DateTime.now();
        final events =
            visibleNotices(all, user)
                .where(
                  (n) =>
                      n.category == NoticeCategory.event && n.eventDate != null,
                )
                .toList()
              ..sort((a, b) => a.eventDate!.compareTo(b.eventDate!));
        final upcoming = events
            .where(
              (e) => !e.eventDate!.isBefore(
                DateTime(now.year, now.month, now.day),
              ),
            )
            .toList();
        final past = events
            .where(
              (e) =>
                  e.eventDate!.isBefore(DateTime(now.year, now.month, now.day)),
            )
            .toList()
            .reversed
            .toList();

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                RoyalPageHeader(
                  title: context.tr('Campus events'),
                  subtitle: context.tr(
                    'Discover what is happening around your university.',
                  ),
                  icon: Icons.celebration_rounded,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _EventStat(
                        value: '${upcoming.length}',
                        label: context.tr('Upcoming'),
                        icon: Icons.event_available_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _EventStat(
                        value: '${past.length}',
                        label: context.tr('Past events'),
                        icon: Icons.history_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                RoyalSectionHeading(context.tr('Coming up')),
                if (upcoming.isEmpty)
                  _EmptyEvents(
                    message: context.tr(
                      'No upcoming events. Check back soon for campus activities.',
                    ),
                  ),
                for (final event in upcoming)
                  _EventCard(event: event, past: false),
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  RoyalSectionHeading(context.tr('Past events')),
                  for (final event in past)
                    _EventCard(event: event, past: true),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventStat extends StatelessWidget {
  const _EventStat({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE6EEE8)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF087342), size: 22),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF173D2A),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF66776D)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.past});
  final Notice event;
  final bool past;
  @override
  Widget build(BuildContext context) {
    final date = event.eventDate!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EEE8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173D2A).withValues(alpha: .045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(ctx).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatDay(date, lang: context.lang)} • ${event.authorName}',
                    style: const TextStyle(
                      color: Color(0xFF087342),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(event.body),
                ],
              ),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 70,
                decoration: BoxDecoration(
                  color: past
                      ? const Color(0xFFF0F2F0)
                      : const Color(0xFFE2F4E9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formatDay(
                        date,
                        lang: context.lang,
                      ).split(' ').first.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF087342),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: const TextStyle(
                        fontSize: 25,
                        color: Color(0xFF075B36),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      past
                          ? context.tr('PAST EVENT')
                          : context.tr('CAMPUS EVENT'),
                      style: const TextStyle(
                        color: Color(0xFFB17A08),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2921),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF68776E),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Color(0xFF087342),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE6EEE8)),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.event_busy_rounded,
          size: 34,
          color: Color(0xFF7A9A86),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF68776E)),
        ),
      ],
    ),
  );
}
