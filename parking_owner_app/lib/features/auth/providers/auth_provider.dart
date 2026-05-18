import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> updateProfileImage(XFile imageFile) async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) {
      throw const ApiException(401, '로그인이 필요합니다.');
    }

    final storage = ref.read(storageServiceProvider);
    final tokens = await storage.loadTokens();
    final accessToken = tokens.accessToken;
    if (accessToken == null) {
      throw const ApiException(401, '로그인이 필요합니다.');
    }

    final service = ref.read(authServiceProvider);
    final profileImageUrl = await service.uploadProfileImage(
      accessToken,
      imageFile,
    );
    state = AsyncData(currentUser.copyWith(profileImageUrl: profileImageUrl));
  }

  Future<void> reloadCurrentUser() async {
    final storage = ref.read(storageServiceProvider);
    final tokens = await storage.loadTokens();
    var accessToken = tokens.accessToken;
    if (accessToken == null) {
      state = const AsyncData(null);
      return;
    }

    final service = ref.read(authServiceProvider);
    if (tokens.refreshToken != null) {
      try {
        final refreshed = await service.refresh(tokens.refreshToken!);
        await storage.saveTokens(
          access: refreshed.accessToken,
          refresh: refreshed.refreshToken,
        );
        accessToken = refreshed.accessToken;
      } catch (_) {}
    }

    state = AsyncData(await service.me(accessToken!));
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserInfo?>(
  () => AuthNotifier(),
);
