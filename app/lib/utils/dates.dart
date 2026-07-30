library;

String dayOffsetIso(int n) {
  final d = DateTime.now();
  final local = DateTime(d.year, d.month, d.day, 12).add(Duration(days: n));
  return _isoDate(local);
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String get todayIso => dayOffsetIso(0);
String get tomorrowIso => dayOffsetIso(1);

String fmtShort(String iso) {
  try {
    final p = iso.split('-');
    if (p.length != 3) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = int.parse(p[1]);
    return '${p[2]} ${months[m - 1]}';
  } catch (_) {
    return iso;
  }
}

bool isSameIso(String? a, String? b) => a != null && b != null && a == b;

int daysBetweenIso(String iso) {
  try {
    final p = iso.split('-');
    final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    return d.difference(today).inDays;
  } catch (_) {
    return 999;
  }
}
