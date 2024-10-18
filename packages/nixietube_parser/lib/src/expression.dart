import 'expression/assert.dart';
import 'expression/attrset.dart';
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
  bool isConstant(Map<Object, Object?> scope) {
    if (isObjectConstantNix(withs, scope)) {
      final newScope = Map.fromEntries([
        ...scope.entries,
        ...withs
            .whereType<NixAttributeSetExpression>()
            .map((entry) => entry.constEval(scope).entries.toList())
            .toList()
            .fold(<MapEntry<Object, Object?>>[], (prev, item) {
          return prev.toList()..addAll(item);
        }),
      ]);

      return isObjectConstantNix(asserts, newScope) &&
          isObjectConstantNix(inner, newScope);
    }

    return false;
  }

  @override
  dynamic constEval(Map<Object, Object?> scope) {
    final newScope = Map.fromEntries([
      ...scope.entries,
      ...withs
          .whereType<NixAttributeSetExpression>()
          .map((entry) => entry.constEval(scope).entries.toList())
          .toList()
          .fold(<MapEntry<Object, Object?>>[], (prev, item) {
        return prev.toList()..addAll(item);
      }),
    ]);

    if (isObjectConstantNix(asserts, newScope)) {
      for (final a in asserts) {
        NixAssertExpression(a).constEval(newScope);
      }
    }

    if (inner is NixType) {
      return (inner as NixType).constEval(newScope);
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
