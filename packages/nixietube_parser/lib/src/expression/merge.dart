enum NixMergeOperation {
  list('++'),
  attrset('//');

  const NixMergeOperation(this.token);

  final String token;
}

class NixMergeExpression {
  const NixMergeExpression(this.operation, this.values);

  final NixMergeOperation operation;
  final List<Object?> values;

  @override
  String toString() => values.join(' ${operation.token} ');
}
