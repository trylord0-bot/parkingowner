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
        ..src = 'kakao_postcode.html'
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
