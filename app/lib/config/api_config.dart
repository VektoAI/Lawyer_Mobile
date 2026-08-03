/// Auth/billing API — same FastAPI app as production (Render or local uvicorn).
library;

class ApiConfig {
  /// Production APK / device testing against Render:
  /// `flutter build apk --release --dart-define=MUNSHI_API_BASE=https://your-service.onrender.com`
  /// Local dev on emulator: `http://10.0.2.2:4173` (Android) or LAN IP for a USB phone.
  static const baseUrl = String.fromEnvironment(
    'MUNSHI_API_BASE',
    defaultValue: 'http://127.0.0.1:4173',
  );

  static String get apiRoot => '$baseUrl/api';

  /// Render free tier cold starts can take 30–50s; keep all API calls consistent.
  static const requestTimeout = Duration(seconds: 60);

  /// Supabase email-confirm redirect — must match Supabase Dashboard → Auth → URL configuration.
  static const emailConfirmRedirect = String.fromEnvironment(
    'MUNSHI_AUTH_REDIRECT',
    defaultValue: 'casevault://auth/confirm',
  );

  static String get displayHost {
    try {
      return Uri.parse(baseUrl).host;
    } catch (_) {
      return baseUrl;
    }
  }

  /// True when APK was built without a production API URL (won't work on a physical phone).
  static bool get isLocalDevApi {
    final host = displayHost.toLowerCase();
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host.startsWith('192.168.') ||
        host.startsWith('10.');
  }

  static bool get usesHttps {
    try {
      return Uri.parse(baseUrl).scheme == 'https';
    } catch (_) {
      return false;
    }
  }
}
