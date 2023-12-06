import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:redis/redis.dart';
import 'package:tuple/tuple.dart';

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

  static Future<void> init(FindexKey findexKey, String label) async {
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
    Findex.instantiateFindex(
        findexKey,
        label,
        Pointer.fromFunction(
          fetchEntriesCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          fetchChainsCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          upsertEntriesCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          insertEntriesCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          insertChainsCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          deleteEntriesCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          deleteChainsCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          dumpTokensCallback,
          errorCodeInCaseOfCallbackException,
        ));
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
    if (keysWithPrefix.isEmpty) {
      return [];
    }
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
      Command db, RedisTable table, UpsertData entries) async {
    if (entries.map.isEmpty) {
      return [];
    }
    log("mset: map length: ${entries.map.length}");
    final msetList = [];
    for (final entry in entries.map.entries) {
      final element = Tuple2(entry.key, entry.value.item2);
      msetList.add(element);
      log("entry.key: ${entry.key}");
      log("entry.value.item1: ${entry.value.item1}");
      log("entry.value.item2: ${entry.value.item2}");
    }
    log("mset: exiting after execute");
    await execute(db, [
      "MSET",
      ...msetList.expand((entry) =>
          [RedisBulk(key(table, entry.item1)), RedisBulk(entry.item2)])
    ]);

    return [];
  }

  static Future<void> msetInsertEntries(
      Command db, RedisTable table, List<UidAndValue> entries) async {
    log("insert: mset2: nb of entries: ${entries.length}");
    if (entries.isEmpty) {
      return;
    }
    await execute(db, [
      "MSET",
      ...entries.expand(
          (entry) => [RedisBulk(key(table, entry.uid)), RedisBulk(entry.value)])
    ]);
  }

  static Future<void> msetInsertChains(
      Command db, RedisTable table, List<UidAndValue> chains) async {
    log("insert: mset2: nb of entries: ${chains.length}");
    if (chains.isEmpty) {
      return;
    }
    await execute(db, [
      "MSET",
      ...chains.expand(
          (entry) => [RedisBulk(key(table, entry.uid)), RedisBulk(entry.value)])
    ]);
  }

  static Future<Set<Keyword>> indexAll() async {
    final users = await allUsers();

    final additions = {
      for (final user in users)
        IndexedValue.fromLocation(user.location): user.indexedWords,
    };

    return add(additions);
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

    if (uids.uids.isEmpty) {
      return [];
    }
    final db = await FindexRedisImplementation.db;
    if (await FindexRedisImplementation.shouldThrowInsideFetch()) {
      log("Redis Should Throw Exception");
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

  static Future<List<UidAndValue>> upsertEntries(UpsertData entries) async {
    log("redis: upserting entries");
    return await mset(await db, RedisTable.entries, entries);
  }

  static Future<void> insertEntries(List<UidAndValue> entries) async {
    await msetInsertEntries(await db, RedisTable.entries, entries);
  }

  static Future<void> insertChains(List<UidAndValue> chains) async {
    await msetInsertChains(await db, RedisTable.chains, chains);
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<Map<Keyword, Set<Location>>> search(
    Set<Keyword> keywords,
  ) async {
    return await Findex.search(keywords);
  }

  static Future<Set<Keyword>> add(
    Map<IndexedValue, Set<Keyword>> additions,
  ) async {
    final results = Findex.add(additions);
    log("[redis]: add: exceptions: ${Findex.exceptions.length}");
    return results;
  }

  static int fetchEntriesCallback(
    Pointer<Uint8> outputEntryTableLinesPointer,
    Pointer<Uint32> outputEntryTableLinesLength,
    Pointer<Uint8> uidsPointer,
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
    Pointer<Uint8> outputChainTableLinesPointer,
    Pointer<Uint32> outputChainTableLinesLength,
    Pointer<Uint8> uidsPointer,
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
    Pointer<Uint8> outputRejectedEntriesListPointer,
    Pointer<Uint32> outputRejectedEntriesListLength,
    Pointer<Uint8> oldValuesPointer,
    int oldValuesLength,
    Pointer<Uint8> newValuesPointer,
    int newValuesLength,
  ) {
    return Findex.wrapAsyncUpsertEntriesCallback(
      FindexRedisImplementation.upsertEntries,
      outputRejectedEntriesListPointer,
      outputRejectedEntriesListLength,
      oldValuesPointer,
      oldValuesLength,
      newValuesPointer,
      newValuesLength,
    );
  }

  static int insertEntriesCallback(
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.wrapAsyncInsertEntriesCallback(
      FindexRedisImplementation.insertEntries,
      entriesListPointer,
      entriesListLength,
    );
  }

  static int insertChainsCallback(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.wrapAsyncInsertChainsCallback(
      FindexRedisImplementation.insertChains,
      chainsListPointer,
      chainsListLength,
    );
  }

  static int deleteEntriesCallback(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    throw FindexException("not implemented");
  }

  static int deleteChainsCallback(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    throw FindexException("not implemented");
  }

  static int dumpTokensCallback(
    Pointer<Uint8> outputTokensPointer,
    Pointer<Uint32> outputTokensLength,
  ) {
    throw FindexException("not implemented");
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
