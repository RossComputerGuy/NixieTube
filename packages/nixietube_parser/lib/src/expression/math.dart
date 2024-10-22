import 'package:asn1lib/asn1lib.dart';
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
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = super.serialize(scope);
    seq.add(ASN1UTF8String(operation.token));
    seq.add(serializeNix(value, scope));
    return seq;
  }

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
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = super.serialize(scope);
    seq.add(serializeNix(left, scope));
    seq.add(serializeNix(right, scope));
    return seq;
  }

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(left, scope) && isObjectConstantNix(right, scope);

  @override
  Object? constEval(Map<Object, Object?> scope) {
    if (!isConstant(scope)) {
      throw Exception('Not constant');
    }

    var i = left is NixType ? (left as NixType).constEval(scope) : left;

    final keepInt = i is int;

    for (final item in right) {
      i = switch (item.operation) {
        NixMathOperator.add => i + item.constEval(scope),
        NixMathOperator.sub => i - item.constEval(scope),
        NixMathOperator.mul => i * item.constEval(scope),
        NixMathOperator.div => i / item.constEval(scope),
        NixMathOperator.equal => i == item.constEval(scope),
        NixMathOperator.notEqual => i != item.constEval(scope),
        NixMathOperator.gt => i > item.constEval(scope),
        NixMathOperator.lt => i < item.constEval(scope),
        NixMathOperator.gtEqual => i >= item.constEval(scope),
        NixMathOperator.ltEqual => i <= item.constEval(scope),
        NixMathOperator.impl =>
          (i as bool) ? item.constEval(scope) as bool : false,
      };
    }

    if (keepInt && i is num) return i.toInt();
    return i;
  }

  @override
  String toString() => '$left ${right.join(' ')}';
}
