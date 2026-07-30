library;

/// Integer rupees only — CLAUDE.md invariant 6. Indian digit grouping
/// (lakh/crore): ₹12,34,567 — not the Western ₹1,234,567.
String rupee(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${negative ? '-' : ''}₹$grouped';
}
