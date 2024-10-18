abstract class NixType<T> {
  const NixType();

  bool get isConstant;
  T constEval() => isConstant
      ? throw Exception('Not implemented')
      : throw Exception('Not constant');
}

bool isObjectConstantNix(Object? value) {
  if (value is NixType) {
    return value.isConstant;
  }

  if (value is List) {
    for (final item in value) {
      if (!isObjectConstantNix(item)) return false;
    }

    return true;
  }

  if (value is Map) {
    for (final key in value.keys) {
      if (!isObjectConstantNix(key)) return false;
    }

    for (final item in value.values) {
      if (!isObjectConstantNix(item)) return false;
    }

    return true;
  }

  return value is num || value is bool || value is String || value is Null;
}
