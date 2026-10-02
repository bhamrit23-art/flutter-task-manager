import 'package:intl/intl.dart';

/// Whole days from today to [date], negative when it is in the past.
/// Compared in UTC so daylight-saving changes cannot shift the result.
int daysFromToday(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(today.year, today.month, today.day))
      .inDays;
}

/// "Today", "Tomorrow", "Yesterday", otherwise a short date such as "12 Oct"
/// (with the year when it is not the current one).
String formatDueDate(DateTime dueDate, {DateTime? now}) {
  final today = now ?? DateTime.now();
  switch (daysFromToday(dueDate, now: today)) {
    case 0:
      return 'Today';
    case 1:
      return 'Tomorrow';
    case -1:
      return 'Yesterday';
  }
  final pattern = dueDate.year == today.year ? 'd MMM' : 'd MMM y';
  return DateFormat(pattern).format(dueDate);
}

/// Full date for forms, e.g. "Fri, 2 Oct 2026".
String formatLongDate(DateTime date) => DateFormat('EEE, d MMM y').format(date);

/// Date and time a task was created, e.g. "2 Oct 2026, 3:45 PM".
String formatTimestamp(DateTime date) =>
    DateFormat('d MMM y, h:mm a').format(date);

String greetingFor(DateTime time) {
  if (time.hour < 12) return 'Good morning';
  if (time.hour < 17) return 'Good afternoon';
  return 'Good evening';
}
