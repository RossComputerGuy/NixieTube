import '../type.dart';

enum NixMathOperator {
  add('+'),
  sub('-'),
  mul('*'),
  div('/'),
  equal('=='),
  notEqual('!='),
  gt('>'),
  lt('<'),
  gtEqual('>='),
  ltEqual('<='),
  impl('->');

  const NixMathOperator(this.token);

  final String token;
}

class NixMathExpressionSide extends NixType<num> {
  const NixMathExpressionSide(this.operation, this.value);

  final NixMathOperator operation;
  final Object? value;

  @override
  bool get isConstant => isObjectConstantNix(value);

  @override
  num constEval() {
    if (value is NixType) {
      return (value as NixType).constEval as num;
    }

    if (isConstant) {
      return value as num;
    }

    throw Exception('Not constant');
  }

  @override
  String toString() => '${operation.token} $value';
}

class NixMathExpression extends NixType<num> {
  const NixMathExpression(this.left, [this.right = const []]);

  final Object? left;
  final List<NixMathExpressionSide> right;

  @override
  bool get isConstant =>
      isObjectConstantNix(left) && isObjectConstantNix(right);

  @override
  num constEval() {
    if (!isConstant) {
      throw Exception('Not constant');
    }

    var i = (left is NixType ? (left as NixType).constEval : left) as num;

    for (final item in right) {
      i = switch (item.operation) {
        NixMathOperator.add => i + item.constEval(),
        NixMathOperator.sub => i - item.constEval(),
        NixMathOperator.mul => i * item.constEval(),
        NixMathOperator.div => i / item.constEval(),
        (_) =>
          throw Exception('Cannot handle operation: ${item.operation.name}'),
      };
    }

    return i;
  }

  @override
  String toString() => '$left ${right.join(' ')}';
}
