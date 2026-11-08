import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/format.dart';

void main() {
  test('formatClock turns minutes into HH:MM', () {
    expect(formatClock(0), '00:00');
    expect(formatClock(480), '08:00');
    expect(formatClock(1005), '16:45');
  });

  test('weekdayName uses 1 = Monday ... 7 = Sunday', () {
    expect(weekdayName(1), 'Monday');
    expect(weekdayName(4), 'Thursday');
    expect(weekdayName(7), 'Sunday');
  });

  test('formatDay writes a short readable date', () {
    expect(formatDay(DateTime(2026, 10, 22)), '22 Oct 2026');
  });

  group('formatCountdown', () {
    test('under a minute', () {
      expect(formatCountdown(Duration.zero), 'less than a minute');
    });

    test('minutes', () {
      expect(formatCountdown(const Duration(minutes: 45)), '45 min');
    });

    test('hours with and without minutes', () {
      expect(formatCountdown(const Duration(minutes: 135)), '2 h 15 min');
      expect(formatCountdown(const Duration(hours: 2)), '2 h');
    });

    test('days', () {
      expect(formatCountdown(const Duration(hours: 30)), '1 day');
      expect(formatCountdown(const Duration(hours: 72)), '3 days');
    });
  });

  test('dayLabel says Today, Tomorrow or the weekday', () {
    final now = DateTime(2026, 10, 26, 10); // Monday
    expect(dayLabel(DateTime(2026, 10, 26, 15), now), 'Today');
    expect(dayLabel(DateTime(2026, 10, 27, 8), now), 'Tomorrow');
    expect(dayLabel(DateTime(2026, 10, 29, 8), now), 'Thursday');
  });

  group('French', () {
    test('weekday and month names', () {
      expect(weekdayName(1, lang: 'fr'), 'Lundi');
      expect(weekdayName(7, lang: 'fr'), 'Dimanche');
      expect(formatDay(DateTime(2026, 10, 22), lang: 'fr'), '22 oct. 2026');
      expect(formatDay(DateTime(2026, 2, 3), lang: 'fr'), '3 févr. 2026');
    });

    test('countdown wording', () {
      expect(formatCountdown(Duration.zero, lang: 'fr'), "moins d'une minute");
      expect(formatCountdown(const Duration(hours: 30), lang: 'fr'), '1 jour');
      expect(formatCountdown(const Duration(hours: 72), lang: 'fr'), '3 jours');
      expect(formatCountdown(const Duration(minutes: 135), lang: 'fr'), '2 h 15 min');
    });

    test('day labels', () {
      final now = DateTime(2026, 10, 26, 10);
      expect(dayLabel(DateTime(2026, 10, 26, 15), now, lang: 'fr'), "Aujourd'hui");
      expect(dayLabel(DateTime(2026, 10, 27, 8), now, lang: 'fr'), 'Demain');
      expect(dayLabel(DateTime(2026, 10, 29, 8), now, lang: 'fr'), 'Jeudi');
    });
  });

  test('daysUntil counts calendar days, not 24-hour blocks', () {
    final lateNight = DateTime(2026, 10, 26, 23, 30);
    expect(daysUntil(DateTime(2026, 10, 27, 0, 10), lateNight), 1);
    expect(daysUntil(DateTime(2026, 10, 26, 8), lateNight), 0);
    expect(daysUntil(DateTime(2026, 10, 25, 8), lateNight), -1);
  });

  test('formatMinutes writes hours and minutes', () {
    expect(formatMinutes(45), '45 min');
    expect(formatMinutes(120), '2 h');
    expect(formatMinutes(90), '1 h 30 min');
    expect(formatMinutes(0), '0 min');
  });

  test('formatTimeRange writes the start and end clock times', () {
    expect(
      formatTimeRange(DateTime(2026, 11, 16, 9), DateTime(2026, 11, 16, 11, 30)),
      '09:00 - 11:30',
    );
  });
}
