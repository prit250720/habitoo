import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/alarm/screens/alarm_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/habits/add_habit/screens/add_habit_screen.dart';
import '../features/habits/edit_habit/screens/edit_habit_screen.dart';
import '../features/habits/screens/my_habits_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../models/habit_model.dart';
import '../providers/auth_provider.dart' show authStateChangesProvider;
import '../screens/auth/login_screen.dart';
import '../screens/auth/phone_login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../shared/widgets/app_bottom_nav.dart';

/// Route paths used throughout the app.
abstract class AppRoutes {
  static const String splash = '/';
  static const String phoneLogin = '/phone-login';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String habits = '/habits';
  static const String addHabit = '/habits/add';
  static const String editHabit = '/habits/edit';
  static const String progress = '/progress';
  static const String profile = '/profile';
  static const String alarm = '/alarm';
}

/// Set of paths that do not require authentication.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.phoneLogin,
  AppRoutes.login,
  AppRoutes.signup,
  // Alarm screen must be reachable even before the shell loads.
  AppRoutes.alarm,
};

/// A root-level [NavigatorKey] shared with [GoRouter] so external code
/// (e.g. notification callbacks in main.dart) can push routes without a
/// BuildContext.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,

    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      if (location == AppRoutes.splash) return null;

      final authValue = authNotifier.currentAuthUser;
      final isLoggedIn = authValue != null;

      if (isLoggedIn && isPublic && location != AppRoutes.alarm) {
        return AppRoutes.dashboard;
      }
      if (!isLoggedIn && !isPublic) return AppRoutes.phoneLogin;

      return null;
    },

    routes: <RouteBase>[
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Phone OTP login (primary auth entry point) ─────────────────────
      GoRoute(
        path: AppRoutes.phoneLogin,
        name: 'phoneLogin',
        builder: (context, state) => const PhoneLoginScreen(),
      ),

      // ── Email / password login (secondary, existing flow) ──────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Sign up ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // ── Alarm (outside shell, accessible over lock screen) ─────────────
      //
      // Navigation is always done imperatively:
      //   context.pushNamed('alarm', extra: _AlarmArgs(alarmId, habit))
      //
      // This keeps the alarm screen on top of whatever was showing and lets
      // context.pop() return to it cleanly.
      GoRoute(
        path: AppRoutes.alarm,
        name: 'alarm',
        builder: (context, state) {
          final args = state.extra as _AlarmArgs;
          return AlarmScreen(alarmId: args.alarmId, habit: args.habit);
        },
      ),

      // ── Main shell with bottom nav ─────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final index = navigationShell.currentIndex;
          final brightness = Theme.of(context).brightness;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
              systemNavigationBarIconBrightness: brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
            ),
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              extendBody: true,
              body: Stack(
                children: [
                  navigationShell,
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AppBottomNav(
                      currentIndex: index,
                      onDestinationSelected: (value) {
                        navigationShell.goBranch(
                          value,
                          initialLocation: value == index,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.dashboard,
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.habits,
                name: 'habits',
                builder: (context, state) => const MyHabitsScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'add',
                    name: 'addHabit',
                    builder: (context, state) => const AddHabitScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    name: 'editHabit',
                    builder: (context, state) {
                      final habit = state.extra as HabitModel;
                      return EditHabitScreen(habit: habit);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.progress,
                name: 'progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Alarm navigation helper
// ---------------------------------------------------------------------------

/// Payload passed as GoRouter `extra` when navigating to the alarm route.
class _AlarmArgs {
  const _AlarmArgs({required this.alarmId, required this.habit});
  final int alarmId;
  final HabitModel habit;
}

/// Push the [AlarmScreen] from anywhere — works both inside and outside the
/// widget tree via [rootNavigatorKey].
///
/// Called from:
///   • [AlarmWatcher] in main.dart (foreground alarm fires)
///   • notification tap handler in main.dart (app was background/killed)
void navigateToAlarm({required int alarmId, required HabitModel habit}) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;
  ctx.pushNamed(
    'alarm',
    extra: _AlarmArgs(alarmId: alarmId, habit: habit),
  );
}

// ---------------------------------------------------------------------------
// Auth notifier — drives GoRouter.refreshListenable
// ---------------------------------------------------------------------------

/// A [ChangeNotifier] that listens to [authStateChangesProvider] and notifies
/// GoRouter whenever the Firebase sign-in state changes.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, next) {
      _currentUser = next.when(
        data: (user) => user,
        loading: () => _currentUser,
        error: (e, st) => null,
      );
      notifyListeners();
    });
    // Capture the initial value synchronously if already resolved.
    _currentUser = ref
        .read(authStateChangesProvider)
        .when(
          data: (user) => user,
          loading: () => null,
          error: (e, st) => null,
        );
  }

  dynamic _currentUser;

  /// Returns the current Firebase [User] or null (typed as dynamic to avoid
  /// importing firebase_auth here; callers only need null-check).
  dynamic get currentAuthUser => _currentUser;
}

// ---------------------------------------------------------------------------
// Placeholder (kept for backward compat with any references)
// ---------------------------------------------------------------------------

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Coming soon: $title')),
    );
  }
}
