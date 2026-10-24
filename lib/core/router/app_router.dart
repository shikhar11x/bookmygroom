import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/appointments/presentation/pass_screen.dart';
import '../../features/appointments/presentation/queue_screen.dart';
import '../../features/appointments/presentation/scan_screen.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/booking/presentation/checkout_screen.dart';
import '../../features/booking/presentation/confirmation_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rewards/presentation/rewards_screen.dart';
import '../../features/reviews/presentation/review_screen.dart';
import '../providers/app_providers.dart';
import 'app_shell.dart';

abstract class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const home = '/home';
  static const explore = '/explore';
  static const appointments = '/appointments';
  static const rewards = '/rewards';
  static const profile = '/profile';
  static const booking = '/booking';
  static const checkout = '/checkout';
  static const scan = '/scan';
  static const queue = '/queue';
  static String reviewPath(String id) => '/review/$id';
  static String confirmedPath(String id) => '/confirmed/$id';
  static String passPath(String id) => '/pass/$id';
}

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (_, _) => refresh.value++);
  ref.listen(onboardingProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(currentUserProvider) != null;
      final seen = ref.read(onboardingProvider);
      final loc = state.matchedLocation;

      if (signedIn) {
        if (loc == AppRoutes.login || loc == AppRoutes.onboarding) {
          return AppRoutes.home;
        }
        return null;
      }

      // Signed out: intro first, then login.
      if (!seen) {
        return loc == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }
      return loc == AppRoutes.login ? null : AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (c, s) => _fadePage(s, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (c, s) => _fadePage(s, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.booking,
        pageBuilder: (c, s) => _fadePage(s, const BookingScreen()),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        pageBuilder: (c, s) => _fadePage(s, const CheckoutScreen()),
      ),
      GoRoute(
        path: AppRoutes.scan,
        pageBuilder: (c, s) => _fadePage(s, const ScanScreen()),
      ),
      GoRoute(
        path: AppRoutes.queue,
        pageBuilder: (c, s) => _fadePage(s, const QueueScreen()),
      ),
      GoRoute(
        path: '/review/:id',
        pageBuilder: (c, s) =>
            _fadePage(s, ReviewScreen(appointmentId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/confirmed/:id',
        pageBuilder: (c, s) => _fadePage(
          s,
          ConfirmationScreen(appointmentId: s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/pass/:id',
        pageBuilder: (c, s) =>
            _fadePage(s, PassScreen(appointmentId: s.pathParameters['id']!)),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (c, s) => _fadePage(s, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                pageBuilder: (c, s) => _fadePage(s, const ExploreScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.appointments,
                pageBuilder: (c, s) => _fadePage(s, const AppointmentsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rewards,
                pageBuilder: (c, s) => _fadePage(s, const RewardsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (c, s) => _fadePage(s, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
