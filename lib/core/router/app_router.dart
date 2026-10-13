import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rewards/presentation/rewards_screen.dart';
import '../providers/app_providers.dart';
import 'app_shell.dart';

abstract class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const explore = '/explore';
  static const booking = '/booking';
  static const appointments = '/appointments';
  static const rewards = '/rewards';
  static const profile = '/profile';
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
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final seen = ref.read(onboardingProvider);
      final atOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!seen && !atOnboarding) return AppRoutes.onboarding;
      if (seen && atOnboarding) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (c, s) => _fadePage(s, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.booking,
        pageBuilder: (c, s) => _fadePage(s, const BookingScreen()),
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
