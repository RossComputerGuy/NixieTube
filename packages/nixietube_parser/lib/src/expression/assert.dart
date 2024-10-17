class NixAssertExpression {
  const NixAssertExpression(this.value);

  final Object? value;

  @override
  bool operator ==(Object other) {
    if (other is NixAssertExpression) {
      return other.value == other.value;
    }
    return false;
  }

  @override
  String toString() => 'assert $value';
}
