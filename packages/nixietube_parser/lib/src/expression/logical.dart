import '../type.dart';

class NixLogicalExpression extends NixType<Object?> {
  const NixLogicalExpression(
    this.value, {
    this.isNegative = false,
  });

  final bool isNegative;
  final Object? value;

  @override
  int get hashCode =>
      Object.hashAll([runtimeType.toString(), isNegative, value]);

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(value, scope);

  @override
  Object? constEval(Map<Object, Object?> scope) {
    if (!isConstant(scope)) {
      throw Exception('Not constant');
    }

    final ceval =
        value is NixType ? (value as NixType).constEval(scope) : value;

    if (isNegative) {
      return !(ceval as bool);
    }

    return ceval;
  }

  @override
  bool operator ==(Object other) {
    if (other is NixLogicalExpression) {
      return other.value == value && other.isNegative == isNegative;
    }
    return false;
  }

  @override
  String toString() => (isNegative ? '! ' : '') + '$value';
}
