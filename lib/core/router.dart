import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/reset_password_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/detail/detail_screen.dart';
import '../presentation/screens/watchlist/watchlist_screen.dart';

final authChangeProvider = Provider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier();
});

class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeEvent? _lastEvent;
  bool _isRecovery = false; // flag dari deep link recovery
  StreamSubscription? _authSub;
  StreamSubscription? _linkSub;
  final AppLinks _appLinks = AppLinks();

  bool _handlingLink = false; // cegah double processing warm+cold start

  AuthChangeNotifier() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      print('🔐 AUTH EVENT: ${data.event} | session: ${data.session?.user.email}');
      _lastEvent = data.event;
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _isRecovery = true;
      }
      notifyListeners();
    });

    // Handle deep link saat app sudah berjalan (warm start)
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      print('🔗 DEEP LINK (warm): $uri');
      _handlingLink = true;
      _handleDeepLink(uri);
    });

    // Handle deep link saat cold start
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        print('🔗 DEEP LINK (cold): $uri');
        if (!_handlingLink) _handleDeepLink(uri);
      }
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final type = uri.queryParameters['type'];
    final tokenHash = uri.queryParameters['token_hash'];

    if (type != 'recovery' || tokenHash == null) return;

    // Set flag dulu agar router redirect ke /reset-password sebelum async selesai
    _isRecovery = true;
    notifyListeners();

    try {
      // Di gotrue 2.x, verifyOTP untuk token_hash harus menggunakan
      // parameter bernama `tokenHash`, bukan `token`
      await Supabase.instance.client.auth.verifyOTP(
        tokenHash: tokenHash,
        type: OtpType.recovery,
      );
      print('✅ verifyOTP recovery berhasil');
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      _isRecovery = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error: $e');
      _isRecovery = false;
      notifyListeners();
    }
  }

  AuthChangeEvent? get lastEvent => _lastEvent;
  bool get isRecovery => _isRecovery;

  void clearRecovery() {
    _isRecovery = false;
    _lastEvent = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authChangeProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;
      final lastEvent = authNotifier.lastEvent;
      final isRecovery = authNotifier.isRecovery;
      final currentPath = state.matchedLocation;

      // 1. Recovery flag aktif → paksa ke /reset-password
      if (isRecovery || lastEvent == AuthChangeEvent.passwordRecovery) {
        return '/reset-password';
      }

      // 2. Sudah di /reset-password → jaga agar tidak keluar
      if (currentPath == '/reset-password') {
        return session != null ? null : '/login';
      }

      final isAuth = user != null && user.emailConfirmedAt != null;
      final isAuthRoute = currentPath == '/login' ||
          currentPath == '/register' ||
          currentPath == '/forgot-password';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/reset-password',
          builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) =>
                DetailScreen(movieId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
              path: 'watchlist', builder: (_, __) => const WatchlistScreen()),
        ],
      ),
    ],
  );
});