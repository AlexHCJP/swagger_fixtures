/// Test fixtures from a Swagger / OpenAPI spec.
///
/// `dart run swagger_fixtures` writes one JSON file per documented response and
/// a `Fixtures` class naming them; a test parses one through a model:
///
/// ```dart
/// final user = Fixtures.getV1UsersUserId200.parse(User.fromJson);
/// ```
library;

export 'src/fixture.dart';
