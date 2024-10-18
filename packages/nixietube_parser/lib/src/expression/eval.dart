import '../identifier.dart';
import '../type.dart';

class NixEvalExpression extends NixType<Object?> {
  const NixEvalExpression(this.identifiers, [this.inners = const []]);

  final NixIdentifierList identifiers;
  final List<Object?> inners;

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(identifiers, scope) &&
      isObjectConstantNix(inners, scope);

  @override
  Object? constEval(Map<Object, Object?> scope) {
    var value = identifiers.constEval(scope);
    if (inners.isNotEmpty) {
      var i = 0;
      for (final inner in inners) {
        // TODO: map i into the arguments
        value = (value as NixType).constEval(Map.fromEntries([
          ...scope.entries,
          MapEntry(i, inner),
        ]));
        i++;
      }
    }
    return value;
  }

  @override
  int get hashCode => Object.hashAll([identifiers, inners]);

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
