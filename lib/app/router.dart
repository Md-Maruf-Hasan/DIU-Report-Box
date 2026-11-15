import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/models/lost_found_model.dart';
import '../core/models/qa_post_model.dart';
import '../core/models/report_model.dart';
import '../core/models/resource_model.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/lost_found/presentation/create_lost_found_screen.dart';
import '../features/lost_found/presentation/lost_found_detail_screen.dart';
import '../features/lost_found/presentation/lost_found_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/qa/presentation/create_qa_screen.dart';
import '../features/qa/presentation/qa_detail_screen.dart';
import '../features/qa/presentation/qa_feed_screen.dart';
import '../features/reports/presentation/report_detail_screen.dart';
import '../features/reports/presentation/submit_report_screen.dart';
import '../features/resources/presentation/resource_detail_screen.dart';
import '../features/resources/presentation/resources_screen.dart';
import '../features/resources/presentation/upload_resource_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _lostFoundNavKey = GlobalKey<NavigatorState>();
final _qaNavKey = GlobalKey<NavigatorState>();
final _reportNavKey = GlobalKey<NavigatorState>();
final _resourceNavKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/lost-found',
    redirect: (context, state) {
      final user = authState.value;
      final isAuthLoading = authState.isLoading;
      final location = state.matchedLocation;

      if (isAuthLoading) return null;

      final isAuthRoute = location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password';

      // 1. Not signed in
      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      // 2. Signed in but email unverified
      if (!user.emailVerified) {
        return location == '/verify-email' ? null : '/verify-email';
      }

      // 3. Signed in & verified
      if (isAuthRoute || location == '/verify-email') {
        return '/lost-found';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Profile & Admin
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // 4 Main Sections inside StatefulShellRoute
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Lost & Found
          StatefulShellBranch(
            navigatorKey: _lostFoundNavKey,
            routes: [
              GoRoute(
                path: '/lost-found',
                builder: (context, state) => const LostFoundScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreateLostFoundScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final item = state.extra as LostFoundModel;
                      return LostFoundDetailScreen(item: item);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Q&A
          StatefulShellBranch(
            navigatorKey: _qaNavKey,
            routes: [
              GoRoute(
                path: '/qa',
                builder: (context, state) => const QaFeedScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreateQaScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final post = state.extra as QaPostModel;
                      return QaDetailScreen(post: post);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Maintenance Report
          StatefulShellBranch(
            navigatorKey: _reportNavKey,
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const SpecificReportMainScreen(),
              ),
            ],
          ),

          // Branch 4: Resources
          StatefulShellBranch(
            navigatorKey: _resourceNavKey,
            routes: [
              GoRoute(
                path: '/resources',
                builder: (context, state) => const ResourcesScreen(),
                routes: [
                  GoRoute(
                    path: 'upload',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final sub = (state.extra as String?) ?? 'previous_questions';
                      return UploadResourceScreen(initialSubsection: sub);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final res = state.extra as ResourceModel;
                      return ResourceDetailScreen(resource: res);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Single report detail route
      GoRoute(
        path: '/report/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final rep = state.extra as ReportModel;
          return ReportDetailScreen(report: rep);
        },
      ),
    ],
  );
});
