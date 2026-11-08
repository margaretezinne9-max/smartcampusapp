import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../domain/campus_models.dart';

/// Compact two-column event cards for the Royal Emerald home dashboard.
class EventBar extends StatelessWidget {
  const EventBar({super.key, required this.events, required this.now});

  final List<Notice> events;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          context.tr('No upcoming events.'),
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 390 ? 1 : 2;
        final gap = 10.0;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final event in events.take(4))
              SizedBox(
                width: width,
                child: _EventTile(event: event, now: now),
              ),
          ],
        );
      },
    );
  }
}

String _countdownLabel(BuildContext context, DateTime date, DateTime now) {
  final days = daysUntil(date, now);
  if (days <= 0) return context.tr('Today');
  if (days == 1) return context.tr('Tomorrow');
  return context.tr('In {n} days', {'n': '$days'});
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.now});
  final Notice event;
  final DateTime now;

  void _showDetails(BuildContext context) {
    final date = event.eventDate!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                '${formatDay(date, lang: context.lang)} • ${_countdownLabel(context, date, now)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 14),
              Text(event.body),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = event.eventDate!;
    final day = date.day.toString().padLeft(2, '0');
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final month = context.lang == 'fr'
        ? formatDay(date, lang: context.lang).split(' ')[1].toUpperCase()
        : months[date.month - 1];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _showDetails(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE5ECE7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF173D2A).withValues(alpha: .05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      month,
                      style: const TextStyle(
                        color: Color(0xFF087342),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      day,
                      style: const TextStyle(
                        color: Color(0xFF075B36),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C2921),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _countdownLabel(context, date, now),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF587064),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF075B36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
