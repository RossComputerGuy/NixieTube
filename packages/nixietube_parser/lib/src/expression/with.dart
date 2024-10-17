class NixWithExpression {
  const NixWithExpression(this.value);

  final Object? value;

  @override
  bool operator ==(Object other) {
    if (other is NixWithExpression) {
      return other.value == other.value;
    }
    return false;
  }

  @override
  String toString() => 'with $value';
}
