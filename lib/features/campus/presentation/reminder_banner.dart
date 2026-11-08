import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/settings/app_settings.dart';
import '../../auth/domain/app_user.dart';
import '../domain/campus_models.dart';
import '../domain/campus_repository.dart';
import '../domain/next_class.dart';

/// "Class starts in 10 min" banner, shown on every tab while the app is open
/// and a class is about to start. The lead time comes from the user's
/// settings (0 = off). [clock] lets tests fix the current time.
///
/// Notifications while the app is closed need Android local notifications
/// and push, which come in a later phase.
class ReminderBanner extends StatefulWidget {
  const ReminderBanner({
    super.key,
    required this.user,
    required this.repository,
    this.clock,
  });

  final AppUser user;
  final CampusRepository repository;
  final DateTime Function()? clock;

  @override
  State<ReminderBanner> createState() => _ReminderBannerState();
}

class _ReminderBannerState extends State<ReminderBanner> {
  late final Stream<List<ClassSlot>> _stream = widget.repository.watchTimetable(
    widget.user,
  );
  Timer? _timer;
  String? _dismissedKey;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    if (settings == null || settings.reminderMinutes == 0) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<ClassSlot>>(
      stream: _stream,
      builder: (context, snapshot) {
        final slots = snapshot.data;
        if (slots == null) return const SizedBox.shrink();

        final now = _now();
        final next = findNextClass(slots, now, skipOngoing: true);
        if (next == null) return const SizedBox.shrink();

        final until = next.untilStart(now);
        if (until > Duration(minutes: settings.reminderMinutes)) {
          return const SizedBox.shrink();
        }

        final key = '${next.slot.id}@${next.start.toIso8601String()}';
        if (_dismissedKey == key) return const SizedBox.shrink();

        return MaterialBanner(
          leading: const Icon(Icons.alarm),
          content: Text(
            context.tr('{course} starts in {time}. {hall}, {campus}.', {
              'course': next.slot.courseTitle,
              'time': formatCountdown(until, lang: context.lang),
              'hall': next.slot.hallName,
              'campus': next.slot.campusName,
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => setState(() => _dismissedKey = key),
              child: Text(context.tr('Dismiss')),
            ),
          ],
        );
      },
    );
  }
}
