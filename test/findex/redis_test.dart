import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';

import 'redis_findex.dart';
import 'redis_multi_entry_tables.dart';

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
      final findexKey = FindexKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));

      final label = Uint8List.fromList(utf8.encode("Some Label"));

      await FindexRedisImplementation.init();

      expect(
          await FindexRedisImplementation.count(RedisTable.users), equals(100));
      expect(
          await FindexRedisImplementation.count(RedisTable.entries), equals(0));
      expect(
          await FindexRedisImplementation.count(RedisTable.chains), equals(0));

      final upsertResults =
          await FindexRedisImplementation.indexAll(findexKey, label);
      expect(upsertResults.length, 583);

      expect(await FindexRedisImplementation.count(RedisTable.entries),
          equals(583));
      expect(await FindexRedisImplementation.count(RedisTable.chains),
          equals(618));

      final searchResults = await FindexRedisImplementation.search(
          findexKey.key, label, {Keyword.fromString("France")});

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

    // test('exceptions', () async {
    //   final findexKey = FindexKey.fromJson(jsonDecode(
    //       await File('test/resources/findex/master_key.json').readAsString()));

    //   final label = Uint8List.fromList(utf8.encode("Some Label"));

    //   await FindexRedisImplementation.init();
    //   final upsertResults =
    //       await FindexRedisImplementation.indexAll(findexKey, label);
    //   expect(upsertResults.length, 583);

    //   await FindexRedisImplementation.setThrowInsideFetch();
    //   try {
    //     await FindexRedisImplementation.search(
    //         findexKey.key, label, {Keyword.fromString("France")});
    //   } catch (e, stacktrace) {
    //     // When an exception is thrown inside a callback
    //     // we should rethrow the exception from our functions
    //     // instead of throwing a generic Findex exception.
    //     // The message should be the same
    //     // The stacktrace should point to the correct line inside the user callback.
    //     // This is working saving by the exceptions during the callbacks runs, returning a
    //     // specific error code, Findex forwards the specific error code, Flutter catch the
    //     // error code at the end of the search/upsert operation and find the saved exception
    //     // to rethrow.
    //     expect(
    //       e.toString(),
    //       "Unsupported operation: Redis Should Throw Exception",
    //     );
    //     expect(stacktrace.toString(),
    //         contains("FindexRedisImplementation.fetchEntriesOrChains"));
    //     expect(
    //       stacktrace.toString(),
    //       contains(
    //           "test/findex/redis_findex.dart:170:7"), // When moving lines inside the Findex implementation this could fail, put the line of the tag :ExceptionLine
    //     );

    //     return;
    //   } finally {
    //     await FindexRedisImplementation.resetThrowInsideFetch();
    //   }

    //   expect(true, false);
    // }, tags: 'exceptions');

    test('redis multi entry tables', () async {
      final findexKey = FindexKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));

      final label = Uint8List.fromList(utf8.encode("Some Label"));

      await RedisMultiEntryTables.init();

      expect(await RedisMultiEntryTables.count(RedisTables.users), equals(100));
      expect(
          await RedisMultiEntryTables.count(RedisTables.entries_1), equals(0));
      expect(
          await RedisMultiEntryTables.count(RedisTables.entries_2), equals(0));
      expect(
          await RedisMultiEntryTables.count(RedisTables.chains_1), equals(0));
      expect(
          await RedisMultiEntryTables.count(RedisTables.chains_2), equals(0));

      await RedisMultiEntryTables.upsert_1(findexKey, label, {
        IndexedValue.fromLocation(Location.fromNumber(1)): {
          Keyword.fromString("John"),
        }
      }, {});
      await RedisMultiEntryTables.upsert_2(findexKey, label, {
        IndexedValue.fromLocation(Location.fromNumber(2)): {
          Keyword.fromString("John")
        }
      }, {});

      expect(
          await RedisMultiEntryTables.count(RedisTables.entries_1), equals(1));
      expect(
          await RedisMultiEntryTables.count(RedisTables.entries_2), equals(1));
      expect(
          await RedisMultiEntryTables.count(RedisTables.chains_1), equals(1));
      expect(
          await RedisMultiEntryTables.count(RedisTables.chains_2), equals(1));

      final searchResults = await RedisMultiEntryTables.search(
          findexKey.key, label, {Keyword.fromString("John")},
          entryTableNumber: 2);
      expect(searchResults.length, 1);

      final keyword = searchResults.entries.toList()[0].key;
      final indexedValues = searchResults.entries.toList()[0].value;
      final usersIds = indexedValues.map((location) {
        return location.number;
      }).toList();
      usersIds.sort();

      expect(Keyword.fromString("John").toBase64(), keyword.toBase64());
      expect(usersIds, equals([1, 2]));
    }, tags: 'redis');
  });
}
