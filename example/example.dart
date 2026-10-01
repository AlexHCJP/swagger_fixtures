// `dart run swagger_fixtures` writes, for every documented response, a JSON
// file and a `Fixture` pointing at it inside a generated `Fixtures` class.
// A test then parses one through a model:
//
//   final pet = Fixtures.getPetPetId200.parse(Pet.fromJson);
//
// The same thing by hand, against a file the generator would produce for
// https://petstore.swagger.io/v2/swagger.json:

import 'dart:io';

import 'package:swagger_fixtures/swagger_fixtures.dart';

/// What `fixtures.g.dart` holds for `GET /pet/{petId}` answering 200.
const getPetPetId200 = Fixture('test/fixtures/get_pet_pet_id_200.json');

/// A model of the app under test.
class Pet {
  /// A pet called [name].
  const Pet(this.name);

  /// Reads a pet from the API's JSON.
  factory Pet.fromJson(Map<String, dynamic> json) =>
      Pet(json['name'] as String);

  /// The pet's name — `doggie` in the petstore's example.
  final String name;
}

void main() {
  final pet = getPetPetId200.parse(Pet.fromJson);
  stdout.writeln(pet.name);
}
