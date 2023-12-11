import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redis/redis.dart';
import 'package:tuple/tuple.dart';

import 'user.dart';

class RedisMultiEntryTables {
  static const String throwInsideFetchFilepath = "/tmp/redisThrowInsideFetch";

  static Future<bool> shouldThrowInsideFetch() async {
    return await File(RedisMultiEntryTables.throwInsideFetchFilepath).exists();
  }

  static Future<void> setThrowInsideFetch() async {
    await File(RedisMultiEntryTables.throwInsideFetchFilepath).create();
  }

  static Future<void> resetThrowInsideFetch() async {
    await File(RedisMultiEntryTables.throwInsideFetchFilepath).delete();
  }

  static Future<Tuple3> init(Uint8List key, String label) async {
    final db = await RedisMultiEntryTables.db;

    for (final userKey in await RedisMultiEntryTables.keys(RedisTables.users)) {
      await RedisMultiEntryTables.del(db, userKey);
    }

    for (final entryKey
        in await RedisMultiEntryTables.keys(RedisTables.entries_1)) {
      await RedisMultiEntryTables.del(db, entryKey);
    }
    for (final entryKey
        in await RedisMultiEntryTables.keys(RedisTables.entries_2)) {
      await RedisMultiEntryTables.del(db, entryKey);
    }

    for (final chainKey
        in await RedisMultiEntryTables.keys(RedisTables.chains_1)) {
      await RedisMultiEntryTables.del(db, chainKey);
    }
    for (final chainKey
        in await RedisMultiEntryTables.keys(RedisTables.chains_2)) {
      await RedisMultiEntryTables.del(db, chainKey);
    }

    final users = jsonDecode(
        await File('test/resources/findex/users.json').readAsString());

    for (final user in users) {
      await RedisMultiEntryTables.set(
          db,
          RedisTables.users,
          Uint8List.fromList([0, 0, 0, user['id']]),
          Uint8List.fromList(utf8.encode(jsonEncode(user))));
    }
    return RedisMultiEntryTables.instantiateFindex(key, label);
  }

  static Tuple3 instantiateFindex(Uint8List key, String label) {
    int findexHandle1 = Findex.instantiateFindex(
        key,
        label,
        Pointer.fromFunction(
          fetchEntriesCallbackDb1,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          fetchChainsCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          upsertEntriesCallbackDb1,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          insertEntriesCallbackDb1,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          insertChainsCallbackDb1,
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

    int findexHandle2 = Findex.instantiateFindex(
        key,
        label,
        Pointer.fromFunction(
          fetchEntriesCallbackDb2,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          fetchChainsCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          upsertEntriesCallbackDb2,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          insertEntriesCallbackDb2,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          insertChainsCallbackDb2,
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
    int findexHandle3 = Findex.instantiateFindex(
        key,
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
        ),
        entryTableNumber: 2);
    return Tuple3(findexHandle1, findexHandle2, findexHandle3);
  }

  static Future<Command> get db async {
    final conn = RedisConnection();
    return await conn.connect('localhost', 6379);
  }

  static Future<dynamic> execute(Command db, List<dynamic> params) async {
    Command binaryCommand = Command.from(db).setParser(RedisParserBulkBinary());
    return await binaryCommand.send_object(params);
  }

  static Uint8List key(RedisTables table, Uint8List key) {
    return Uint8List.fromList(const Utf8Encoder().convert("cosmian") +
        Uint8List.fromList([0, 0, 0, table.number] + key));
  }

  static Future<void> del(Command db, Uint8List keyWithPrefix) async {
    await execute(db, ["DEL", RedisBulk(keyWithPrefix)]);
  }

  static Future<dynamic> get(
      Command db, RedisTables table, Uint8List key) async {
    return await getWithoutPrefix(db, RedisMultiEntryTables.key(table, key));
  }

  static Future<List<dynamic>> mget(
      Command db, RedisTables table, List<Uint8List> keys) async {
    return await mgetWithoutPrefix(
        db, keys.map((key) => RedisMultiEntryTables.key(table, key)).toList());
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
      Command db, RedisTables table, Uint8List key, Uint8List value) async {
    await execute(db, [
      "SET",
      RedisBulk(RedisMultiEntryTables.key(table, key)),
      RedisBulk(value)
    ]);
  }

  static Future<List<UidAndValue>> mset(
      Command db, RedisTables table, UpsertData entries) async {
    log("mset: map length: ${entries.map.length}");
    for (final entry in entries.map.entries) {
      set(db, table, entry.key, entry.value.item2);
      log("entry.key: ${entry.key}");
      log("entry.value.item1: ${entry.value.item1}");
      log("entry.value.item2: ${entry.value.item2}");
    }
    log("mset: exiting after execute");
    return [];
  }

  static Future<void> mset2(
      Command db, RedisTables table, List<UidAndValue> entries) async {
    await execute(db, [
      "MSET",
      ...entries.expand(
          (entry) => [RedisBulk(key(table, entry.uid)), RedisBulk(entry.value)])
    ]);
  }

  static Future<List<Uint8List>> keys(RedisTables table) async {
    return (await execute(await db, [
      "KEYS",
      RedisBulk(key(table, Uint8List(0)) + utf8.encode("*"))
    ]) as List)
        .map((e) => Uint8List.fromList(e))
        .toList();
  }

  static Future<int> count(RedisTables table) async {
    return (await keys(table)).length;
  }

  static Future<List<User>> allUsers() async {
    final db = await RedisMultiEntryTables.db;

    final users = await mgetWithoutPrefix(db, await keys(RedisTables.users));

    return users.map((userBytes) {
      final userJson = utf8.decode(userBytes);
      return User.fromMap(jsonDecode(userJson));
    }).toList();
  }

  static Future<List<UidAndValue>> fetchEntriesOrChains(
      RedisTables table, Uids uids) async {
    List<UidAndValue> results = [];

    final db = await RedisMultiEntryTables.db;

    if (await RedisMultiEntryTables.shouldThrowInsideFetch()) {
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
    log("multi redis: fetchEntries");
    final list1 = await fetchEntriesOrChains(RedisTables.entries_1, uids);
    final list2 = await fetchEntriesOrChains(RedisTables.entries_2, uids);

    log("multi redis: fetchEntries: list1: $list1");
    for (final entry in list1) {
      log("multi redis: fetchEntries: list1: $entry");
    }
    log("multi redis: fetchEntries: list2: $list2");
    list1.addAll(list2);
    log("multi redis: fetchEntries: final list: $list1");

    return list1;
  }

  static Future<List<UidAndValue>> fetchEntriesDb1(Uids uids) async {
    return await fetchEntriesOrChains(RedisTables.entries_1, uids);
  }

  static Future<List<UidAndValue>> fetchEntriesDb2(Uids uids) async {
    return await fetchEntriesOrChains(RedisTables.entries_2, uids);
  }

  static Future<List<UidAndValue>> fetchChains(Uids uids) async {
    final list1 = await fetchEntriesOrChains(RedisTables.chains_1, uids);
    final list2 = await fetchEntriesOrChains(RedisTables.chains_2, uids);

    list1.addAll(list2);
    return list1;
  }

  static Future<List<UidAndValue>> fetchChainsDb1(Uids uids) async {
    return await fetchEntriesOrChains(RedisTables.chains_1, uids);
  }

  static Future<List<UidAndValue>> fetchChainsDb2(Uids uids) async {
    return await fetchEntriesOrChains(RedisTables.chains_2, uids);
  }

  static Future<List<UidAndValue>> upsertEntries_1(UpsertData entries) async {
    return await mset(await db, RedisTables.entries_1, entries);
  }

  static Future<List<UidAndValue>> upsertEntries_2(UpsertData entries) async {
    return await mset(await db, RedisTables.entries_2, entries);
  }

  static Future<void> insertEntries_1(List<UidAndValue> entries) async {
    await mset2(await db, RedisTables.entries_1, entries);
  }

  static Future<void> insertEntries_2(List<UidAndValue> entries) async {
    await mset2(await db, RedisTables.entries_2, entries);
  }

  static Future<void> insertChains_1(List<UidAndValue> chains) async {
    await mset2(await db, RedisTables.chains_1, chains);
  }

  static Future<void> insertChains_2(List<UidAndValue> chains) async {
    await mset2(await db, RedisTables.chains_2, chains);
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<Map<Keyword, Set<Location>>> search(Set<Keyword> keywords,
      {int findexHandle = -1}) async {
    return await Findex.search(keywords, findexHandle: findexHandle);
  }

  static Future<Set<Keyword>> upsert_1(
      Map<IndexedValue, Set<Keyword>> additions, int handle) async {
    log("upsert_1: handle: $handle");
    return Findex.add(additions, findexHandle: handle);
  }

  static Future<Set<Keyword>> upsert_2(
      Map<IndexedValue, Set<Keyword>> additions, int handle) async {
    return Findex.add(additions, findexHandle: handle);
  }

  static int fetchEntriesCallback(
    Pointer<Uint8> outputEntryTableLinesPointer,
    Pointer<Uint32> outputEntryTableLinesLength,
    Pointer<Uint8> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapAsyncFetchCallback(
      RedisMultiEntryTables.fetchEntries,
      outputEntryTableLinesPointer,
      outputEntryTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }

  static int fetchEntriesCallbackDb1(
    Pointer<Uint8> outputEntryTableLinesPointer,
    Pointer<Uint32> outputEntryTableLinesLength,
    Pointer<Uint8> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapAsyncFetchCallback(
      RedisMultiEntryTables.fetchEntriesDb1,
      outputEntryTableLinesPointer,
      outputEntryTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }

  static int fetchEntriesCallbackDb2(
    Pointer<Uint8> outputEntryTableLinesPointer,
    Pointer<Uint32> outputEntryTableLinesLength,
    Pointer<Uint8> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapAsyncFetchCallback(
      RedisMultiEntryTables.fetchEntriesDb2,
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
      RedisMultiEntryTables.fetchChains,
      outputChainTableLinesPointer,
      outputChainTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }

  static int upsertEntriesCallbackDb1(
    Pointer<Uint8> outputRejectedEntriesListPointer,
    Pointer<Uint32> outputRejectedEntriesListLength,
    Pointer<Uint8> oldValuesPointer,
    int oldValuesLength,
    Pointer<Uint8> newValuesPointer,
    int newValuesLength,
  ) {
    return Findex.wrapAsyncUpsertEntriesCallback(
      RedisMultiEntryTables.upsertEntries_1,
      outputRejectedEntriesListPointer,
      outputRejectedEntriesListLength,
      oldValuesPointer,
      oldValuesLength,
      newValuesPointer,
      newValuesLength,
    );
  }

  static int upsertEntriesCallbackDb2(
    Pointer<Uint8> outputRejectedEntriesListPointer,
    Pointer<Uint32> outputRejectedEntriesListLength,
    Pointer<Uint8> oldValuesPointer,
    int oldValuesLength,
    Pointer<Uint8> newValuesPointer,
    int newValuesLength,
  ) {
    return Findex.wrapAsyncUpsertEntriesCallback(
      RedisMultiEntryTables.upsertEntries_2,
      outputRejectedEntriesListPointer,
      outputRejectedEntriesListLength,
      oldValuesPointer,
      oldValuesLength,
      newValuesPointer,
      newValuesLength,
    );
  }

  static int insertEntriesCallbackDb1(
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.wrapAsyncInsertEntriesCallback(
      RedisMultiEntryTables.insertEntries_1,
      entriesListPointer,
      entriesListLength,
    );
  }

  static int insertEntriesCallbackDb2(
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.wrapAsyncInsertEntriesCallback(
      RedisMultiEntryTables.insertEntries_2,
      entriesListPointer,
      entriesListLength,
    );
  }

  static int insertChainsCallbackDb1(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.wrapAsyncInsertChainsCallback(
      RedisMultiEntryTables.insertChains_1,
      chainsListPointer,
      chainsListLength,
    );
  }

  static int insertChainsCallbackDb2(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.wrapAsyncInsertChainsCallback(
      RedisMultiEntryTables.insertChains_2,
      chainsListPointer,
      chainsListLength,
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
    throw FindexException("not implemented");
  }

  static int insertEntriesCallback(
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    throw FindexException("not implemented");
  }

  static int insertChainsCallback(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    throw FindexException("not implemented");
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

enum RedisTables {
  entries_1,
  entries_2,
  chains_1,
  chains_2,
  users,
  others,
}

extension RedisTableExtension on RedisTables {
  int get number {
    switch (this) {
      case RedisTables.entries_1:
        return 100;
      case RedisTables.entries_2:
        return 200;
      case RedisTables.chains_1:
        return 300;
      case RedisTables.chains_2:
        return 400;
      case RedisTables.users:
        return 3;
      case RedisTables.others:
        return 4;
      default:
        throw Exception("Unknown RedisTables $this");
    }
  }
}
