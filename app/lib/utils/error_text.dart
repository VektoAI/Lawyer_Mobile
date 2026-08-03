/// Turns a caught exception into a clean, user-facing sentence.
///
/// Dart's built-in exception types prefix their `toString()` with internal
/// jargon (`StateError` → "Bad state: ...", a bare `Exception('...')` →
/// "Exception: ...") that reads as an unhandled crash rather than a normal
/// app message. Screens already catch these and show `'<action> failed:
/// $e'` in a SnackBar — this strips that jargon so the message stays a
/// plain sentence a lawyer would trust, without hiding what actually went
/// wrong.
library;

const _internalPrefixes = ['Bad state: ', 'Exception: ', 'FormatException: '];

String friendlyError(Object error) {
  final text = error.toString();
  for (final prefix in _internalPrefixes) {
    if (text.startsWith(prefix)) return text.substring(prefix.length);
  }
  return text;
}
