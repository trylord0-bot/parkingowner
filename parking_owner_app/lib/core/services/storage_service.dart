import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, access);
    await prefs.setString(_kRefreshToken, refresh);
  }

  Future<({String? accessToken, String? refreshToken})> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      accessToken: prefs.getString(_kAccessToken),
      refreshToken: prefs.getString(_kRefreshToken),
    );
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
  }
}
