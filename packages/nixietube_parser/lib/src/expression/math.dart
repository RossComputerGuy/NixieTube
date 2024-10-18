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

class NixMathExpressionSide extends NixType<Object?> {
  const NixMathExpressionSide(this.operation, this.value);

  final NixMathOperator operation;
  final Object? value;

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(value, scope);

  @override
  Object? constEval(Map<Object, Object?> scope) {
    if (value is NixType) {
      return (value as NixType).constEval(scope);
    }

    if (isConstant(scope)) {
      return value;
    }

    throw Exception('Not constant');
  }

  @override
  String toString() => '${operation.token} $value';
}

class NixMathExpression extends NixType<Object?> {
  const NixMathExpression(this.left, [this.right = const []]);

  final Object? left;
  final List<NixMathExpressionSide> right;

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(left, scope) && isObjectConstantNix(right, scope);

  @override
  Object? constEval(Map<Object, Object?> scope) {
    if (!isConstant(scope)) {
      throw Exception('Not constant');
    }

    var i = left is NixType ? (left as NixType).constEval(scope) : left;

    final shouldPromote = left is int;

    for (final item in right) {
      i = switch (item.operation) {
        NixMathOperator.add => i + item.constEval(scope),
        NixMathOperator.sub => i - item.constEval(scope),
        NixMathOperator.mul => i * item.constEval(scope),
        NixMathOperator.div => i / item.constEval(scope),
        NixMathOperator.equal => (i as bool) == (item.constEval(scope) as bool),
        (_) =>
          throw Exception('Cannot handle operation: ${item.operation.name}'),
      };
    }

    if (shouldPromote) return i.toInt();
    return i;
  }

  @override
  String toString() => '$left ${right.join(' ')}';
}
