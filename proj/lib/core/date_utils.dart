/// Tiny date helpers so we don't need the intl package.
String dayKeyOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime dateOfKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];
String monthShort(DateTime d) => _months[d.month - 1];
String prettyDate(DateTime d) => '${weekdayShort(d)}, ${monthShort(d)} ${d.day}';
