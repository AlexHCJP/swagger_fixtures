import 'package:swagger_fixtures/src/generator.dart';
import 'package:test/test.dart';

void main() {
  test('builds bodies from schema examples, refs and response examples', () {
    final spec = {
      'swagger': '2.0',
      'paths': {
        '/v1/friends/{userID}': {
          'parameters': <Object?>[],
          'get': {
            'responses': {
              '200': {
                'schema': {r'$ref': '#/definitions/Friends'},
              },
              '204': {'description': 'No Content'},
            },
          },
          'post': {
            'responses': {
              '201': {
                'examples': {
                  'application/json': {'ok': true},
                },
              },
            },
          },
        },
      },
      'definitions': {
        'Friends': {
          'type': 'object',
          'properties': {
            'items': {
              'type': 'array',
              'items': {r'$ref': '#/definitions/Friend'},
            },
            'total': {'type': 'integer', 'example': 3},
          },
        },
        'Friend': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'example': 'Ann'},
            'role': {
              'type': 'string',
              'enum': ['admin', 'user'],
            },
            'best': {r'$ref': '#/definitions/Friend'},
          },
        },
      },
    };

    final all = responses(spec);
    expect(all.map((r) => r.name), [
      'getV1FriendsUserId200',
      'postV1FriendsUserId201',
    ]);
    expect(all.first.fileName, 'get_v1_friends_user_id_200.json');
    expect(all.first.body, {
      'items': [
        {'name': 'Ann', 'role': 'admin', 'best': null},
      ],
      'total': 3,
    });
    expect(all.last.body, {'ok': true});
    expect(
      dartFile('test/fixtures', all),
      contains(
        "static const getV1FriendsUserId200 = Fixture('test/fixtures/get_v1_friends_user_id_200.json');",
      ),
    );
  });

  test('isFixtureFile matches only generated names', () {
    expect(isFixtureFile('get_v1_friends_user_id_200.json'), isTrue);
    expect(isFixtureFile('post_v1_me_default.json'), isTrue);
    expect(isFixtureFile('my_data.json'), isFalse);
    expect(isFixtureFile('get_v1_me_200.dart'), isFalse);
  });
}
