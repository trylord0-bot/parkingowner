import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../models/complex_onboarding_models.dart';
import 'kakao_postcode_embed_stub.dart'
    if (dart.library.js_interop) 'kakao_postcode_embed_web.dart';

class KakaoPostcodeSearchSheet extends StatefulWidget {
  const KakaoPostcodeSearchSheet({super.key});

  @override
  State<KakaoPostcodeSearchSheet> createState() =>
      _KakaoPostcodeSearchSheetState();
}

class _KakaoPostcodeSearchSheetState extends State<KakaoPostcodeSearchSheet> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'KakaoPostcode',
          onMessageReceived: (message) => _selectFromMessage(message.message),
        )
        ..loadHtmlString(_postcodeHtml);
    }
  }

  void _selectFromMessage(String message) {
    final json = jsonDecode(message) as Map<String, dynamic>;
    final result = AddressSearchResult.fromJson(json);
    if (result.roadAddress.isEmpty) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final text = isDark ? AppColors.textDark : AppColors.textLight;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '주소 검색',
                      style: TextStyle(
                        color: text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    icon: const Icon(Icons.close_rounded),
                    color: isDark
                        ? AppColors.subtextDark
                        : AppColors.subtextLight,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: kIsWeb ? bg : Colors.white,
                child: kIsWeb
                    ? KakaoPostcodeEmbed(
                        onSelected: (result) {
                          Navigator.of(context).pop(result);
                        },
                      )
                    : WebViewWidget(controller: _controller!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _postcodeHtml = '''
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<style>
html,body,#wrap{width:100%;height:100%;margin:0;padding:0;overflow:hidden;}
body{font-family:-apple-system,BlinkMacSystemFont,'Noto Sans KR',sans-serif;}
</style>
</head>
<body>
<div id="wrap"></div>
<script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
new daum.Postcode({
  oncomplete: function(data) {
    KakaoPostcode.postMessage(JSON.stringify({
      roadAddress: data.roadAddress || data.address,
      jibunAddress: data.jibunAddress || '',
      zipCode: data.zonecode || ''
    }));
  },
  width: '100%',
  height: '100%'
}).embed(document.getElementById('wrap'));
</script>
</body>
</html>
''';
