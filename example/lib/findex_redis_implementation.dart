import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:cloudproof_demo/users.dart';
import 'package:redis/redis.dart';

import 'cover_crypt_helper.dart';

const redisHost = "192.168.1.95";
const redisPort = 6379;

class FindexRedisImplementation {
  static Future<void> init(CoverCryptHelper coverCryptHelper) async {
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

    for (final user in Users.getUsers()) {
      final userBytes =
          Uint8List.fromList(utf8.encode(jsonEncode(user.toString())));
      final ciphertext = CoverCrypt.encrypt(
          coverCryptHelper.policy,
          coverCryptHelper.masterKeys.publicKey,
          "Department::MKG && Security Level::Top Secret",
          userBytes);

      await FindexRedisImplementation.set(
          db, RedisTable.users, Uint8List.fromList([user.id]), ciphertext);
    }
  }

  static Future<Command> get db async {
    final conn = RedisConnection();
    return await conn.connect(redisHost, redisPort);
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
      Command db, RedisTable table, UpsertData entries) async {
    //TODO: implement bulk insert if required
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
      Command db, RedisTable table, List<UidAndValue> entries) async {
    await execute(db, [
      "MSET",
      ...entries.expand(
          (entry) => [RedisBulk(key(table, entry.uid)), RedisBulk(entry.value)])
    ]);
  }

  static Future<Set<Keyword>> indexAll(
      FindexKey findexKey, Uint8List label) async {
    final additions = {
      for (final user in Users.getUsers())
        IndexedValue.fromLocation(user.location): user.indexedWords,
    };

    return upsert(findexKey, label, additions, {});
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
    //TODO: implement findex multithreaded support if required
    return await mset(await db, RedisTable.entries, entries);
  }

  static Future<void> upsertChains(List<UidAndValue> chains) async {
    await mset2(await db, RedisTable.chains, chains);
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<Map<Keyword, Set<Location>>> search(Uint8List findexKey,
      Uint8List label, Set<Keyword> words, //TODO: replace all keyK by findexKey
      {int entryTableNumber = 1}) async {
    return await Findex.search(
        findexKey,
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

  static Future<Set<Keyword>> upsert(
    FindexKey findexKey,
    Uint8List label,
    Map<IndexedValue, Set<Keyword>> additions,
    Map<IndexedValue, Set<Keyword>> deletions,
  ) async {
    return Findex.upsert(
      findexKey,
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

  static int upsertChainsCallback(
    Pointer<Uint8> chainsListPointer,
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
