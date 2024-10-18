import 'expression/assert.dart';
import 'type.dart';

class NixExpression extends NixType<dynamic> {
  const NixExpression(
    this.inner, {
    this.withs = const [],
    this.asserts = const [],
  });

  final List<Object?> withs;
  final List<Object?> asserts;
  final Object? inner;

  @override
  bool get isConstant =>
      isObjectConstantNix(withs) &&
      isObjectConstantNix(asserts) &&
      isObjectConstantNix(inner);

  @override
  dynamic constEval() {
    if (isObjectConstantNix(asserts)) {
      for (final a in asserts) {
        NixAssertExpression(a).constEval();
      }
    }
    return inner;
  }

  @override
  bool operator ==(Object other) {
    if (other is NixExpression) {
      if (other.withs.length == withs.length) {
        var i = 0;
        while (i < withs.length) {
          if (other.withs[i] != withs[i]) return false;
          i++;
        }
      } else
        return false;

      if (other.asserts.length == asserts.length) {
        var i = 0;
        while (i < asserts.length) {
          if (other.asserts[i] != asserts[i]) return false;
          i++;
        }
      } else
        return false;

      return other.inner == inner;
    }
    return false;
  }

  @override
  String toString() {
    final w = withs.map((value) => 'with $value; ').join(' ');
    final a = asserts.map((value) => 'assert $value; ').join(' ');
    return '$w$a$inner';
  }
}
