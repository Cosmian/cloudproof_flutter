import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:cloudproof_demo/users.dart';
import 'package:ffi/ffi.dart';
import 'package:redis/redis.dart';
import 'package:tuple/tuple.dart';

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
    final indexedValuesAndWords = {
      for (final user in Users.getUsers())
        IndexedValue.fromLocation(user.location): user.indexedWords,
    };

    await upsert(masterKey, label, indexedValuesAndWords);
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

  static Future<List<IndexedValue>> search(
    Uint8List keyK,
    Uint8List label,
    List<Keyword> words,
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
    FindexMasterKey masterKey,
    Uint8List label,
    Map<IndexedValue, List<Keyword>> indexedValuesAndKeywords,
  ) async {
    await Findex.upsert(
      masterKey,
      label,
      indexedValuesAndKeywords,
      Pointer.fromFunction(
        fetchEntriesCallback,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        upsertEntriesCallback,
      ),
      Pointer.fromFunction(
        upsertChainsCallback,
      ),
    );
  }

  static int fetchEntriesCallback(
    Pointer<Char> outputEntryTableLinesPointer,
    Pointer<UnsignedInt> outputEntryTableLinesLength,
    Pointer<UnsignedChar> uidsPointer,
    int uidsNumber,
  ) {
    final donePointer = calloc<Bool>(1);
    donePointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            final inputArray = Pointer<Uint8>.fromAddress(message.item3)
                .asTypedList(uidsNumber);

            final uids = Uids.deserialize(inputArray);
            final entryTableLines =
                await FindexRedisImplementation.fetchEntries(uids);

            UidAndValue.serialize(
                Pointer<UnsignedChar>.fromAddress(message.item1),
                Pointer<UnsignedInt>.fromAddress(message.item2),
                entryTableLines);
          } catch (e) {
            log("Excepting in fetch isolate. $e");
          } finally {
            Pointer<Bool>.fromAddress(message.item4).value = true;
          }
        },
        Tuple4(
          outputEntryTableLinesPointer.address,
          outputEntryTableLinesLength.address,
          uidsPointer.address,
          donePointer.address,
        ),
      );
      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }
      return 0;
    } catch (e, stacktrace) {
      log("Exception during fetchEntriesCallback $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
    }
  }

  static int fetchChainsCallback(
    Pointer<Char> outputChainTableLinesPointer,
    Pointer<UnsignedInt> outputChainTableLinesLength,
    Pointer<UnsignedChar> uidsPointer,
    int uidsNumber,
  ) {
    final donePointer = calloc<Bool>(1);
    donePointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            final inputArray = Pointer<Uint8>.fromAddress(message.item3)
                .asTypedList(uidsNumber);

            final uids = Uids.deserialize(inputArray);
            final chainTableLines =
                await FindexRedisImplementation.fetchChains(uids);
            UidAndValue.serialize(
                Pointer<UnsignedChar>.fromAddress(message.item1),
                Pointer<UnsignedInt>.fromAddress(message.item2),
                chainTableLines);
          } catch (e) {
            log("Excepting in fetch isolate. $e");
          } finally {
            Pointer<Bool>.fromAddress(message.item4).value = true;
          }
        },
        Tuple4(
          outputChainTableLinesPointer.address,
          outputChainTableLinesLength.address,
          uidsPointer.address,
          donePointer.address,
        ),
      );
      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }

      return 0;
    } catch (e, stacktrace) {
      log("Exception during fetchChainsCallback $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
    }
  }

  static void upsertEntriesCallback(
    Pointer<UnsignedChar> entriesListPointer,
    int entriesListLength,
    Pointer<UnsignedChar> outputRejectedEntriesListPointer,
    Pointer<UnsignedInt> outputRejectedEntriesListLength,
  ) {
    final donePointer = calloc<Bool>(1);
    donePointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            final inputArray = Pointer<Uint8>.fromAddress(message.item1)
                .asTypedList(entriesListLength);

            final uidsAndValues = UpsertData.deserialize(inputArray);

            final rejectedEntries =
                await FindexRedisImplementation.upsertEntries(uidsAndValues);

            UidAndValue.serialize(
                Pointer<UnsignedChar>.fromAddress(message.item4),
                Pointer<UnsignedInt>.fromAddress(message.item3),
                rejectedEntries);
          } catch (e) {
            log("Excepting in upsert isolate. $e");
          } finally {
            Pointer<Bool>.fromAddress(message.item4).value = true;
          }
        },
        Tuple4(
          entriesListPointer.address,
          outputRejectedEntriesListPointer.address,
          outputRejectedEntriesListLength.address,
          donePointer.address,
        ),
      );

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }
    } catch (e, stacktrace) {
      log("Exception during upsertEntriesCallback $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
    }
  }

  static void upsertChainsCallback(
    Pointer<UnsignedChar> chainsListPointer,
    int chainsListLength,
  ) {
    final donePointer = calloc<Bool>(1);
    donePointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            final inputArray = Pointer<Uint8>.fromAddress(message.item1)
                .asTypedList(chainsListLength);

            final uidsAndValues = UidAndValue.deserialize(inputArray);
            log("upsertWrapperWithoutIsolate: uidsAndValues: $uidsAndValues");

            FindexRedisImplementation.upsertChains(uidsAndValues);
          } catch (e) {
            log("Excepting in upsert isolate. $e");
          } finally {
            Pointer<Bool>.fromAddress(message.item2).value = true;
          }
        },
        Tuple2(
          chainsListPointer.address,
          donePointer.address,
        ),
      );

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }
    } catch (e, stacktrace) {
      log("Exception during upsertChainsCallback $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
    }
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
