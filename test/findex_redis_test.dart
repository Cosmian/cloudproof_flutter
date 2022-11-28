import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redis/redis.dart';

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
      final db = await RedisFindex.db;

      final Uint8List sseKeys = Uint8List.fromList(await RedisFindex.get(
          db, RedisTable.others, Uint8List.fromList([0])));
      final masterKeys = MasterKeys.fromJson(jsonDecode(utf8.decode(sseKeys)));

      final Uint8List userDecryptionKey = Uint8List.fromList(
          await RedisFindex.get(
              db, RedisTable.others, Uint8List.fromList([3])));

      final label = Uint8List.fromList(utf8.encode("NewLabel"));

      final indexedValues = await RedisFindex.search(
          masterKeys.k, label, [Word.fromString("martinos")]);

      final usersIds = indexedValues.map((indexedValue) {
        return indexedValue.location.bytes;
      }).toList();

      expect(usersIds.length, equals(1));

      final Uint8List userEncryptedBytes = Uint8List.fromList(
          await RedisFindex.get(db, RedisTable.users, usersIds[0]));

      final result =
          CoverCryptDecryption(userDecryptionKey).decrypt(userEncryptedBytes);

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
      final masterKeys = MasterKeys.fromJson(jsonDecode(
          await File('test/resources/findex/master_keys.json').readAsString()));

      final label = Uint8List.fromList(utf8.encode("Some Label"));

      await RedisFindex.init();

      expect(await RedisFindex.count(RedisTable.users), equals(100));
      expect(await RedisFindex.count(RedisTable.entries), equals(0));
      expect(await RedisFindex.count(RedisTable.chains), equals(0));

      await RedisFindex.indexAll(masterKeys, label);

      expect(await RedisFindex.count(RedisTable.entries), equals(583));
      expect(await RedisFindex.count(RedisTable.chains), equals(800));

      final indexedValues = await RedisFindex.search(
          masterKeys.k, label, [Word.fromString("France")]);

      final usersIds = indexedValues.map((indexedValue) {
        return indexedValue.location.bytes[0];
      }).toList();
      usersIds.sort();

      expect(usersIds, equals(expectedUsersIdsForFrance));
    });
  });
}

class RedisFindex {
  static Future<void> init() async {
    final db = await RedisFindex.db;

    for (final userKey in await RedisFindex.keys(RedisTable.users)) {
      await RedisFindex.del(db, userKey);
    }

    for (final entryKey in await RedisFindex.keys(RedisTable.entries)) {
      await RedisFindex.del(db, entryKey);
    }

    for (final chainKey in await RedisFindex.keys(RedisTable.chains)) {
      await RedisFindex.del(db, chainKey);
    }

    final users = jsonDecode(
        await File('test/resources/findex/users.json').readAsString());

    for (final user in users) {
      await RedisFindex.set(
          db,
          RedisTable.users,
          Uint8List.fromList([0, 0, 0, user['id']]),
          Uint8List.fromList(utf8.encode(jsonEncode(user))));
    }
  }

  static Future<Command> get db async {
    final conn = RedisConnection();
    return await conn.connect('localhost', 6379);
  }

  static Future<dynamic> execute(Command db, List<dynamic> params) async {
    Command binaryCommand = Command.from(db).setParser(RedisParserBulkBinary());
    return await binaryCommand.send_object(params);
  }

  static Uint8List key(RedisTable table, Uint8List key) {
    return Uint8List.fromList(const Utf8Encoder().convert("cosmian") +
        Uint8List.fromList([0, 0, 0, table.number] + key));
  }

  static Future<void> del(Command db, Uint8List keyWithPrefix) async {
    await execute(db, ["DEL", RedisBulk(keyWithPrefix)]);
  }

  static Future<dynamic> get(
      Command db, RedisTable table, Uint8List key) async {
    return await getWithoutPrefix(db, RedisFindex.key(table, key));
  }

  static Future<List<dynamic>> mget(
      Command db, RedisTable table, List<Uint8List> keys) async {
    return await mgetWithoutPrefix(
        db, keys.map((key) => RedisFindex.key(table, key)).toList());
  }

  static Future<dynamic> getWithoutPrefix(
      Command db, Uint8List keyWithPrefix) async {
    return await execute(db, ["GET", RedisBulk(keyWithPrefix)]);
  }

  static Future<List<dynamic>> mgetWithoutPrefix(
      Command db, List<Uint8List> keysWithPrefix) async {
    return await execute(
        db, ["MGET", ...keysWithPrefix.map((key) => RedisBulk(key))]);
  }

  static Future<void> set(
      Command db, RedisTable table, Uint8List key, Uint8List value) async {
    await execute(
        db, ["SET", RedisBulk(RedisFindex.key(table, key)), RedisBulk(value)]);
  }

  static Future<void> mset(
      Command db, RedisTable table, Map<Uint8List, Uint8List> entries) async {
    await execute(db, [
      "MSET",
      ...entries.entries.expand(
          (entry) => [RedisBulk(key(table, entry.key)), RedisBulk(entry.value)])
    ]);
  }

  static Future<void> indexAll(MasterKeys masterKeys, Uint8List label) async {
    final users = await allUsers();

    final indexedValuesAndWords = {
      for (final user in users)
        IndexedValue.fromLocation(user.location): user.indexedWords,
    };

    await upsert(masterKeys, label, indexedValuesAndWords);
  }

  static Future<List<Uint8List>> keys(RedisTable table) async {
    return (await execute(await db, [
      "KEYS",
      RedisBulk(key(table, Uint8List(0)) + utf8.encode("*"))
    ]) as List)
        .map((e) => Uint8List.fromList(e))
        .toList();
  }

  static Future<int> count(RedisTable table) async {
    return (await keys(table)).length;
  }

  static Future<List<User>> allUsers() async {
    final db = await RedisFindex.db;

    final users = await mgetWithoutPrefix(db, await keys(RedisTable.users));

    return users.map((userBytes) {
      final userJson = utf8.decode(userBytes);
      return User.fromMap(jsonDecode(userJson));
    }).toList();
  }

  static Future<Map<Uint8List, Uint8List>> fetchEntriesOrChains(
      RedisTable table, List<Uint8List> uids) async {
    final db = await RedisFindex.db;

    Map<Uint8List, Uint8List> results = {};

    final values = await mget(db, table, uids);

    for (final entry in uids.asMap().entries) {
      final value = values[entry.key];

      if (value != null) {
        if (value is! List<int>) {
          throw Exception("Should only store bytes in Redis for $table");
        }
        results[entry.value] = Uint8List.fromList(value);
      }
    }

    return results;
  }

  static Future<Map<Uint8List, Uint8List>> fetchEntries(
    List<Uint8List> uids,
  ) async {
    return await fetchEntriesOrChains(RedisTable.entries, uids);
  }

  static Future<Map<Uint8List, Uint8List>> fetchChains(
    List<Uint8List> uids,
  ) async {
    return await fetchEntriesOrChains(RedisTable.chains, uids);
  }

  static Future<void> upsertEntries(Map<Uint8List, Uint8List> entries) async {
    await mset(await db, RedisTable.entries, entries);
  }

  static Future<void> upsertChains(Map<Uint8List, Uint8List> chains) async {
    await mset(await db, RedisTable.chains, chains);
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<List<IndexedValue>> search(
    Uint8List keyK,
    Uint8List label,
    List<Word> words,
  ) async {
    return await Findex.search(
      keyK,
      label,
      words,
      Pointer.fromFunction(
        fetchEntriesCallback,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        fetchChainsCallback,
        errorCodeInCaseOfCallbackException,
      ),
    );
  }

  static Future<void> upsert(
    MasterKeys masterKeys,
    Uint8List label,
    Map<IndexedValue, List<Word>> indexedValuesAndWords,
  ) async {
    await Findex.upsert(
      masterKeys,
      label,
      indexedValuesAndWords,
      Pointer.fromFunction(
        fetchEntriesCallback,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        upsertEntriesCallback,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        upsertChainsCallback,
        errorCodeInCaseOfCallbackException,
      ),
    );
  }

  static int fetchEntriesCallback(
    Pointer<Uint8> outputPointer,
    Pointer<Uint32> outputLength,
    Pointer<Uint8> entriesUidsListPointer,
    int entriesUidsListLength,
  ) {
    return Findex.fetchWrapper(
      outputPointer,
      outputLength,
      entriesUidsListPointer,
      entriesUidsListLength,
      RedisFindex.fetchEntries,
    );
  }

  static int fetchChainsCallback(
    Pointer<Uint8> outputPointer,
    Pointer<Uint32> outputLength,
    Pointer<Uint8> chainsUidsListPointer,
    int chainsUidsListLength,
  ) {
    return Findex.fetchWrapper(
      outputPointer,
      outputLength,
      chainsUidsListPointer,
      chainsUidsListLength,
      RedisFindex.fetchChains,
    );
  }

  static int upsertEntriesCallback(
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.upsertWrapper(
      entriesListPointer,
      entriesListLength,
      RedisFindex.upsertEntries,
    );
  }

  static int upsertChainsCallback(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.upsertWrapper(
      chainsListPointer,
      chainsListLength,
      RedisFindex.upsertChains,
    );
  }
}

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String country;
  final String region;
  final String employeeNumber;
  final String security;

  User(this.id, this.firstName, this.lastName, this.phone, this.email,
      this.country, this.region, this.employeeNumber, this.security);

  factory User.fromMap(Map<String, dynamic> json) {
    return User(
      json['id'],
      json['firstName'],
      json['lastName'],
      json['phone'],
      json['email'],
      json['country'],
      json['region'],
      json['employeeNumber'],
      json['security'],
    );
  }

  Location get location {
    return Location(Uint8List.fromList([id]));
  }

  List<Word> get indexedWords {
    return [
      Word.fromString(firstName),
      Word.fromString(lastName),
      Word.fromString(phone),
      Word.fromString(email),
      Word.fromString(country),
      Word.fromString(region),
      Word.fromString(employeeNumber),
      Word.fromString(security)
    ];
  }
}

enum RedisTable {
  entries,
  chains,
  users,
  others,
}

extension RedisTableExtension on RedisTable {
  int get number {
    switch (this) {
      case RedisTable.entries:
        return 1;
      case RedisTable.chains:
        return 2;
      case RedisTable.users:
        return 3;
      case RedisTable.others:
        return 4;
      default:
        throw Exception("Unknown RedisTable $this");
    }
  }
}
