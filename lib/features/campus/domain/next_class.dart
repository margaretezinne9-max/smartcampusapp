import 'campus_models.dart';

/// The class a user should attend next, with its real date and time.
class NextClass {
  const NextClass({required this.slot, required this.start, required this.end});

  final ClassSlot slot;
  final DateTime start;
  final DateTime end;

  bool isOngoingAt(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  Duration untilStart(DateTime now) => start.difference(now);
}

/// Finds the earliest class that has not finished yet, looking up to a week
/// ahead. A class that is happening right now counts as "next", unless
/// [skipOngoing] is true (used for reminders, which only care about classes
/// that have not started).
NextClass? findNextClass(
  Iterable<ClassSlot> slots,
  DateTime now, {
  bool skipOngoing = false,
}) {
  NextClass? best;

  for (final slot in slots) {
    DateTime at(int days, int minute) =>
        DateTime(now.year, now.month, now.day + days, 0, minute);

    // Dart's % is never negative, so this is "days until that weekday".
    var days = (slot.weekday - now.weekday) % 7;
    var start = at(days, slot.startMinute);
    var end = at(days, slot.endMinute);

    // Already finished (or, when skipping, already started) -> next week.
    final passed = !end.isAfter(now) || (skipOngoing && start.isBefore(now));
    if (passed) {
      days += 7;
      start = at(days, slot.startMinute);
      end = at(days, slot.endMinute);
    }

    if (best == null || start.isBefore(best.start)) {
      best = NextClass(slot: slot, start: start, end: end);
    }
  }
  return best;
}
