import 'dart:convert';
import 'dart:io';

/// One generated JSON response, read from disk on demand.
///
/// [path] is relative to the package root, which is the working directory
/// both `dart test` and `flutter test` run in.
class Fixture {
  /// A fixture whose JSON lives at [path].
  const Fixture(this.path);

  /// The JSON file, relative to the package root.
  final String path;

  /// The file as it is on disk.
  String get raw => File(path).readAsStringSync();

  /// The decoded body: a map, a list or a scalar.
  Object? get json => jsonDecode(raw);

  /// The body, when it is a JSON object.
  Map<String, dynamic> get map => json! as Map<String, dynamic>;

  /// The body, when it is a JSON array.
  List<dynamic> get list => json! as List<dynamic>;

  /// The fixture through a model's `fromJson`: `Fixtures.getV1Me200.parse(UserModel.fromJson)`.
  T parse<T>(T Function(Map<String, dynamic> json) fromJson) => fromJson(map);
}
