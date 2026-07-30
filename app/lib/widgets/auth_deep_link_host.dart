library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_deep_link.dart';

/// Wires AppLinks into the widget tree (must sit under [ProviderScope]).
class AuthDeepLinkHost extends ConsumerStatefulWidget {
  const AuthDeepLinkHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthDeepLinkHost> createState() => _AuthDeepLinkHostState();
}

class _AuthDeepLinkHostState extends ConsumerState<AuthDeepLinkHost> {
  @override
  void initState() {
    super.initState();
    ref.read(authDeepLinkProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
