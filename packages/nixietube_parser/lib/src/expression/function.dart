import '../identifier.dart';
import '../type.dart';

class NixFunctionArgumentExpression extends NixType<Map<Object, Object?>> {
  const NixFunctionArgumentExpression(this.fields, this.tag);

  final Map<Object, Object?> fields;
  final NixIdentifier? tag;

  @override
  bool isConstant(Map<Object, Object?> scope) => isObjectConstantNix(
        fields,
        scope,
        isRec: true,
      );

  @override
  Map<Object, Object?> constEval(Map<Object, Object?> scope) => constEvalScope(
        scope: scope,
        isRec: true,
      );

  @override
  String toString() =>
      '{ ' +
      fields.entries
          .map((entry) =>
              '${entry.key}' + (entry.value != null ? ' ? ${entry.value}' : ''))
          .join(', ') +
      ' }' +
      (tag != null ? '@$tag' : '');
}

class NixFunctionExpression extends NixType<dynamic> {
  const NixFunctionExpression(this.arguments, this.body);

  final List<Object> arguments;
  final Object? body;

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(body, scope);

  @override
  dynamic constEval(Map<Object, Object?> scope) => null;

  @override
  String toString() => '${arguments.map((a) => '$a: ').join()}$body';
}
