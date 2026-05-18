import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../features/complex_onboarding/models/complex_onboarding_models.dart';
import 'auth_service.dart';

class ComplexService {
  static final String _base =
      '${kIsWeb ? 'http://localhost' : 'http://10.0.2.2'}:3000/api';
  static const _timeout = Duration(seconds: 10);

  Future<ComplexCheckResult> checkAddress({
    required String accessToken,
    required String roadAddress,
  }) async {
    final uri = Uri.parse(
      '$_base/complexes/check',
    ).replace(queryParameters: {'roadAddress': roadAddress});
    final resp = await _get(uri, accessToken);
    return ComplexCheckResult.fromJson(_decode(resp));
  }

  Future<ComplexSummary> createComplex({
    required String accessToken,
    required AddressSearchResult address,
    required String alias,
  }) async {
    final resp = await _post(Uri.parse('$_base/complexes'), accessToken, {
      ...address.toJson(),
      'alias': alias,
    });
    final data = _decode(resp);
    return ComplexSummary.fromJson(data['complex'] as Map<String, dynamic>);
  }

  Future<void> requestJoin({
    required String accessToken,
    required String complexId,
  }) async {
    final resp = await _post(
      Uri.parse('$_base/complexes/$complexId/join-request'),
      accessToken,
      {},
    );
    _decode(resp);
  }

  Future<void> useInviteCode({
    required String accessToken,
    required String code,
  }) async {
    final resp = await _post(
      Uri.parse('$_base/complexes/use-invite'),
      accessToken,
      {'code': code},
    );
    _decode(resp);
  }

  Future<http.Response> _get(Uri uri, String token) async {
    try {
      return await http.get(uri, headers: _headers(token)).timeout(_timeout);
    } catch (e) {
      throw ApiException(0, _networkMessage(e));
    }
  }

  Future<http.Response> _post(
    Uri uri,
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      return await http
          .post(uri, headers: _headers(token), body: jsonEncode(body))
          .timeout(_timeout);
    } catch (e) {
      throw ApiException(0, _networkMessage(e));
    }
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(http.Response resp) {
    if (resp.statusCode < 400) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    String serverMsg = '알 수 없는 오류';
    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      serverMsg =
          json['error'] as String? ?? json['message'] as String? ?? serverMsg;
    } catch (_) {
      if (resp.body.isNotEmpty) serverMsg = resp.body;
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
    return '[네트워크 오류] $e';
  }
}
