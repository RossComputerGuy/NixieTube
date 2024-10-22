import 'dart:convert' show utf8;

import 'package:asn1lib/asn1lib.dart';
import 'package:meta/meta.dart';
import 'package:xxh3/xxh3.dart';

import 'expression/inherit.dart';

abstract class NixType<T> {
  const NixType();

  @override
  int get hashCode => xxh3(utf8.encode(serialize({}).toString()));

  @mustCallSuper
  ASN1Sequence serialize(Map<Object, Object?> scope) {
    final seq = ASN1Sequence();
    seq.add(ASN1UTF8String(runtimeType.toString()));
    return seq;
  }

  bool isConstant(Map<Object, Object?> scope);
  T constEval(Map<Object, Object?> scope) => isConstant(scope)
      ? throw Exception('Not implemented')
      : throw Exception('Not constant');
}

bool isObjectConstantNix(
  Object? value,
  Map<Object, Object?> scope, {
  Map<Object, Object?> fields = const {},
  List<NixInheritExpression> inherits = const [],
  bool isRec = false,
}) {
  final newScope = constEvalScope(
      scope: scope, fields: fields, inherits: inherits, isRec: isRec);

  if (value is NixType) {
    return value.isConstant(newScope);
  }

  if (value is List) {
    for (final item in value) {
      if (!isObjectConstantNix(item, newScope)) return false;
    }

    return true;
  }

  if (value is Map) {
    for (final key in value.keys) {
      if (!isObjectConstantNix(key, newScope)) return false;
    }

    for (final item in value.values) {
      if (!isObjectConstantNix(item, newScope)) return false;
    }

    return true;
  }

  return value is num || value is bool || value is String || value is Null;
}

Map<Object, Object?> constEvalScope({
  Map<Object, Object?> scope = const {},
  Map<Object, Object?> fields = const {},
  List<NixInheritExpression> inherits = const [],
  bool isRec = false,
}) {
  Map<Object, Object?> createMiniScope(Object key) => Map.fromEntries([
        ...scope.entries,
        if (isRec) ...(fields.entries.toList()..remove(key)),
      ]);

  // TODO: handle inherits
  return Map.fromEntries([
    ...scope.entries,
    ...fields.entries
        .where((entry) => isObjectConstantNix(
              entry.value,
              createMiniScope(entry.key),
            ))
        .map((entry) {
      if (entry.value is NixType) {
        return MapEntry(
          entry.key,
          (entry.value as NixType).constEval(createMiniScope(entry.key)),
        );
      }
      return entry;
    }),
  ]);
}

ASN1Object serializeNix(Object? value, Map<Object, Object?> scope) {
  if (value is NixType) {
    return (value as NixType).serialize(scope);
  }

  if (value is String) {
    return ASN1UTF8String(value as String);
  }

  if (value is bool) {
    return ASN1Boolean(value as bool);
  }

  if (value is int) {
    return ASN1Integer.fromInt(value as int);
  }

  if (value is Null) {
    return ASN1Null();
  }

  if (value is List) {
    final list = ASN1Sequence();

    for (final item in (value as List)) {
      list.add(serializeNix(item, scope));
    }

    return list;
  }

  if (value is Map) {
    final map = ASN1Sequence();

    for (final entry in (value as Map).entries) {
      final field = ASN1Sequence();

      field.add(serializeNix(entry.key, scope));
      field.add(serializeNix(entry.value, scope));

      map.add(field);
    }

    return map;
  }

  throw Exception('Cannot serialize type ${value.runtimeType}');
}
