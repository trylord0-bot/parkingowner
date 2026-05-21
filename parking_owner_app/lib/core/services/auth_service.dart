import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/models/app_state.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final UserInfo user;

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

class AuthService {
  // 웹: localhost, Android 에뮬레이터: 10.0.2.2, iOS 시뮬레이터: localhost
  static final String _base =
      '${kIsWeb ? 'http://localhost' : 'http://10.0.2.2'}:3000/api';
  static const _timeout = Duration(seconds: 10);

  // ── HTTP 헬퍼 ─────────────────────────────────────────────────────────────

  Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      return await http
          .post(
            Uri.parse('$_base$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(
            _timeout,
            onTimeout: () => throw const ApiException(
              408,
              '[408] 서버 응답 시간이 초과되었습니다. 네트워크를 확인해주세요.',
            ),
          );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, _networkMessage(e));
    }
  }

  Future<http.Response> _get(String path, {String? token}) async {
    try {
      return await http
          .get(
            Uri.parse('$_base$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            _timeout,
            onTimeout: () => throw const ApiException(
              408,
              '[408] 서버 응답 시간이 초과되었습니다. 네트워크를 확인해주세요.',
            ),
          );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, _networkMessage(e));
    }
  }

  // ── API 메서드 ────────────────────────────────────────────────────────────

  Future<LoginResult> login(String email, String password) async {
    final resp = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    final data = _decode(resp);
    final userData = data['user'] as Map<String, dynamic>;
    return LoginResult(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: UserInfo(
        id: userData['id'] as String,
        name: userData['name'] as String,
        email: userData['email'] as String,
        role: _parseRole(userData['role'] as String? ?? 'RESIDENT'),
        currentComplexId:
            userData['currentComplexId'] as String? ??
            userData['complexId'] as String?,
        complexName: userData['complexName'] as String? ?? '',
        complexBuildingName: userData['complexBuildingName'] as String?,
        complexRoadAddress: userData['complexRoadAddress'] as String?,
        profileImageUrl: _normalizeNullableAssetUrl(
          userData['profileImageUrl'] as String?,
        ),
      ),
    );
  }

  Future<void> register(String name, String email, String password) async {
    final resp = await _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    _decode(resp);
  }

  Future<void> verifyEmail(String email, String code) async {
    final resp = await _post('/auth/verify-email', {
      'email': email,
      'code': code,
    });
    _decode(resp);
  }

  Future<void> resendVerificationEmail(String email) async {
    final resp = await _post('/auth/resend-verification', {'email': email});
    _decode(resp);
  }

  Future<Map<String, dynamic>> devReset() async {
    final resp = await _post('/dev/reset', {});
    return _decode(resp);
  }

  Future<UserInfo> me(String accessToken) async {
    final resp = await _get('/auth/me', token: accessToken);
    return _parseUserInfo(_decode(resp));
  }

  Future<String> uploadProfileImage(String accessToken, XFile imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/users/me/profile-image'),
    );
    request.headers['Authorization'] = 'Bearer $accessToken';

    final bytes = await imageFile.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
        contentType: _contentTypeFor(imageFile.name),
      ),
    );

    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const ApiException(
          408,
          '[408] 이미지 업로드 시간이 초과되었습니다. 네트워크를 확인해주세요.',
        ),
      );
      final resp = await http.Response.fromStream(streamed);
      final data = _decode(resp);
      return _normalizeAssetUrl(data['profileImageUrl'] as String);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, _networkMessage(e));
    }
  }

  Future<void> logout(String accessToken, String refreshToken) async {
    try {
      await _post('/auth/logout', {
        'refreshToken': refreshToken,
      }, token: accessToken);
    } catch (_) {}
  }

  Future<void> forgotPassword(String email) async {
    final resp = await _post('/auth/forgot-password', {'email': email});
    _decode(resp);
  }

  Future<LoginResult> refresh(String refreshToken) async {
    final resp = await _post('/auth/refresh', {'refreshToken': refreshToken});
    final data = _decode(resp);
    return LoginResult(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: UserInfo(
        id: '',
        name: '',
        email: '',
        role: UserRole.resident,
        currentComplexId: null,
        complexName: '',
        complexBuildingName: null,
        complexRoadAddress: null,
      ),
    );
  }

  // ── 내부 유틸 ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _decode(http.Response resp) {
    // 성공 응답 파싱
    if (resp.statusCode < 400) {
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException(
          resp.statusCode,
          '[${resp.statusCode}] 응답 파싱 실패: ${_truncate(resp.body)}',
        );
      }
    }

    // 에러 응답: JSON에서 error/message 필드 추출
    String serverMsg = '알 수 없는 오류';
    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      serverMsg =
          json['error'] as String? ?? json['message'] as String? ?? serverMsg;
    } catch (_) {
      if (resp.body.isNotEmpty) serverMsg = _truncate(resp.body);
    }

    throw ApiException(resp.statusCode, '[${resp.statusCode}] $serverMsg');
  }

  String _networkMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('connection refused') ||
        s.contains('err_connection_refused')) {
      return '[연결 거부] 서버가 실행 중이지 않습니다. ($_base)';
    }
    if (s.contains('failed host lookup') ||
        s.contains('err_name_not_resolved')) {
      return '[DNS 오류] 호스트를 찾을 수 없습니다.';
    }
    if (s.contains('network') ||
        s.contains('socket') ||
        s.contains('err_') ||
        s.contains('xmlhttprequest')) {
      return '[네트워크 오류] 인터넷 연결을 확인해주세요.';
    }
    return '[오류] $e';
  }

  String _truncate(String s) => s.length > 120 ? '${s.substring(0, 120)}…' : s;

  UserInfo _parseUserInfo(Map<String, dynamic> data) {
    final members =
        (data['complexMembers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final currentComplexId = data['currentComplexId'] as String?;
    final primary =
        members.where((m) => m['complexId'] == currentComplexId).firstOrNull ??
        (members.isNotEmpty ? members.first : null);
    return UserInfo(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      role: _parseRole(primary?['role'] as String? ?? 'RESIDENT'),
      currentComplexId: currentComplexId ?? (primary?['complexId'] as String?),
      complexName:
          data['currentComplexName'] as String? ??
          primary?['complexName'] as String? ??
          '',
      complexBuildingName:
          data['currentComplexBuildingName'] as String? ??
          primary?['complexBuildingName'] as String?,
      complexRoadAddress:
          data['currentComplexRoadAddress'] as String? ??
          primary?['complexRoadAddress'] as String?,
      profileImageUrl: _normalizeNullableAssetUrl(
        data['profileImageUrl'] as String?,
      ),
    );
  }

  UserRole _parseRole(String role) => switch (role) {
    'APP_ADMIN' => UserRole.appAdmin,
    'COMPLEX_MANAGER' => UserRole.complexManager,
    'ATTENDANT' => UserRole.attendant,
    _ => UserRole.resident,
  };

  MediaType _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  String? _normalizeNullableAssetUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    return _normalizeAssetUrl(url);
  }

  String _normalizeAssetUrl(String url) {
    if (kIsWeb) return url;
    return url
        .replaceFirst('http://localhost:3000', 'http://10.0.2.2:3000')
        .replaceFirst('http://127.0.0.1:3000', 'http://10.0.2.2:3000');
  }
}
