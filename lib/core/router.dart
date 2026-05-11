import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/detail/detail_screen.dart';
import '../presentation/screens/watchlist/watchlist_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isAuth = user != null && user.emailConfirmedAt != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) =>
                DetailScreen(movieId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'watchlist',
            builder: (context, state) => const WatchlistScreen(),
          ),
        ],
      ),
    ],
  );
});
