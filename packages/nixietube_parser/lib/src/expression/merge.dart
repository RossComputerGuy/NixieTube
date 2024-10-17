enum NixMergeOperation {
  list('++'),
  attrset('//');

  const NixMergeOperation(this.token);

  final String token;
}

class NixMergeExpression {
  const NixMergeExpression(this.operation, this.left, this.right);

  final NixMergeOperation operation;
  final Object? left;
  final Object? right;

  @override
  String toString() => '$left ${operation.token} $right';
}
