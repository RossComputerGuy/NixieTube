import '../type.dart';

class NixAssertExpression extends NixType<NixAssertExpression> {
  const NixAssertExpression(this.value);

  final Object? value;

  @override
  int get hashCode => Object.hashAll([value]);

  @override
  bool get isConstant => isObjectConstantNix(value);

  @override
  NixAssertExpression constEval() {
    if (value is NixType) {
      if ((value as NixType).constEval() as bool) {
        return this;
      }

      throw Exception('Assertion \'$value\' failed');
    }

    if (isConstant) {
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
