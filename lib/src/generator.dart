const _methods = {'get', 'put', 'post', 'delete', 'patch', 'head', 'options'};

/// One documented response with a JSON body.
class Response {
  /// A response named [name], saved as [fileName], answering with [body].
  Response(this.name, this.fileName, this.body);

  /// Dart identifier, e.g. `getV1FriendsUserId200`.
  final String name;

  /// e.g. `get_v1_friends_user_id_200.json`.
  final String fileName;

  /// The JSON body, already decoded.
  final Object? body;
}

/// Every response in a Swagger 2.0 or OpenAPI 3 [spec] that has a body.
List<Response> responses(Map<String, dynamic> spec) {
  final out = <Response>[];
  final paths = spec['paths'] as Map<String, dynamic>? ?? const {};
  for (final MapEntry(key: path, value: item) in paths.entries) {
    for (final MapEntry(key: method, value: op)
        in (item as Map<String, dynamic>).entries) {
      if (!_methods.contains(method)) continue;
      final codes =
          (op as Map<String, dynamic>)['responses'] as Map<String, dynamic>? ??
          const {};
      for (final MapEntry(key: code, value: res) in codes.entries) {
        final body = _responseBody(spec, res as Map<String, dynamic>);
        if (body == _none) continue;
        final words = [method, ..._words(path), code];
        out.add(Response(_camel(words), '${words.join('_')}.json', body));
      }
    }
  }
  return out;
}

const _none = Object();

/// Whether [name] is a file [responses] would produce: `get_v1_me_200.json`.
bool isFixtureFile(String name) => RegExp(
  '^(${_methods.join('|')})_[a-z0-9_]*_[0-9a-z]+\\.json\$',
).hasMatch(name);

Object? _responseBody(Map<String, dynamic> spec, Map<String, dynamic> ref) {
  final res = _deref(spec, ref);
  // Swagger 2.0: `examples: {application/json: ...}` beside `schema`.
  final examples = res['examples'] as Map<String, dynamic>?;
  if (examples != null && examples.containsKey('application/json')) {
    return examples['application/json'];
  }
  if (res['schema'] != null) return example(spec, res['schema']);
  // OpenAPI 3: `content: {application/json: {example | examples | schema}}`.
  final media =
      (res['content'] as Map<String, dynamic>?)?['application/json']
          as Map<String, dynamic>?;
  if (media == null) return _none;
  if (media.containsKey('example')) return media['example'];
  final named = media['examples'] as Map<String, dynamic>?;
  if (named != null && named.isNotEmpty) {
    return _deref(spec, named.values.first as Map<String, dynamic>)['value'];
  }
  if (media['schema'] != null) return example(spec, media['schema']);
  return _none;
}

/// A JSON value for [schema]: its own `example` where it has one, otherwise
/// built from its properties, otherwise a placeholder of the right type.
Object? example(
  Map<String, dynamic> spec,
  Object? schema, [
  Set<String> seen = const {},
]) {
  if (schema is! Map<String, dynamic>) return null;
  final ref = schema[r'$ref'] as String?;
  if (ref != null) {
    // A type that contains itself stops at null rather than recursing forever.
    if (seen.contains(ref)) return null;
    return example(spec, _resolve(spec, ref), {...seen, ref});
  }
  if (schema.containsKey('example')) return schema['example'];
  if (schema['default'] != null) return schema['default'];
  if (schema['enum'] case [final first, ...]) return first;
  for (final key in ['oneOf', 'anyOf']) {
    if (schema[key] case [final first, ...]) return example(spec, first, seen);
  }
  if (schema['allOf'] case final List<Object?> parts) {
    return {
      for (final part in parts)
        if (example(spec, part, seen) case final Map<String, dynamic> m) ...m,
    };
  }
  final props = schema['properties'] as Map<String, dynamic>?;
  return switch (schema['type']) {
    'array' => [example(spec, schema['items'], seen)],
    'string' => _string(schema['format'] as String?),
    'integer' => 0,
    'number' => 0.0,
    'boolean' => false,
    _ when props != null => {
      for (final MapEntry(:key, :value) in props.entries)
        key: example(spec, value, seen),
    },
    'object' => <String, dynamic>{},
    _ => null,
  };
}

String _string(String? format) => switch (format) {
  'date-time' => '2026-01-01T00:00:00Z',
  'date' => '2026-01-01',
  'uuid' => '00000000-0000-0000-0000-000000000000',
  'email' => 'user@example.com',
  _ => 'string',
};

Map<String, dynamic> _deref(
  Map<String, dynamic> spec,
  Map<String, dynamic> node,
) {
  final ref = node[r'$ref'] as String?;
  return ref == null ? node : _resolve(spec, ref);
}

Map<String, dynamic> _resolve(Map<String, dynamic> spec, String ref) {
  if (!ref.startsWith('#/')) {
    throw FormatException('Only local refs are supported', ref);
  }
  Object? node = spec;
  for (final part in ref.substring(2).split('/')) {
    node =
        (node as Map<String, dynamic>)[part
            .replaceAll('~1', '/')
            .replaceAll('~0', '~')];
  }
  if (node is! Map<String, dynamic>) {
    throw FormatException('Unresolved ref', ref);
  }
  return node;
}

/// `/v1/friends/{userID}` → `[v1, friends, user, id]`.
List<String> _words(String path) =>
    path
        .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
        .toLowerCase()
        .split(RegExp('[^a-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toList();

String _camel(List<String> words) =>
    words.first +
    words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();

/// The Dart file naming every fixture in [all], whose JSON is in [outputDir]
/// (relative to the package root, wherever the Dart file itself goes).
String dartFile(String outputDir, List<Response> all) {
  final b =
      StringBuffer()
        ..writeln(
          '// GENERATED by swagger_fixtures. Do not edit — rerun `dart run swagger_fixtures`.',
        )
        ..writeln('// ignore_for_file: type=lint')
        ..writeln()
        ..writeln("import 'package:swagger_fixtures/swagger_fixtures.dart';")
        ..writeln()
        ..writeln('abstract final class Fixtures {');
  for (final r in all) {
    b.writeln(
      "  static const ${r.name} = Fixture('$outputDir/${r.fileName}');",
    );
  }
  b.writeln('}');
  return b.toString();
}
