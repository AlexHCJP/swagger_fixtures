## 0.2.0

- specs in YAML as well as JSON: `swagger_url` takes either, the format is detected from the content
- CI: format, analyze, test and a publish dry run on every push and pull request, and again before publishing a tag

## 0.1.0

- first release: `dart run swagger_fixtures` turns every documented response of one or more Swagger 2.0 / OpenAPI 3 specs into a JSON file and a `Fixtures` class of `Fixture` handles
- `swagger_url`, `json_output_dir` and `dart_output_file` in the `swagger_fixtures:` section of `pubspec.yaml`
