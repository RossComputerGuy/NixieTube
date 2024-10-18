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
  int get hashCode => Object.hashAll([
        isRec,
        inherits,
        fields,
      ]);

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(fields, scope, fields: fields, inherits: inherits);

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
