import '../identifier.dart';

class NixEvalExpression {
  const NixEvalExpression(this.identifiers, [this.inners = const []]);

  final NixIdentifierList identifiers;
  final List<Object?> inners;

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
