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
    seq.add(ASN1Sequence()
      ..elements =
          inherits.map((inherit) => inherit.serialize(scope)).toList());
    seq.add(ASN1Sequence()
      ..elements = fields.entries.map((entry) {
        final seqField = ASN1Sequence();

        if (entry.key is NixType) {
          seqField.add((entry.key as NixType).serialize(scope));
        } else {
          throw Exception('Cannot serialize ${entry.key.runtimeType}');
        }

        if (entry.value is NixType) {
          seqField.add((entry.value as NixType).serialize(scope));
        } else {
          throw Exception('Cannot serialize ${entry.key.runtimeType}');
        }

        return seqField;
      }).toList());

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
