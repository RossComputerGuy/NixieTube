import 'package:asn1lib/asn1lib.dart';
import 'type.dart';

class NixIdentifier {
  const NixIdentifier(this.value);

  final List<Object?> value;

  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = ASN1Sequence();
    seq.add(ASN1UTF8String(runtimeType.toString()));
    // TODO seq.add(ASN1Sequence()..elements = value.map().toList());
    return seq;
  }

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
  int get hashCode => Object.hashAll(value);

  @override
  bool isConstant(Map<Object, Object?> scope) {
    // FIXME: implement proper handling of identifier lists or strings

    for (final key in scope.keys) {
      if (key == this) return true;
    }
    return false;
  }

  @override
  Object? constEval(Map<Object, Object?> scope) {
    // FIXME: implement proper handling of identifier lists or strings
    for (final key in scope.keys) {
      if (key == this) {
        return scope[key];
      }
    }

    throw Exception(
        'Internal error, could not match key \'$this\' in scope \'$scope\'');
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
