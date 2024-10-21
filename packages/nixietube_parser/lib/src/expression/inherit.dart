import 'package:asn1lib/asn1lib.dart';

import '../identifier.dart';

class NixInheritExpression {
  const NixInheritExpression(this.variables, [this.from = null]);

  final List<NixIdentifier> variables;
  final NixIdentifierList? from;

  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = ASN1Sequence();
    seq.add(ASN1UTF8String(runtimeType.toString()));
    seq.add(ASN1Sequence()
      ..elements = variables.map((v) => v.serialize(scope)).toList());
    seq.add(from != null ? from!.serialize(scope) : ASN1Null());
    return seq;
  }

  @override
  String toString() =>
      'inherit${from != null ? ' ($from)' : ''} ${variables.join(' ')}';
}
