import 'package:asn1lib/asn1lib.dart';

import 'function.dart';
import '../identifier.dart';
import '../type.dart';

class NixEvalExpression extends NixType<Object?> {
  const NixEvalExpression(this.identifiers, [this.inners = const []]);

  final NixIdentifierList identifiers;
  final List<Object?> inners;

  @override
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = super.serialize(scope);
    seq.add(serializeNix(identifiers, scope));
    seq.add(serializeNix(inners, scope));
    return seq;
  }

  @override
  bool isConstant(Map<Object, Object?> scope) {
    if (inners.isNotEmpty && isObjectConstantNix(identifiers, scope)) {
      final value = identifiers.constEval(scope);
      if (value is NixFunctionExpression) {
        return value.isConstant(Map.fromEntries([
          ...scope.entries,
          ...inners.asMap().entries,
        ]));
      }
    }

    return isObjectConstantNix(identifiers, scope);
  }

  @override
  Object? constEval(Map<Object, Object?> scope) {
    final value = identifiers.constEval(scope);

    if (inners.isNotEmpty) {
      final func = value as NixFunctionExpression;

      return func.constEval(Map.fromEntries([
        ...scope.entries,
        ...inners.asMap().entries,
      ]));
    }
    return value;
  }

  @override
  bool operator ==(Object other) {
    if (other is NixEvalExpression) {
      if (other.inners.length == inners.length) {
        var i = 0;
        while (i < inners.length) {
          if (other.inners[i] != inners[i]) return false;
          i++;
        }

        return identifiers == other.identifiers;
      }
    }
    return false;
  }

  @override
  String toString() =>
      '$identifiers${inners.isNotEmpty ? ' ' + inners.join(' ') : ''}';
}
