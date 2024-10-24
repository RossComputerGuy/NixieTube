import 'package:asn1lib/asn1lib.dart';
import 'type.dart';

class NixIdentifier extends NixType<List<Object?>> {
  const NixIdentifier(this.value);

  final List<Object?> value;

  @override
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = super.serialize(scope);
    seq.add(serializeNix(value, scope));
    return seq;
  }

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(value, scope);

  @override
  List<Object?> constEval(Map<Object, Object?> scope) => value
      .map((v) => v is NixType ? (v as NixType).constEval(scope) : v)
      .toList();

  @override
  String toString() => value.join('');
}

class NixIdentifierList extends NixType<Object?> {
  const NixIdentifierList(this.value);

  final List<Object?> value;

  @override
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = super.serialize(scope);
    seq.add(serializeNix(value, scope));
    return seq;
  }

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
  String toString() => value.join('.');
}
