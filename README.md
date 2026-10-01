# 🧪 Swagger Fixtures

<div align="center">
  <a href="https://pub.dev/packages/swagger_fixtures">
    <img src="https://img.shields.io/pub/v/swagger_fixtures?label=Pub&logo=dart" alt="Pub Package" />
  </a>
  <a href="https://pub.dev/packages/swagger_fixtures">
    <img src="https://img.shields.io/pub/likes/swagger_fixtures?style=flat&logo=dart&label=Likes" alt="Pub Likes" />
  </a>
  <a href="https://pub.dev/packages/swagger_fixtures/score">
    <img src="https://img.shields.io/pub/points/swagger_fixtures?label=Score&logo=dart" alt="Pub Score" />
  </a>
  <a href="https://pub.dev/packages/swagger_fixtures">
    <img src="https://img.shields.io/pub/dm/swagger_fixtures?style=flat&color=blue&logo=dart&label=Downloads" alt="Pub Monthly Downloads" />
  </a>
  <a href="https://github.com/AlexHCJP/swagger_fixtures">
    <img src="https://img.shields.io/github/stars/AlexHCJP/swagger_fixtures?style=flat&logo=github&colorB=deeppink&label=Stars" alt="Star on Github" />
  </a>
  <a href="https://github.com/AlexHCJP/swagger_fixtures">
    <img src="https://img.shields.io/github/forks/AlexHCJP/swagger_fixtures?color=orange&label=Forks&logo=github" alt="Forks on Github" />
  </a>
  <a href="https://github.com/AlexHCJP/swagger_fixtures/graphs/contributors">
    <img src="https://img.shields.io/github/contributors/AlexHCJP/swagger_fixtures?style=flat&logo=github&colorB=yellow&label=Contributors" alt="Contributors" />
  </a>
  <a href="https://github.com/AlexHCJP/swagger_fixtures/issues">
    <img src="https://img.shields.io/github/issues/AlexHCJP/swagger_fixtures?label=Issues&logo=github&color=purple" alt="Issues" />
  </a>
  <a href="https://github.com/AlexHCJP/swagger_fixtures">
    <img src="https://img.shields.io/github/languages/code-size/AlexHCJP/swagger_fixtures?logo=github&color=blue&label=Size" alt="Code size" />
  </a>
  <a href="https://github.com/AlexHCJP/swagger_fixtures/blob/HEAD/LICENSE">
    <img src="https://img.shields.io/github/license/AlexHCJP/swagger_fixtures?label=License&color=red&logo=Leanpub" alt="License" />
  </a>
</div>

Test fixtures straight from your API's Swagger / OpenAPI spec.

`swagger_fixtures` reads the spec, writes one JSON file per documented response
— built from the spec's own `example` values — and generates a Dart file that
names every one of them, ready to parse in a test:

```dart
final user = Fixtures.getV1Users200.parse(User.fromJson);
```

When the backend changes a response, regenerate, and the tests that parse it
tell you whether your models still fit.

## 📋 Features

- 🌐 Reads one or many specs — by URL or local path
- 📄 One JSON file per documented response, every status code included
- 🧩 Bodies built from the spec's `example` values, `$ref`s followed
- 🎯 A generated `Fixtures` class with a typed handle per response
- 🔄 Rerun to refresh; responses gone from the spec are cleaned up

## 🚀 Installation

### In a project (as dev dependency)

```shell
dart pub add -d swagger_fixtures
```

Or manually in `pubspec.yaml`:

```yaml
dev_dependencies:
  swagger_fixtures: ^0.2.0
```

### Globally

```shell
dart pub global activate swagger_fixtures
```

Then run as `swagger_fixtures` from the package root.

## ⚙️ Configuration

Add a `swagger_fixtures:` section to the same `pubspec.yaml`:

```yaml
swagger_fixtures:
  # Required. One spec, or a list of them, JSON or YAML. A local file path works too.
  swagger_url:
    - https://api.example.com/auth/swagger/doc.json
    - https://api.example.com/billing/swagger/doc.json

  # Optional. Where the JSON files go. Default: test/fixtures
  json_output_dir: test/fixtures

  # Optional. Where the Dart file goes. Default: <json_output_dir>/fixtures.g.dart
  dart_output_file: test/fixtures/fixtures.g.dart
```

Paths are relative to the package root.

## 📖 Usage

```sh
dart run swagger_fixtures
```

```
swagger_fixtures: 42 fixtures → test/fixtures, test/fixtures/fixtures.g.dart
```

Rerun it whenever the spec changes. JSON files for responses that left the
spec are removed; other files in `json_output_dir` are left alone.

## 📂 What you get

For `GET /v1/users/{userID}` answering `200`:

- `test/fixtures/get_v1_users_user_id_200.json`
- in `fixtures.g.dart`:

  ```dart
  abstract final class Fixtures {
    static const getV1UsersUserId200 = Fixture('test/fixtures/get_v1_users_user_id_200.json');
  }
  ```

Names are `<method><path words><status>`, so every documented status code —
`401`, `404`, `422`, … — gets its own fixture as well.

## 🧪 Use in tests

```dart
import 'package:test/test.dart'; // or flutter_test

import 'fixtures/fixtures.g.dart';

void main() {
  test('user parses', () {
    final user = Fixtures.getV1UsersUserId200.parse(User.fromJson);
    expect(user.name, 'Ann');
  });
}
```

`Fixture` reads its file on demand:

| Member | Returns |
| --- | --- |
| `raw` | the file as a `String` |
| `json` | `jsonDecode(raw)` |
| `map` | the body as `Map<String, dynamic>` |
| `list` | the body as `List<dynamic>` |
| `parse(fromJson)` | `fromJson(map)` |

Paths are relative to the package root, which is the working directory of both
`dart test` and `flutter test`.

## 🔨 How a body is built

For each response, the first of these that exists wins:

1. the response's own example — Swagger 2.0 `examples['application/json']`,
   OpenAPI 3 `content['application/json'].example` or the first of `examples`;
2. a body built from the response schema:
   - a schema's `example`, then `default`, then the first `enum` value;
   - objects are built property by property, arrays hold one item;
   - `$ref`, `allOf` (merged), `oneOf` / `anyOf` (first option) are followed;
   - anything else gets a placeholder of its type: `"string"`, `0`, `0.0`,
     `false`; `date-time`, `date`, `uuid` and `email` strings get a value in
     that format;
   - a type that contains itself stops at `null` on the repeat.

Responses without a JSON body (`204`, files) are skipped.

The more `example` values your spec carries, the closer the fixtures are to
real responses.

## ⚠️ Limitations

- Local `$ref`s only (`#/...`).
- Fixtures are read with `dart:io`, so they work in VM tests (`dart test`,
  `flutter test`), not in browser tests.
