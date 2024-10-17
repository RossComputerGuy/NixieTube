class NixImportExpression {
  const NixImportExpression(this.value);

  final Object? value;

  @override
  bool operator ==(Object other) {
    if (other is NixImportExpression) {
      return other.value == other.value;
    }
    return false;
  }

  @override
  String toString() => 'import $value';
}
