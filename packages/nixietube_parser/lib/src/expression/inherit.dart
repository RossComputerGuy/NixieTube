import '../identifier.dart';

class NixInheritExpression {
  const NixInheritExpression(this.variables, [this.from = null]);

  final List<NixIdentifier> variables;
  final NixIdentifierList? from;

  @override
  String toString() =>
      'inherit${from != null ? ' ($from)' : ''} ${variables.join(' ')}';
}
