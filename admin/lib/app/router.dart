import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:la_favola_admin/app/admin_shell.dart';
import 'package:la_favola_admin/app/providers.dart';
import 'package:la_favola_admin/features/audit/presentation/audit_page.dart';
import 'package:la_favola_admin/features/auth/presentation/sign_in_page.dart';
import 'package:la_favola_admin/features/auth/presentation/forgot_password_page.dart';
import 'package:la_favola_admin/features/dashboard/presentation/dashboard_page.dart';
import 'package:la_favola_admin/features/finance/presentation/refunds_page.dart';
import 'package:la_favola_admin/features/media/presentation/media_library_page.dart';
import 'package:la_favola_admin/features/pos/presentation/pos_page.dart';
import 'package:la_favola_admin/features/navigation/presentation/admin_feature_hubs.dart';
import 'package:la_favola_admin/features/reports/presentation/reports_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider);
  return GoRouter(
    initialLocation: session.isAuthenticated ? '/dashboard' : '/login',
    redirect: (context, state) {
      final login = state.matchedLocation == '/login';
      final publicAuth = login || state.matchedLocation == '/forgot-password';
      if (session.status == SessionStatus.restoring) return '/restore';
      if (!session.isAuthenticated) return publicAuth ? null : '/login';
      if (publicAuth || state.matchedLocation == '/restore') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const SignInPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/restore', builder: (_, __) => const _RestorePage()),
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(path: '/pos', builder: (_, __) => const PosPage()),
          GoRoute(
            path: '/orders',
            builder:
                (_, __) =>
                    OrdersWorkspacePage(api: ref.read(apiClientProvider)),
          ),
          GoRoute(
            path: '/deliveries',
            builder:
                (_, __) =>
                    DeliveryWorkspacePage(api: ref.read(apiClientProvider)),
          ),
          GoRoute(path: '/refunds', builder: (_, __) => const RefundsPage()),
          GoRoute(
            path: '/support',
            builder:
                (_, __) =>
                    SupportWorkspacePage(api: ref.read(apiClientProvider)),
          ),
          GoRoute(
            path: '/catalogue',
            builder:
                (_, __) =>
                    CatalogueWorkspacePage(api: ref.read(apiClientProvider)),
          ),
          GoRoute(
            path: '/offers',
            builder:
                (_, __) =>
                    OffersWorkspacePage(api: ref.read(apiClientProvider)),
          ),
          GoRoute(path: '/media', builder: (_, __) => const MediaLibraryPage()),
          GoRoute(
            path: '/people',
            builder:
                (_, __) =>
                    TeamAccessWorkspacePage(api: ref.read(apiClientProvider)),
          ),
          GoRoute(
            path: '/restaurant',
            builder:
                (_, __) =>
                    SettingsWorkspacePage(api: ref.read(apiClientProvider)),
          ),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
          GoRoute(
            path: '/notifications',
            builder:
                (_, __) => NotificationsWorkspacePage(
                  api: ref.read(apiClientProvider),
                ),
          ),
          GoRoute(path: '/audit', builder: (_, __) => const AuditPage()),
        ],
      ),
    ],
  );
});

class _RestorePage extends StatelessWidget {
  const _RestorePage();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Semantics(
        label: 'Ripristino della sessione amministrativa',
        child: const CircularProgressIndicator(),
      ),
    ),
  );
}
