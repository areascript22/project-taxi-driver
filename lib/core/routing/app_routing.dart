import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:driver_app/feature/incoming_request/presentation/screen/incoming_request_screen.dart';
import 'package:driver_app/feature/incoming_request/presentation/screen/incoming_request_screen2.dart';
import 'package:driver_app/feature/trip/presentation/screen/trip_screen.dart';
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
                path: bookingRoute.route,
                name: bookingRoute.name,
                builder: (context, state) => const IncomingRequestScreen(),
              ),
              GoRoute(
                path: booking2Route.route,
                name: booking2Route.name,
                builder: (context, state) => const IncomingRequestScreen2(),
              ),
              GoRoute(
                path: tripRoute.route,
                name: tripRoute.name,
                builder:
                    (context, state) =>
                        TripScreen(request: state.extra as IncomingRequestEntity),
              ),
            ],
          ),

          // ---------------------------
          // BRANCH 2: Profile Flow
          // ---------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: profileRoute.route,
                name: profileRoute.name,
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: profile2Route.route,
                name: profile2Route.name,
                builder: (context, state) => const ProfileScreen2(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
