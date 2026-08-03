import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_network.dart';

class BootstrapStatus {
  const BootstrapStatus({required this.ok, this.mode, this.message = ''});
  final bool ok;
  final String? mode;
  final String message;
}

/// Auth/billing health — same probe as munshi-ui verify sheet (`/api/healthz` or `/healthz`).
Future<BootstrapStatus> fetchBootstrapStatus() async {
  for (final path in ['/api/healthz', '/healthz']) {
    try {
      final res = await withApiTimeout(
        http.get(Uri.parse('${ApiConfig.baseUrl}$path')),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;
        return BootstrapStatus(
          ok: true,
          mode: body?['mode'] as String?,
          message: 'API reachable',
        );
      }
    } catch (_) {}
  }
  return const BootstrapStatus(
      ok: false, message: 'API unreachable (offline OK for demo)');
}
