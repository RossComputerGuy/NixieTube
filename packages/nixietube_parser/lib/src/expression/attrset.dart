import 'package:asn1lib/asn1lib.dart';

import 'inherit.dart';
import '../type.dart';

class NixAttributeSetExpression extends NixType<Map<Object, Object?>> {
  const NixAttributeSetExpression({
    this.isRec = false,
    this.inherits = const [],
    this.fields = const {},
  });

  final bool isRec;
  final List<NixInheritExpression> inherits;
  final Map<Object, Object?> fields;

  @override
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = super.serialize(scope);

    seq.add(ASN1Boolean(isRec));
    seq.add(serializeNix(inherits, scope));
    seq.add(serializeNix(fields, scope));

    return seq;
  }

  @override
  bool isConstant(Map<Object, Object?> scope) => isObjectConstantNix(
        fields,
        scope,
        fields: fields,
        inherits: inherits,
        isRec: isRec,
      );

  @override
  Map<Object, Object?> constEval(Map<Object, Object?> scope) => constEvalScope(
        scope: scope,
        fields: fields,
        inherits: inherits,
        isRec: isRec,
      );

  @override
  String toString() =>
      (isRec ? 'rec ' : '') +
      '{ ' +
      inherits.map((v) => '$v; ').join() +
      fields.entries.map((entry) => '${entry.key} = ${entry.value}; ').join() +
      '}';
}
