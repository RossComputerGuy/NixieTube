import '../identifier.dart';

class NixOrExpression {
  const NixOrExpression(this.identifiers, this.valueExpression);

  final NixIdentifierList identifiers;
  final Object? valueExpression;

  @override
  String toString() => '$identifiers or $valueExpression';
}
