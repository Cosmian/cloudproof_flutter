import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';

import 'in_memory_findex.dart';

const expectedUsersIdsForFrance = [
  4,
  5,
  7,
  8,
  14,
  17,
  19,
  20,
  23,
  34,
  37,
  43,
  46,
  48,
  55,
  56,
  60,
  61,
  63,
  65,
  68,
  70,
  71,
  77,
  80,
  82,
  83,
  85,
  86,
  96
];

Future<void> testFunction(FindexKey key, String label) async {
  FindexInMemory.init(key, label);

  expect(FindexInMemory.entryTable?.length, equals(0));
  expect(FindexInMemory.chainTable?.length, equals(0));

  final upsertResults = await FindexInMemory.indexAll(key);
  expect(upsertResults.length, 583);

  Map<IndexedValue, Set<Keyword>> additions = {};
  additions[IndexedValue.fromLocation(Location.fromNumber(0))] = {
    Keyword.fromString("Felix")
  };
  final secondInsertion = await FindexInMemory.upsert(additions);
  expect(secondInsertion.length, 0);

  expect(FindexInMemory.entryTable?.length, equals(583 + 1));
  expect(FindexInMemory.chainTable?.length, equals(618 + 1));

  log("\n\n\n Search \n\n\n");
  final searchResults =
      await FindexInMemory.search({Keyword.fromString("France")});

  expect(searchResults.length, 1);

  final keyword = searchResults.entries.toList()[0].key;
  final indexedValues = searchResults.entries.toList()[0].value;
  final usersIds = indexedValues.map((location) {
    return location.number;
  }).toList();
  usersIds.sort();

  expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
  expect(usersIds, equals(expectedUsersIdsForFrance));
}

void main() {
  group('Findex in memory', () {
    test('in_memory', () async {
      final findexKey = FindexKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));

      await testFunction(findexKey, "Some Label");
    }, tags: 'in_memory');
  });
}
