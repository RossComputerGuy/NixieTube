import '../type.dart';

class NixLogicalExpression extends NixType<Object?> {
  const NixLogicalExpression(
    this.value, {
    this.isNegative = false,
  });

  final bool isNegative;
  final Object? value;

  @override
  bool get isConstant => isObjectConstantNix(value);

  @override
  Object? constEval() {
    if (!isConstant) {
      throw Exception('Not constant');
    }

    final ceval = value is NixType ? (value as NixType).constEval() : value;

    if (isNegative) {
      return !(ceval as bool);
    }

    return ceval;
  }

  @override
  String toString() => (isNegative ? '! ' : '') + '$value';
}
