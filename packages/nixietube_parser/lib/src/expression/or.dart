import 'package:asn1lib/asn1lib.dart';
import '../identifier.dart';
import '../type.dart';

class NixOrExpression extends NixType<Object?> {
  const NixOrExpression(this.identifiers, this.valueExpression);

  final NixIdentifierList identifiers;
  final Object? valueExpression;

  @override
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = super.serialize(scope);

    seq.add(serializeNix(identifiers, scope));
    seq.add(serializeNix(valueExpression, scope));

    return seq;
  }

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(identifiers, scope) &&
      isObjectConstantNix(valueExpression, scope);

  @override
  Object? constEval(Map<Object, Object?> scope) {
    final a = identifiers.constEval(scope);

    if (a == null) {
      if (valueExpression is NixType) {
        return (valueExpression as NixType).constEval(scope);
      }
      return valueExpression;
    }

    return a;
  }

  @override
  String toString() => '$identifiers or $valueExpression';
}
