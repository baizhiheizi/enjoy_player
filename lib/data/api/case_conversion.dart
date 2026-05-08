/// Recursive camelCase ↔ snake_case for JSON-like structures.
library;

String _camelToSnakeToken(String input) {
  final b = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    final code = c.codeUnitAt(0);
    final isUpper = code >= 65 && code <= 90;
    if (isUpper && i > 0) {
      b.write('_');
    }
    b.write(c.toLowerCase());
  }
  return b.toString();
}

String _snakeToCamelToken(String input) {
  final parts = input.split('_');
  if (parts.isEmpty) return input;
  final b = StringBuffer(parts.first);
  for (var i = 1; i < parts.length; i++) {
    final p = parts[i];
    if (p.isEmpty) continue;
    b.write(p[0].toUpperCase());
    if (p.length > 1) {
      b.write(p.substring(1));
    }
  }
  return b.toString();
}

dynamic convertKeysToSnake(dynamic value) {
  if (value is Map) {
    return value.map<dynamic, dynamic>(
      (k, v) => MapEntry(
        k is String ? _camelToSnakeToken(k) : k,
        convertKeysToSnake(v),
      ),
    );
  }
  if (value is List) {
    return value.map(convertKeysToSnake).toList();
  }
  return value;
}

dynamic convertKeysToCamel(dynamic value) {
  if (value is Map) {
    return value.map<dynamic, dynamic>(
      (k, v) => MapEntry(
        k is String ? _snakeToCamelToken(k) : k,
        convertKeysToCamel(v),
      ),
    );
  }
  if (value is List) {
    return value.map(convertKeysToCamel).toList();
  }
  return value;
}
