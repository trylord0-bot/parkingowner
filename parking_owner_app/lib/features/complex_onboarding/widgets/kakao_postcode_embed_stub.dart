import 'package:flutter/material.dart';

import '../models/complex_onboarding_models.dart';

class KakaoPostcodeEmbed extends StatelessWidget {
  final ValueChanged<AddressSearchResult> onSelected;

  const KakaoPostcodeEmbed({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('카카오 주소검색은 웹 또는 WebView 환경에서 사용할 수 있습니다.'));
  }
}
