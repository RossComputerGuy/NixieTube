import 'package:asn1lib/asn1lib.dart';
import '../type.dart';

class NixAssertExpression extends NixType<NixAssertExpression> {
  const NixAssertExpression(this.value);

  final Object? value;

  @override
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = super.serialize(scope);

    if (value is NixType) {
      seq.add((value as NixType).serialize(scope));
    } else {
      if (isConstant(scope)) {
        seq.add(ASN1Boolean(value as bool));
      }
    }
    return seq;
  }

  @override
  bool isConstant(Map<Object, Object?> scope) =>
      isObjectConstantNix(value, scope);

  @override
  NixAssertExpression constEval(Map<Object, Object?> scope) {
    if (value is NixType) {
      if ((value as NixType).constEval(scope) as bool) {
        return this;
      }

      throw Exception('Assertion \'$value\' failed');
    }

    if (isConstant(scope)) {
      if (value as bool) {
        return this;
      }

      throw Exception('Assertion \'$value\' failed');
    }

    throw Exception('Not constant');
  }

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
