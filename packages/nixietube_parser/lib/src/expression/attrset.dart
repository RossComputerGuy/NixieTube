import 'inherit.dart';

class NixAttributeSetExpression {
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
  String toString() =>
      (isRec ? 'rec ' : '') +
      '{ ' +
      inherits.map((v) => '$v; ').join() +
      fields.entries.map((entry) => '${entry.key} = ${entry.value}; ').join() +
      '}';
}
