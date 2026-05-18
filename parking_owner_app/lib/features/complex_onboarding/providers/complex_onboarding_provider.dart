import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/complex_service.dart';

final complexServiceProvider = Provider<ComplexService>((ref) {
  return ComplexService();
});
