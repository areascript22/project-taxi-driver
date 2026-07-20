import 'package:driver_app/feature/incoming_request/presentation/screen/incoming_request_screen.dart';
import 'package:driver_app/feature/incoming_request/presentation/screen/incoming_request_screen2.dart';
import 'package:go_router/go_router.dart';
import '../../feature/auth/presentation/screen/session_screen.dart';
import '../../feature/auth/presentation/screen/sign_in_screen.dart';
import '../../feature/auth/presentation/screen/splash_screen.dart';
import '../../feature/profile/presentation/screen/profile_screen.dart';
import '../../feature/profile/presentation/screen/profile_screen_2.dart';
import '../../shared/presentation/component/scaffold_nav_bar.dart';
import 'app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: splashRoute.route,
    routes: [
      GoRoute(
        path: splashRoute.route,
        name: splashRoute.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: signInRoute.route,
        name: signInRoute.name,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: sessionRoute.route,
        name: sessionRoute.name,
        builder: (context, state) => const SessionScreen(),
      ),

      // The StatefulShellRoute acts as your authenticated "Home"
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // ---------------------------
          // BRANCH 1: Booking Flow
          // ---------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/booking',
                name: 'booking',
                builder: (context, state) => const IncomingRequestScreen(),
                routes: [
                  // CHILD ROUTE: Notice there is no leading '/' in the path
                  // Navigate here using: context.pushNamed('booking2')
                  GoRoute(
                    path: 'booking2',
                    name: 'booking2',
                    builder: (context, state) => const IncomingRequestScreen2(),
                  ),
                ],
              ),
            ],
          ),

          // ---------------------------
          // BRANCH 2: Profile Flow
          // ---------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  // CHILD ROUTE: Notice there is no leading '/'
                  // Navigate here using: context.pushNamed('profile2')
                  GoRoute(
                    path: '2',
                    name: 'profile2',
                    builder: (context, state) => const ProfileScreen2(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}