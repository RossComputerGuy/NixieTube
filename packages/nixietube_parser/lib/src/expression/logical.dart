class NixLogicalExpression {
  const NixLogicalExpression(
    this.value, {
    this.isNegative = false,
  });

  final bool isNegative;
  final Object? value;

  @override
  String toString() => (isNegative ? '! ' : '') + '$value';
}
