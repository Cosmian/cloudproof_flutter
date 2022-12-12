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
  group('Cloudproof', () {
    if (!Platform.environment.containsKey("RUN_JAVA_E2E_TESTS")) {
      return;
    }

    test('Search and decrypt with preallocate Redis by Java', () async {
      final db = await FindexRedisImplementation.db;

      final Uint8List sseKeys = Uint8List.fromList(
          await FindexRedisImplementation.get(
              db, RedisTable.others, Uint8List.fromList([0])));
      final masterKeys =
          FindexMasterKeys.fromJson(jsonDecode(utf8.decode(sseKeys)));

      final Uint8List userDecryptionKey = Uint8List.fromList(
          await FindexRedisImplementation.get(
              db, RedisTable.others, Uint8List.fromList([3])));

      final label = Uint8List.fromList(utf8.encode("NewLabel"));

      final indexedValues = await FindexRedisImplementation.search(
          masterKeys.k, label, [Keyword.fromString("martinos")]);

      final usersIds = indexedValues.map((indexedValue) {
        return indexedValue.location.bytes;
      }).toList();

      expect(usersIds.length, equals(1));

      final Uint8List userEncryptedBytes = Uint8List.fromList(
          await FindexRedisImplementation.get(
              db, RedisTable.users, usersIds[0]));

      final result = CoverCrypt.decrypt(userDecryptionKey, userEncryptedBytes);

      expect(
          utf8.decode(result.plaintext),
          equals(
              '{"Sn":"_5N9ljQ@oS","givenName":"Martinos","departmentNumber":"377","title":"_4\\\\CWV9Qth","caYellowPagesCategory":"1:435SP2VM","uid":"FL2NMLWrw^","employeeNumber":"GItkZba]r9","Mail":"Ylcp^eugZT","TelephoneNumber":"UFvr>>zS0T","Mobile":";e_jUYXZL?","facsimileTelephoneNumber":"0QB0nOjC5I","caPersonLocalisation":"bm5n8LtdcZ","Cn":"jYTLrOls11","caUnitdn":"OIwUIa`Ih2","department":"p_>NtZd\\\\w9","co":"France"}'));
    });
  });

  group('Findex Redis', () {
    if (Platform.environment.containsKey("RUN_JAVA_E2E_TESTS")) {
      return;
    }

    test('search/upsert', () async {
      final masterKeys = FindexMasterKeys.fromJson(jsonDecode(
          await File('test/resources/findex/master_keys.json').readAsString()));

      final label = Uint8List.fromList(utf8.encode("Some Label"));

      await FindexRedisImplementation.init();

      expect(
          await FindexRedisImplementation.count(RedisTable.users), equals(100));
      expect(
          await FindexRedisImplementation.count(RedisTable.entries), equals(0));
      expect(
          await FindexRedisImplementation.count(RedisTable.chains), equals(0));

      await FindexRedisImplementation.indexAll(masterKeys, label);

      expect(await FindexRedisImplementation.count(RedisTable.entries),
          equals(583));
      expect(await FindexRedisImplementation.count(RedisTable.chains),
          equals(618));

      final indexedValues = await FindexRedisImplementation.search(
          masterKeys.k, label, [Keyword.fromString("France")]);

      final usersIds = indexedValues.map((indexedValue) {
        return indexedValue.location.bytes[0];
      }).toList();
      usersIds.sort();

      expect(usersIds, equals(expectedUsersIdsForFrance));
    });
  });
}
