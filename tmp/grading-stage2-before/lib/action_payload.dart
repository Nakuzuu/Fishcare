import 'dart:convert';

Object? _ordered(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return <String, Object?>{for (final key in keys) key: _ordered(value[key])};
  }
  if (value is List) return value.map(_ordered).toList();
  return value;
}

String canonicalPayload(Map<String, Object?> payload) =>
    jsonEncode(_ordered(payload));
