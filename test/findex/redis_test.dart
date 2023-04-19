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
    test('search/upsert', () async {
      final masterKey = FindexMasterKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));

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
      final locations = searchResults.entries.toList()[0].value;
      final usersIds = locations.map((location) {
        return location.number;
      }).toList();
      usersIds.sort();

      expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
      expect(usersIds, equals(expectedUsersIdsForFrance));
    }, tags: 'redis');

    test('exceptions', () async {
      final masterKey = FindexMasterKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));

      final label = Uint8List.fromList(utf8.encode("Some Label"));

      await FindexRedisImplementation.init();
      await FindexRedisImplementation.indexAll(masterKey, label);

      await FindexRedisImplementation.setThrowInsideFetch();
      try {
        await FindexRedisImplementation.search(
            masterKey.k, label, [Keyword.fromString("France")]);
      } catch (e, stacktrace) {
        // When an exception is thrown inside a callback
        // we should rethrow the exception from our functions
        // instead of throwing a generic Findex exception.
        // The message should be the same
        // The stacktrace should point to the correct line inside the user callback.
        // This is working saving by the exceptions during the callbacks runs, returning a
        // specific error code, Findex forwards the specific error code, Flutter catch the
        // error code at the end of the search/upsert operation and find the saved exception
        // to rethrow.
        expect(
          e.toString(),
          "Unsupported operation: Redis Should Throw Exception",
        );
        expect(stacktrace.toString(),
            contains("FindexRedisImplementation.fetchEntriesOrChains"));
        expect(
          stacktrace.toString(),
          contains(
              "test/findex/findex_redis_implementation.dart:170:7"), // When moving lines inside the Findex implementation this could fail, put the line of the tag :ExceptionLine
        );

        return;
      } finally {
        await FindexRedisImplementation.resetThrowInsideFetch();
      }

      expect(true, false);
    }, tags: 'redis');
  });
}
