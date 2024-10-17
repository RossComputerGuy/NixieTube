class NixPath {
  const NixPath(this.items);

  final List<Object?> items;

  @override
  String toString() => items.join('/');
}
