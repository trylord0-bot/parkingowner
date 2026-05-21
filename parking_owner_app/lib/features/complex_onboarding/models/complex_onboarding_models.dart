class AddressSearchResult {
  final String roadAddress;
  final String? jibunAddress;
  final String? zipCode;
  final String? buildingName;

  const AddressSearchResult({
    required this.roadAddress,
    this.jibunAddress,
    this.zipCode,
    this.buildingName,
  });

  factory AddressSearchResult.fromJson(Map<String, dynamic> json) {
    final parsed = _parseRoadAddress(json['roadAddress'] as String? ?? '');
    final kakaoBuildingName = (json['buildingName'] as String?)?.trim();
    return AddressSearchResult(
      roadAddress: parsed.roadAddress,
      jibunAddress: (json['jibunAddress'] as String?)?.trim(),
      zipCode: (json['zipCode'] as String?)?.trim(),
      buildingName: kakaoBuildingName?.isNotEmpty == true
          ? kakaoBuildingName
          : parsed.buildingName,
    );
  }

  Map<String, dynamic> toJson() => {
    'roadAddress': roadAddress,
    'jibunAddress': jibunAddress,
    'zipCode': zipCode,
    'buildingName': buildingName,
  };
}

class ComplexSummary {
  final String id;
  final String roadAddress;
  final String? jibunAddress;
  final String? zipCode;
  final String? buildingName;
  final String alias;

  const ComplexSummary({
    required this.id,
    required this.roadAddress,
    this.jibunAddress,
    this.zipCode,
    this.buildingName,
    required this.alias,
  });

  factory ComplexSummary.fromJson(Map<String, dynamic> json) {
    return ComplexSummary(
      id: json['id'] as String,
      roadAddress: json['roadAddress'] as String,
      jibunAddress: json['jibunAddress'] as String?,
      zipCode: json['zipCode'] as String?,
      buildingName: json['buildingName'] as String?,
      alias: json['alias'] as String? ?? json['name'] as String? ?? '',
    );
  }
}

class ComplexCheckResult {
  final bool exists;
  final String roadAddress;
  final ComplexSummary? complex;

  const ComplexCheckResult({
    required this.exists,
    required this.roadAddress,
    this.complex,
  });

  factory ComplexCheckResult.fromJson(Map<String, dynamic> json) {
    final complexJson = json['complex'] as Map<String, dynamic>?;
    return ComplexCheckResult(
      exists: json['exists'] as bool? ?? false,
      roadAddress:
          json['roadAddress'] as String? ??
          complexJson?['roadAddress'] as String? ??
          '',
      complex: complexJson == null
          ? null
          : ComplexSummary.fromJson(complexJson),
    );
  }
}

class _ParsedRoadAddress {
  final String roadAddress;
  final String? buildingName;

  const _ParsedRoadAddress({required this.roadAddress, this.buildingName});
}

_ParsedRoadAddress _parseRoadAddress(String rawRoadAddress) {
  final trimmed = rawRoadAddress.trim();
  final match = RegExp(r'^(.*)\(([^()]*)\)\s*$').firstMatch(trimmed);
  if (match == null) {
    return _ParsedRoadAddress(roadAddress: trimmed);
  }

  final baseAddress = match.group(1)?.trim() ?? trimmed;
  final parenthetical = match.group(2)?.trim() ?? '';
  if (baseAddress.isEmpty || parenthetical.isEmpty) {
    return _ParsedRoadAddress(roadAddress: trimmed);
  }

  final buildingName = parenthetical
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .lastOrNull;

  return _ParsedRoadAddress(
    roadAddress: baseAddress,
    buildingName: buildingName,
  );
}
