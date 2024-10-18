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

class NixMathExpressionSide {
  const NixMathExpressionSide(this.operation, this.value);

  final NixMathOperator operation;
  final Object? value;

  @override
  String toString() => '${operation.token} $value';
}

class NixMathExpression {
  const NixMathExpression(this.left, [this.right = const []]);

  final Object? left;
  final List<NixMathExpressionSide> right;

  @override
  String toString() => '$left ${right.join(' ')}';
}
