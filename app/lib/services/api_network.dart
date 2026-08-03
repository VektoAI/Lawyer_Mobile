library;

import 'dart:async';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/perf_log.dart';
import 'auth_service.dart';

/// Maps socket/HTTP client failures to user-facing [AuthException] messages.
Never rethrowNetworkFailure(Object error, {String? host}) {
  final target = host ?? ApiConfig.displayHost;
  if (error is TimeoutException) {
    throw AuthException(
      'Server is taking too long to respond (it may be waking up after being idle) — please try again.',
    );
  }
  if (error is SocketException) {
    throw AuthException('No network connection — check Wi‑Fi or mobile data.');
  }
  if (error is http.ClientException) {
    throw AuthException(
        'Could not reach the server ($target). Check network or API URL.');
  }
  throw AuthException(
      'Could not reach the server ($target). Check network or API URL.');
}

Future<T> withApiTimeout<T>(Future<T> future) =>
    PerfLog.timeAsync('api.request', () => future.timeout(ApiConfig.requestTimeout));
