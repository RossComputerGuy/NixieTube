import 'package:asn1lib/asn1lib.dart';
import 'inherit.dart';
import '../expression.dart';
import '../type.dart';

class NixLetInExpression extends NixType<dynamic> {
  const NixLetInExpression(
    this.inner, {
    this.inherits = const [],
    this.fields = const {},
  });

  final List<NixInheritExpression> inherits;
  final Map<Object, Object?> fields;
  final Object? inner;

  @override
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = super.serialize(scope);
    seq.add(serializeNix(inherits, scope));
    seq.add(serializeNix(fields, scope));
    seq.add(serializeNix(inner, scope));
    return seq;
  }

  @override
  bool isConstant(Map<Object, Object?> scope) => isObjectConstantNix(
        inner,
        scope,
        fields: fields,
        inherits: inherits,
        isRec: true,
      );

  @override
  dynamic constEval(Map<Object, Object?> scope) {
    if (inner is NixType) {
      final newScope = constEvalScope(
        scope: scope,
        fields: fields,
        inherits: inherits,
        isRec: true,
      );

      return (inner as NixType).constEval(newScope);
    }
    return inner;
  }

  @override
  String toString() =>
      'let ' +
      inherits.map((v) => '$v; ').join() +
      fields.entries.map((entry) => '${entry.key} = ${entry.value}; ').join() +
      'in $inner';
}
