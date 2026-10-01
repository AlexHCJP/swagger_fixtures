import 'dart:convert';
import 'dart:io';

import 'package:swagger_fixtures/src/generator.dart';
import 'package:yaml/yaml.dart';

/// Run from the consuming package's root:
///
/// ```yaml
/// # pubspec.yaml
/// swagger_fixtures:
///   swagger_url: https://api.example.com/swagger.json  # or a list of them; a local path works too
///   json_output_dir: test/fixtures                     # default
///   dart_output_file: test/fixtures/fixtures.g.dart      # default <json_output_dir>/fixtures.g.dart
/// ```
Future<void> main() async {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  final config = pubspec['swagger_fixtures'] as YamlMap?;
  if (config == null) {
    stderr.writeln('pubspec.yaml has no `swagger_fixtures:` section.');
    exit(64);
  }
  final urls = switch (config['swagger_url']) {
    final String one => [one],
    final YamlList many => many.cast<String>(),
    _ =>
      throw const FormatException(
        'swagger_fixtures.swagger_url must be a string or a list',
      ),
  };
  final jsonOutputDir = (config['json_output_dir'] as String? ??
          'test/fixtures')
      .replaceAll(RegExp(r'/+$'), '');
  final dartOutputFile =
      config['dart_output_file'] as String? ?? '$jsonOutputDir/fixtures.g.dart';

  final all = <Response>[];
  for (final url in urls) {
    final spec = jsonDecode(await _read(url)) as Map<String, dynamic>;
    all.addAll(responses(spec));
  }

  final dir = Directory(jsonOutputDir);
  // Stale fixtures go with the endpoints that dropped out of the spec. Only
  // files named like ours: [jsonOutputDir] may be a folder that holds other JSON too.
  if (dir.existsSync()) {
    for (final f in dir.listSync().whereType<File>().where(
      (f) => isFixtureFile(f.uri.pathSegments.last),
    )) {
      f.deleteSync();
    }
  }
  dir.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  for (final r in all) {
    File(
      '$jsonOutputDir/${r.fileName}',
    ).writeAsStringSync('${encoder.convert(r.body)}\n');
  }
  File(dartOutputFile)
    ..createSync(recursive: true)
    ..writeAsStringSync(dartFile(jsonOutputDir, all));
  stdout.writeln(
    'swagger_fixtures: ${all.length} fixtures → $jsonOutputDir, $dartOutputFile',
  );
}

Future<String> _read(String url) async {
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return File(url).readAsString();
  }
  final client = HttpClient();
  try {
    final res = await (await client.getUrl(Uri.parse(url))).close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw HttpException('${res.statusCode} for $url');
    }
    return body;
  } finally {
    client.close();
  }
}
