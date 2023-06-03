import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:redis/redis.dart';

import 'user.dart';

class FindexRedisImplementation {
  static const String throwInsideFetchFilepath = "/tmp/redisThrowInsideFetch";

  static Future<bool> shouldThrowInsideFetch() async {
    return await File(FindexRedisImplementation.throwInsideFetchFilepath)
        .exists();
  }

  static Future<void> setThrowInsideFetch() async {
    await File(FindexRedisImplementation.throwInsideFetchFilepath).create();
  }

  static Future<void> resetThrowInsideFetch() async {
    await File(FindexRedisImplementation.throwInsideFetchFilepath).delete();
  }

  static Future<void> init() async {
    final db = await FindexRedisImplementation.db;

    for (final userKey
        in await FindexRedisImplementation.keys(RedisTable.users)) {
      await FindexRedisImplementation.del(db, userKey);
    }

    for (final entryKey
        in await FindexRedisImplementation.keys(RedisTable.entries)) {
      await FindexRedisImplementation.del(db, entryKey);
    }

    for (final chainKey
        in await FindexRedisImplementation.keys(RedisTable.chains)) {
      await FindexRedisImplementation.del(db, chainKey);
    }

    final users = jsonDecode(
        await File('test/resources/findex/users.json').readAsString());

    for (final user in users) {
      await FindexRedisImplementation.set(
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
    return await getWithoutPrefix(
        db, FindexRedisImplementation.key(table, key));
  }

  static Future<List<dynamic>> mget(
      Command db, RedisTable table, List<Uint8List> keys) async {
    return await mgetWithoutPrefix(db,
        keys.map((key) => FindexRedisImplementation.key(table, key)).toList());
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
    await execute(db, [
      "SET",
      RedisBulk(FindexRedisImplementation.key(table, key)),
      RedisBulk(value)
    ]);
  }

  static Future<List<UidAndValue>> mset(
      Command db, RedisTable table, List<UpsertData> entries) async {
    await execute(db, [
      "MSET",
      ...entries.expand((entry) =>
          [RedisBulk(key(table, entry.uid)), RedisBulk(entry.newValue)])
    ]);
    return [];
  }

  static Future<void> mset2(
      Command db, RedisTable table, List<UidAndValue> entries) async {
    await execute(db, [
      "MSET",
      ...entries.expand(
          (entry) => [RedisBulk(key(table, entry.uid)), RedisBulk(entry.value)])
    ]);
  }

  static Future<void> indexAll(
      FindexMasterKey masterKey, Uint8List label) async {
    final users = await allUsers();

    final additions = {
      for (final user in users)
        IndexedValue.fromLocation(user.location): user.indexedWords,
    };

    await upsert(masterKey, label, additions, {});
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
    final db = await FindexRedisImplementation.db;

    final users = await mgetWithoutPrefix(db, await keys(RedisTable.users));

    return users.map((userBytes) {
      final userJson = utf8.decode(userBytes);
      return User.fromMap(jsonDecode(userJson));
    }).toList();
  }

  static Future<List<UidAndValue>> fetchEntriesOrChains(
      RedisTable table, Uids uids) async {
    List<UidAndValue> results = [];

    final db = await FindexRedisImplementation.db;

    if (await FindexRedisImplementation.shouldThrowInsideFetch()) {
      throw UnsupportedError("Redis Should Throw Exception"); // :ExceptionLine
    }

    final values = await mget(db, table, uids.uids);

    for (final entry in uids.uids.asMap().entries) {
      final value = values[entry.key];

      if (value != null) {
        if (value is! List<int>) {
          throw Exception("Should only store bytes in Redis for $table");
        }
        results.add(UidAndValue(entry.value, Uint8List.fromList(value)));
      }
    }

    return results;
  }

  static Future<List<UidAndValue>> fetchEntries(Uids uids) async {
    return await fetchEntriesOrChains(RedisTable.entries, uids);
  }

  static Future<List<UidAndValue>> fetchChains(Uids uids) async {
    return await fetchEntriesOrChains(RedisTable.chains, uids);
  }

  static Future<List<UidAndValue>> upsertEntries(
      List<UpsertData> entries) async {
    //TODO: implement findex multithreaded support if required
    return await mset(await db, RedisTable.entries, entries);
  }

  static Future<void> upsertChains(List<UidAndValue> chains) async {
    await mset2(await db, RedisTable.chains, chains);
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<Map<Keyword, List<Location>>> search(
      Uint8List keyK, Uint8List label, List<Keyword> words,
      {int entryTableNumber = 1}) async {
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
        entryTableNumber: entryTableNumber);
  }

  static Future<void> upsert(
    FindexMasterKey masterKey,
    Uint8List label,
    Map<IndexedValue, List<Keyword>> additions,
    Map<IndexedValue, List<Keyword>> deletions,
  ) async {
    await Findex.upsert(
      masterKey,
      label,
      additions,
      deletions,
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
    Pointer<UnsignedChar> outputEntryTableLinesPointer,
    Pointer<UnsignedInt> outputEntryTableLinesLength,
    Pointer<UnsignedChar> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapAsyncFetchCallback(
      FindexRedisImplementation.fetchEntries,
      outputEntryTableLinesPointer,
      outputEntryTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }

  static int fetchChainsCallback(
    Pointer<UnsignedChar> outputChainTableLinesPointer,
    Pointer<UnsignedInt> outputChainTableLinesLength,
    Pointer<UnsignedChar> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapAsyncFetchCallback(
      FindexRedisImplementation.fetchChains,
      outputChainTableLinesPointer,
      outputChainTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }

  static int upsertEntriesCallback(
    Pointer<UnsignedChar> outputRejectedEntriesListPointer,
    Pointer<UnsignedInt> outputRejectedEntriesListLength,
    Pointer<UnsignedChar> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.wrapAsyncUpsertEntriesCallback(
      FindexRedisImplementation.upsertEntries,
      outputRejectedEntriesListPointer,
      outputRejectedEntriesListLength,
      entriesListPointer,
      entriesListLength,
    );
  }

  static int upsertChainsCallback(
    Pointer<UnsignedChar> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.wrapAsyncInsertChainsCallback(
      FindexRedisImplementation.upsertChains,
      chainsListPointer,
      chainsListLength,
    );
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
