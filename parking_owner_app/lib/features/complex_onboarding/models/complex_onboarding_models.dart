class AddressSearchResult {
  final String roadAddress;
  final String? jibunAddress;
  final String? zipCode;

  const AddressSearchResult({
    required this.roadAddress,
    this.jibunAddress,
    this.zipCode,
  });

  factory AddressSearchResult.fromJson(Map<String, dynamic> json) {
    return AddressSearchResult(
      roadAddress: (json['roadAddress'] as String? ?? '').trim(),
      jibunAddress: (json['jibunAddress'] as String?)?.trim(),
      zipCode: (json['zipCode'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'roadAddress': roadAddress,
    'jibunAddress': jibunAddress,
    'zipCode': zipCode,
  };
}

class ComplexSummary {
  final String id;
  final String roadAddress;
  final String? jibunAddress;
  final String? zipCode;
  final String alias;

  const ComplexSummary({
    required this.id,
    required this.roadAddress,
    this.jibunAddress,
    this.zipCode,
    required this.alias,
  });

  factory ComplexSummary.fromJson(Map<String, dynamic> json) {
    return ComplexSummary(
      id: json['id'] as String,
      roadAddress: json['roadAddress'] as String,
      jibunAddress: json['jibunAddress'] as String?,
      zipCode: json['zipCode'] as String?,
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
