import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:web/web.dart' as web;

import '../models/complex_onboarding_models.dart';

class KakaoPostcodeEmbed extends StatefulWidget {
  final ValueChanged<AddressSearchResult> onSelected;

  const KakaoPostcodeEmbed({super.key, required this.onSelected});

  @override
  State<KakaoPostcodeEmbed> createState() => _KakaoPostcodeEmbedState();
}

class _KakaoPostcodeEmbedState extends State<KakaoPostcodeEmbed> {
  static const _viewType = 'parking-owner-kakao-postcode';
  static var _registered = false;

  late final web.EventListener _messageListener;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    _messageListener = ((web.Event event) {
      final raw = (event as web.MessageEvent).data;
      if (raw == null || !raw.isA<JSString>()) return;

      final Object? decoded;
      try {
        decoded = jsonDecode((raw as JSString).toDart);
      } catch (_) {
        return;
      }
      if (decoded is! Map<String, dynamic>) return;
      if (decoded['source'] != 'parking-owner-kakao-postcode') return;

      final payload = decoded['payload'];
      if (payload is! Map<String, dynamic>) return;

      final result = AddressSearchResult.fromJson(payload);
      if (result.roadAddress.isEmpty) return;
      widget.onSelected(result);
    }).toJS;
    web.window.addEventListener('message', _messageListener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _messageListener);
    super.dispose();
  }

  static void _registerViewFactory() {
    if (_registered) return;
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (
      int viewId, {
      Object? params,
    }) {
      final iframe = web.HTMLIFrameElement()
        ..srcdoc = _webPostcodeHtml.toJS
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0'
        ..style.display = 'block';
      iframe.setAttribute('title', '카카오 주소검색');
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(
      viewType: _viewType,
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    );
  }
}

const _webPostcodeHtml = '''
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<style>
html,body,#wrap{width:100%;height:100%;margin:0;padding:0;overflow:hidden;background:#fff;}
body{font-family:-apple-system,BlinkMacSystemFont,'Noto Sans KR',sans-serif;}
#loading{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;color:#666;font-size:14px;}
</style>
</head>
<body>
<div id="loading">카카오 주소검색을 불러오는 중입니다.</div>
<div id="wrap"></div>
<script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
function sendAddress(data) {
  parent.postMessage(JSON.stringify({
    source: 'parking-owner-kakao-postcode',
    payload: {
      roadAddress: data.roadAddress || data.address || '',
      jibunAddress: data.jibunAddress || '',
      zipCode: data.zonecode || ''
    }
  }), '*');
}

function boot() {
  if (!window.daum || !window.daum.Postcode) {
    document.getElementById('loading').textContent = '카카오 주소검색을 불러오지 못했습니다. 네트워크를 확인해주세요.';
    return;
  }
  document.getElementById('loading').style.display = 'none';
  new daum.Postcode({
    oncomplete: sendAddress,
    width: '100%',
    height: '100%'
  }).embed(document.getElementById('wrap'));
}

if (document.readyState === 'complete') {
  boot();
} else {
  window.addEventListener('load', boot);
}
</script>
</body>
</html>
''';
