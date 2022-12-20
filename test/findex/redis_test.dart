import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';

import 'findex_redis_implementation.dart';

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

void main() {
  group('Findex Redis', () {
    if (Platform.environment.containsKey("RUN_JAVA_E2E_TESTS")) {
      return;
    }

    test('search/upsert', () async {
      final masterKey = FindexMasterKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_keys.json').readAsString()));

      final label = Uint8List.fromList(utf8.encode("Some Label"));

      await FindexRedisImplementation.init();

      expect(
          await FindexRedisImplementation.count(RedisTable.users), equals(100));
      expect(
          await FindexRedisImplementation.count(RedisTable.entries), equals(0));
      expect(
          await FindexRedisImplementation.count(RedisTable.chains), equals(0));

      await FindexRedisImplementation.indexAll(masterKey, label);

      expect(await FindexRedisImplementation.count(RedisTable.entries),
          equals(583));
      expect(await FindexRedisImplementation.count(RedisTable.chains),
          equals(618));

      final searchResults = await FindexRedisImplementation.search(
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
    });
  });
}
