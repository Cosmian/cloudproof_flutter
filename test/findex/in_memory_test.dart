import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

Future<void> testFunction(FindexMasterKey masterKey, Uint8List label) async {
  FindexInMemory.init();

  expect(FindexInMemory.entryTable?.length, equals(0));
  expect(FindexInMemory.chainTable?.length, equals(0));

  await FindexInMemory.indexAll(masterKey, label);
  expect(FindexInMemory.entryTable?.length, equals(583));
  expect(FindexInMemory.chainTable?.length, equals(618));

  final searchResults = await FindexInMemory.search(
      masterKey.k, label, [Keyword.fromString("France")]);

  expect(searchResults.length, 1);

  final keyword = searchResults.entries.toList()[0].key;
  final indexedValues = searchResults.entries.toList()[0].value;
  final usersIds = indexedValues.map((indexedValue) {
    return indexedValue.location.bytes[0];
  }).toList();
  usersIds.sort();

  expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
  expect(usersIds, equals(expectedUsersIdsForFrance));
}

void main() {
  group('Findex in memory', () {
    test('in_memory', () async {
      final masterKey = FindexMasterKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));
      final label = Uint8List.fromList(utf8.encode("Some Label"));

      await testFunction(masterKey, label);
    });
  });
}
