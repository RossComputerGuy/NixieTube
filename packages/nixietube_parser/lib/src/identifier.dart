import 'type.dart';

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

class NixIdentifierList extends NixType<Object?> {
  const NixIdentifierList(this.value);

  final List<Object?> value;

  @override
  bool isConstant(Map<Object, Object?> scope) {
    // FIXME: implement handling of identifier lists or strings
    return true;
  }

  @override
  Object? constEval(Map<Object, Object?> scope) {
    // FIXME: implement handling of identifier lists or strings
    return null;
  }

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
