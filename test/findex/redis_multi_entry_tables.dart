import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:redis/redis.dart';

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

  static Future<void> init() async {
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
      Command db, RedisTables table, List<UpsertData> entries) async {
    await execute(db, [
      "MSET",
      ...entries.expand((entry) =>
          [RedisBulk(key(table, entry.uid)), RedisBulk(entry.newValue)])
    ]);
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
    final list1 = await fetchEntriesOrChains(RedisTables.entries_1, uids);
    final list2 = await fetchEntriesOrChains(RedisTables.entries_2, uids);

    list1.addAll(list2);
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

  static Future<List<UidAndValue>> upsertEntries_1(
      List<UpsertData> entries) async {
    return await mset(await db, RedisTables.entries_1, entries);
  }

  static Future<List<UidAndValue>> upsertEntries_2(
      List<UpsertData> entries) async {
    return await mset(await db, RedisTables.entries_2, entries);
  }

  static Future<void> upsertChains_1(List<UidAndValue> chains) async {
    await mset2(await db, RedisTables.chains_1, chains);
  }

  static Future<void> upsertChains_2(List<UidAndValue> chains) async {
    await mset2(await db, RedisTables.chains_2, chains);
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

  static Future<Set<Keyword>> upsert_1(
    FindexMasterKey masterKey,
    Uint8List label,
    Map<IndexedValue, List<Keyword>> additions,
    Map<IndexedValue, List<Keyword>> deletions,
  ) async {
    return Findex.upsert(
      masterKey,
      label,
      additions,
      deletions,
      Pointer.fromFunction(
        fetchEntriesCallbackDb1,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        upsertEntriesCallbackDb1,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        upsertChainsCallbackDb1,
        errorCodeInCaseOfCallbackException,
      ),
    );
  }

  static Future<Set<Keyword>> upsert_2(
    FindexMasterKey masterKey,
    Uint8List label,
    Map<IndexedValue, List<Keyword>> additions,
    Map<IndexedValue, List<Keyword>> deletions,
  ) async {
    return Findex.upsert(
      masterKey,
      label,
      additions,
      deletions,
      Pointer.fromFunction(
        fetchEntriesCallbackDb2,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        upsertEntriesCallbackDb2,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        upsertChainsCallbackDb2,
        errorCodeInCaseOfCallbackException,
      ),
    );
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
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.wrapAsyncUpsertEntriesCallback(
      RedisMultiEntryTables.upsertEntries_1,
      outputRejectedEntriesListPointer,
      outputRejectedEntriesListLength,
      entriesListPointer,
      entriesListLength,
    );
  }

  static int upsertEntriesCallbackDb2(
    Pointer<Uint8> outputRejectedEntriesListPointer,
    Pointer<Uint32> outputRejectedEntriesListLength,
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.wrapAsyncUpsertEntriesCallback(
      RedisMultiEntryTables.upsertEntries_2,
      outputRejectedEntriesListPointer,
      outputRejectedEntriesListLength,
      entriesListPointer,
      entriesListLength,
    );
  }

  static int upsertChainsCallbackDb1(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.wrapAsyncInsertChainsCallback(
      RedisMultiEntryTables.upsertChains_1,
      chainsListPointer,
      chainsListLength,
    );
  }

  static int upsertChainsCallbackDb2(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.wrapAsyncInsertChainsCallback(
      RedisMultiEntryTables.upsertChains_2,
      chainsListPointer,
      chainsListLength,
    );
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
