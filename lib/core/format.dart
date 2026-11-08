/// Small date/time helpers (no external packages). Every function takes an
/// optional [lang] ('en' or 'fr') and defaults to English.
const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _weekdaysFr = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _monthsFr = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// 1 = Monday ... 7 = Sunday (same as DateTime.weekday).
String weekdayName(int weekday, {String lang = 'en'}) =>
    (lang == 'fr' ? _weekdaysFr : _weekdays)[(weekday - 1) % 7];

/// Minutes after midnight -> "08:00".
String formatClock(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

/// "22 Oct 2026" / "22 oct. 2026".
String formatDay(DateTime d, {String lang = 'en'}) =>
    '${d.day} ${(lang == 'fr' ? _monthsFr : _months)[d.month - 1]} ${d.year}';

/// Whole calendar days from [now] to [date] (0 = today).
int daysUntil(DateTime date, DateTime now) => DateTime(
  date.year,
  date.month,
  date.day,
).difference(DateTime(now.year, now.month, now.day)).inDays;

/// "Today", "Tomorrow" or the weekday name of [date] relative to [now].
String dayLabel(DateTime date, DateTime now, {String lang = 'en'}) {
  final diff = daysUntil(date, now);
  if (diff == 0) return lang == 'fr' ? "Aujourd'hui" : 'Today';
  if (diff == 1) return lang == 'fr' ? 'Demain' : 'Tomorrow';
  return weekdayName(date.weekday, lang: lang);
}

/// "45 min", "2 h 15 min", "3 days" / "3 jours".
String formatCountdown(Duration d, {String lang = 'en'}) {
  final fr = lang == 'fr';
  final minutes = d.inMinutes;
  if (minutes < 1) return fr ? "moins d'une minute" : 'less than a minute';
  if (minutes < 60) return '$minutes min';
  final hours = d.inHours;
  if (hours < 24) {
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }
  final days = d.inDays;
  if (fr) return days == 1 ? '1 jour' : '$days jours';
  return days == 1 ? '1 day' : '$days days';
}

/// 90 -> "1 h 30 min", 120 -> "2 h", 45 -> "45 min".
String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}

/// Start and end of an exam or class as "09:00 - 11:00".
String formatTimeRange(DateTime start, DateTime end) =>
    '${formatClock(start.hour * 60 + start.minute)} - ${formatClock(end.hour * 60 + end.minute)}';
