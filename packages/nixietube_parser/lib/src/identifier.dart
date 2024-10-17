class NixIdentifier {
  const NixIdentifier(this.value);

  final List<Object?> value;

  @override
  bool operator ==(Object other) {
    if (other is NixIdentifier) {
      if (other.value.length == value.length) {
        var i = 0;
        while (i < value.length) {
          if (other.value[i] != value[i]) return false;
          i++;
        }

        return true;
      }
    }
    return false;
  }

  @override
  String toString() => value.join('');
}

class NixIdentifierList {
  const NixIdentifierList(this.value);

  final List<Object?> value;

  @override
  bool operator ==(Object other) {
    if (other is NixIdentifierList) {
      if (other.value.length == value.length) {
        var i = 0;
        while (i < value.length) {
          if (other.value[i] != value[i]) return false;
          i++;
        }

        return true;
      }
    }
    return false;
  }

  @override
  String toString() => value.join('.');
}
