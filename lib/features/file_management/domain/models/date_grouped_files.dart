import 'kappogy_file.dart';

class DateGroupedFiles {
  final String title;
  final DateTime date;
  final List<KappogyFile> files;

  const DateGroupedFiles({
    required this.title,
    required this.date,
    required this.files,
  });

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  /// Formats a DateTime as "Monday, August 24" or "Monday, August 24, 2025"
  static String formatDateHeader(DateTime dt) {
    final weekday = _weekdays[dt.weekday - 1];
    final month = _months[dt.month - 1];
    final day = dt.day;
    final now = DateTime.now();

    if (dt.year == now.year) {
      return '$weekday, $month $day';
    } else {
      return '$weekday, $month $day, ${dt.year}';
    }
  }

  /// Groups a flat list of [KappogyFile] objects into date buckets.
  static List<DateGroupedFiles> groupFiles(List<KappogyFile> items) {
    if (items.isEmpty) return [];

    final Map<String, List<KappogyFile>> map = {};
    final Map<String, DateTime> dateMap = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final file in items) {
      final modified = file.lastModified ?? now;
      final fileDate = DateTime(modified.year, modified.month, modified.day);

      String header;
      if (fileDate == today) {
        header = 'Today';
      } else if (fileDate == yesterday) {
        header = 'Yesterday';
      } else {
        header = formatDateHeader(fileDate);
      }

      if (!map.containsKey(header)) {
        map[header] = [];
        dateMap[header] = fileDate;
      }
      map[header]!.add(file);
    }

    final groups = map.entries.map((e) {
      return DateGroupedFiles(
        title: e.key,
        date: dateMap[e.key] ?? now,
        files: e.value,
      );
    }).toList();

    // Sort groups descending by date
    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }
}
