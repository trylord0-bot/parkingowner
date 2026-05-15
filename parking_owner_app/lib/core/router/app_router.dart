import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

// GoRouter는 한 번만 생성하고, auth 상태 변경은 refreshListenable로 전달한다.
// Provider가 rebuild될 때마다 GoRouter를 재생성하면 redirect 클로저가
// 이전 상태를 캡처해 버리기 때문에 이 패턴이 필요하다.
class _AuthListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable();
  ref.listen<AsyncValue<Object?>>(authNotifierProvider, (prev, next) {
    listenable.notify();
  });
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      if (authState.isLoading) return null;
      final loggedIn = authState.valueOrNull != null;
      final path = state.uri.path;
      final onAuthRoute = path == '/login' || path == '/signup';
      if (!loggedIn && !onAuthRoute) return '/login';
      if (loggedIn && onAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/home', builder: (context, state) => const MainScaffold()),
    ],
  );
});
