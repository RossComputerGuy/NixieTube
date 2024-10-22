import 'package:asn1lib/asn1lib.dart';

import '../identifier.dart';
import '../type.dart';

class NixInheritExpression extends NixType<Map<Object, Object?>> {
  const NixInheritExpression(this.variables, [this.from = null]);

  final List<NixIdentifier> variables;
  final NixIdentifierList? from;

  @override
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = super.serialize(scope);
    seq.add(serializeNix(variables, scope));
    seq.add(serializeNix(from, scope));
    return seq;
  }

  @override
  bool isConstant(Map<Object, Object?> scope) => false;

  @override
  Map<Object, Object?> constEval(Map<Object, Object?> scope) => {};

  @override
  String toString() =>
      'inherit${from != null ? ' ($from)' : ''} ${variables.join(' ')}';
}
