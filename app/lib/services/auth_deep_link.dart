library;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Listens for `casevault://auth/confirm` (Supabase email verification).
final authDeepLinkProvider = Provider<AuthDeepLinkNotifier>((ref) {
  final n = AuthDeepLinkNotifier(ref);
  n.init();
  ref.onDispose(n.dispose);
  return n;
});

class AuthDeepLinkNotifier {
  AuthDeepLinkNotifier(Ref ref);

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  final pendingUri = ValueNotifier<Uri?>(null);

  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null && _isAuthConfirm(initial)) {
        pendingUri.value = initial;
      }
    } catch (_) {}
    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (_isAuthConfirm(uri)) pendingUri.value = uri;
    });
  }

  bool _isAuthConfirm(Uri uri) {
    if (uri.scheme != 'casevault') return false;
    return uri.host == 'auth' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'confirm';
  }

  void dispose() {
    _sub?.cancel();
  }
}
