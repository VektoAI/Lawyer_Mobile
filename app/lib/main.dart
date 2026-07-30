library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/app_providers.dart';
import 'router_refresh.dart';
import 'services/hearing_reminder_service.dart';
import 'screens/archived_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/case_detail_screen.dart';
import 'screens/cases_screen.dart';
import 'screens/docs_screen.dart';
import 'screens/fees_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';
import 'widgets/auth_deep_link_host.dart';

final _rootNavKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HearingReminderService.instance.init();
  runApp(
    const ProviderScope(
      child: AuthDeepLinkHost(child: MunshiMobileApp()),
    ),
  );
}

final _router = GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, __, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/cases', builder: (_, __) => const CasesScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (_, state) => CalendarScreen(initialDay: state.uri.queryParameters['day']),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/fees', builder: (_, __) => const FeesScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/docs', builder: (_, __) => const DocsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/cases/:caseId',
      builder: (_, state) => CaseDetailScreen(caseId: state.pathParameters['caseId']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/archived',
      builder: (_, __) => const ArchivedScreen(),
    ),
  ],
  redirect: (context, state) {
    final loc = state.matchedLocation;
    final container = ProviderScope.containerOf(context);
    final vault = container.read(vaultStoreProvider);
    if (loc == '/login' && vault.isUnlocked) return '/cases';
    if (loc == '/login') return null;
    if (!vault.isUnlocked) return '/login';
    return null;
  },
  refreshListenable: RouterRefresh.instance,
);

class MunshiMobileApp extends StatelessWidget {
  const MunshiMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Case Vault (internal)',
      theme: munshiTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
