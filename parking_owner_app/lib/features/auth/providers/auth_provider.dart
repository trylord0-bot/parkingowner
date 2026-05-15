import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/app_state.dart';

final authServiceProvider = Provider((ref) => AuthService());
final storageServiceProvider = Provider((ref) => StorageService());

class AuthNotifier extends AsyncNotifier<UserInfo?> {
  @override
  Future<UserInfo?> build() async {
    final storage = ref.read(storageServiceProvider);
    final tokens = await storage.loadTokens();
    if (tokens.accessToken == null) return null;
    try {
      final service = ref.read(authServiceProvider);
      return await service.me(tokens.accessToken!);
    } catch (_) {
      await storage.clearTokens();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final service = ref.read(authServiceProvider);
    final storage = ref.read(storageServiceProvider);
    try {
      final result = await service.login(email, password);
      await storage.saveTokens(
        access: result.accessToken,
        refresh: result.refreshToken,
      );
      state = AsyncData(result.user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    final service = ref.read(authServiceProvider);
    await service.register(name, email, password);
  }

  Future<void> logout() async {
    final storage = ref.read(storageServiceProvider);
    try {
      final tokens = await storage.loadTokens();
      if (tokens.accessToken != null && tokens.refreshToken != null) {
        final service = ref.read(authServiceProvider);
        await service.logout(tokens.accessToken!, tokens.refreshToken!);
      }
    } catch (_) {}
    await storage.clearTokens();
    state = const AsyncData(null);
  }

  Future<void> forgotPassword(String email) async {
    final service = ref.read(authServiceProvider);
    await service.forgotPassword(email);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserInfo?>(() => AuthNotifier());
