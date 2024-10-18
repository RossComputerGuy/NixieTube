import '../type.dart';

class NixAssertExpression extends NixType<NixAssertExpression> {
  const NixAssertExpression(this.value);

  final Object? value;

  @override
  int get hashCode => Object.hashAll([value]);

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(value, scope);

  @override
  NixAssertExpression constEval(Map<Object, Object?> scope) {
    if (value is NixType) {
      if ((value as NixType).constEval(scope) as bool) {
        return this;
      }

      throw Exception('Assertion \'$value\' failed');
    }

    if (isConstant(scope)) {
      if (value as bool) {
        return this;
      }

      throw Exception('Assertion \'$value\' failed');
    }

    throw Exception('Not constant');
  }

  @override
  bool operator ==(Object other) {
    if (other is NixAssertExpression) {
      return other.value == other.value;
    }
    return false;
  }

  @override
  String toString() => 'assert $value';
}
