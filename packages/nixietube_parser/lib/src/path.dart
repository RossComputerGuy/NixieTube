class NixPath {
  const NixPath(this.items);

  final List<Object?> items;

  @override
  bool operator ==(Object other) {
    if (other is NixPath) {
      if (other.items.length == items.length) {
        var i = 0;
        while (i < items.length) {
          if (other.items[i] != items[i]) return false;
          i++;
        }
        return true;
      }
    }
    return false;
  }

  @override
  String toString() => items.join('/');
}
