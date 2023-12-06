// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tuple/tuple.dart';

import 'user.dart';

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

Future<Database> initDb(String filepath) async {
  if (await File(filepath).exists()) {
    await File(filepath).delete();
  }
  final db = sqlite3.open(filepath);

  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id integer PRIMARY KEY,
      firstName text NOT NULL,
      lastName text NOT NULL,
      email text NOT NULL,
      phone text NOT NULL,
      country text NOT NULL,
      region text NOT NULL,
      employeeNumber text NOT NULL,
      security text NOT NULL
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS entry_table (uid BLOB PRIMARY KEY,value BLOB NOT NULL)
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS chain_table (uid BLOB PRIMARY KEY,value BLOB NOT NULL)
  ''');

  final users =
      jsonDecode(await File('test/resources/findex/users.json').readAsString());

  final stmt = db.prepare(
      'INSERT INTO users (id, firstName, lastName, phone, email, country, region, employeeNumber, security) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
  for (final user in users) {
    stmt.execute([
      user['id'],
      user['firstName'],
      user['lastName'],
      user['phone'],
      user['email'],
      user['country'],
      user['region'],
      user['employeeNumber'],
      user['security'],
    ]);
  }

  return db;
}

// Sqlite test class: everything is static du to Pointer.fromFunction
class SqliteFindex {
  static Database? singletonDb;
  static bool throwInsideFetchEntries = false;
  static bool returnOnlyUidInsideFetchEntries = false;
  static bool returnOnlyValueInsideFetchEntries = false;
  static bool returnOnlyUidInsideFetchChains = false;
  static bool returnOnlyValueInsideFetchChains = false;
  static int findexHandle = 0;

  static Tuple2<Database, int> init(
      String filepath, FindexKey findexKey, String label) {
    final newDb = sqlite3.open(filepath);
    singletonDb = newDb;
    findexHandle = instantiateFindex(findexKey, label);
    return Tuple2(newDb, findexHandle);
  }

  static int instantiateFindex(FindexKey findexKey, String label) {
    findexHandle = Findex.instantiateFindex(
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
    log("instantiateFindex: findexHandle: $findexHandle");
    return findexHandle;
  }

  static Database get db {
    if (singletonDb != null) {
      return singletonDb as Database;
    }
    throw Exception("Database not initialized");
  }

  static Future<Set<Keyword>> indexAll() async {
    final users = allUsers();

    final indexedValuesAndKeywords = {
      for (final user in users)
        IndexedValue.fromLocation(user.location): user.indexedWords,
    };

    return add(indexedValuesAndKeywords);
  }

  static Future<void> indexAllFromFile(String usersFilepath) async {
    final users = jsonDecode(await File(usersFilepath).readAsString());

    final indexedValuesAndKeywords = {
      for (final user in users)
        IndexedValue.fromLocation(Location.fromNumber(user['id'])): {
          Keyword.fromString(user['firstName']),
          Keyword.fromString(user['lastName']),
          Keyword.fromString(user['phone']),
          Keyword.fromString(user['email']),
          Keyword.fromString(user['country']),
          Keyword.fromString(user['region']),
          Keyword.fromString(user['employeeNumber']),
          Keyword.fromString(user['security'])
        },
    };

    await add(indexedValuesAndKeywords);
  }

  static List<User> allUsers() {
    final ResultSet resultSet = db.select('SELECT * FROM users');
    List<User> users = [];

    for (final Row row in resultSet) {
      users.add(User.fromMap(row));
    }

    return users;
  }

  static int count(String table) {
    final ResultSet resultSet = db.select('SELECT COUNT(*) FROM $table');
    return int.parse(resultSet.first.values.first.toString());
  }

  static void reinsert(String table) async {
    final ResultSet resultSet = db.select('SELECT * FROM $table');
    for (final Row row in resultSet) {
      log(row['uid']);
      log(row['value']);

      final stmt =
          db.prepare('INSERT INTO entry_table (uid, value) VALUES (?, ?)');
      stmt.execute([
        row['uid'],
        row['value'],
      ]);
      break;
    }
  }

  static List<UidAndValue> fetchEntries(Uids uids) {
    log("fetchEntries: entering");

    if (SqliteFindex.throwInsideFetchEntries) {
      log("fetchEntries: throwing fake exception");
      throw UnsupportedError("Some message"); // :ExceptionLine
    }

    if (uids.uids.isEmpty) {
      return [];
    }
    log("fetchEntries: preparing questions: uids number: ${uids.uids.length}");

    var questions = ("?," * uids.uids.length);
    questions = questions.substring(0, questions.length - 1);

    log("fetchEntries: preparing fetch request");
    final ResultSet resultSet = db.select(
        'SELECT * FROM entry_table WHERE uid IN ($questions)', uids.uids);
    log("fetchEntries: executed!");

    List<UidAndValue> entries = [];
    for (final Row row in resultSet) {
      if (SqliteFindex.returnOnlyUidInsideFetchEntries) {
        entries.add(UidAndValue(row['uid'], row['uid']));
      } else if (SqliteFindex.returnOnlyValueInsideFetchEntries) {
        entries.add(UidAndValue(row['value'], row['value']));
      } else {
        entries.add(UidAndValue(row['uid'], row['value']));
      }
    }

    log("fetchEntries: exiting");
    return entries;
  }

  static List<UidAndValue> fetchChains(Uids uids) {
    var questions = ("?," * uids.uids.length);
    questions = questions.substring(0, questions.length - 1);
    final ResultSet resultSet = db.select(
        'SELECT * FROM chain_table WHERE uid IN ($questions)', uids.uids);

    List<UidAndValue> entries = [];
    for (final Row row in resultSet) {
      if (SqliteFindex.returnOnlyUidInsideFetchChains) {
        entries.add(UidAndValue(row['uid'], row['uid']));
      } else if (SqliteFindex.returnOnlyValueInsideFetchChains) {
        entries.add(UidAndValue(row['value'], row['value']));
      } else {
        entries.add(UidAndValue(row['uid'], row['value']));
      }
    }

    return entries;
  }

  static List<UidAndValue> upsertEntries(UpsertData entries) {
    List<UidAndValue> rejectedEntries = [];
    log("[sqlite]: upsertEntries: entering");
    final stmt = db.prepare(
        'INSERT INTO entry_table (uid, value) VALUES (?, ?) ON CONFLICT (uid) DO UPDATE SET value = ? WHERE value = ?');
    for (final entry in entries.map.entries) {
      stmt.execute([
        entry.key,
        entry.value.item2,
        entry.value.item2,
        entry.value.item1,
      ]);
      log("[sqlite]: upsertEntries: executed!");
      log("[sqlite]: upsertEntries: entry.key: ${entry.key}");
      log("[sqlite]: upsertEntries: entry.value.item1: ${entry.value.item1}");
      log("[sqlite]: upsertEntries: entry.value.item2: ${entry.value.item2}");

      if (db.getUpdatedRows() == 0) {
        log("[sqlite]: upsertEntries: 0 updated row!");
        try {
          log("[sqlite]: upsertEntries: prepare select");
          final ResultSet resultSet = db
              .select('SELECT value FROM entry_table WHERE uid=?', [entry.key]);
          if (resultSet.length != 1) {
            final errorMsg =
                "1 entry is expected, found ${resultSet.length} entries";
            log("[sqlite]: errorMsg: $errorMsg");
            throw Exception(errorMsg);
          }
          final Row row = resultSet[0];
          rejectedEntries.add(UidAndValue(entry.key, row['value']));
          log("[sqlite]: upsertEntries: rejectedEntries: ${rejectedEntries.length}");
        } catch (e) {
          rethrow;
        }
      }
    }

    log("[sqlite]: upsertEntries: exiting with ${rejectedEntries.length} entries");
    return rejectedEntries;
  }

  static void insertEntries(List<UidAndValue> entries) {
    final stmt = db.prepare(
        'INSERT OR REPLACE INTO entry_table (uid, value) VALUES (?, ?)');
    for (final entry in entries) {
      stmt.execute([
        entry.uid,
        entry.value,
      ]);
    }
  }

  static void insertChains(List<UidAndValue> chains) {
    final stmt = db.prepare(
        'INSERT OR REPLACE INTO chain_table (uid, value) VALUES (?, ?)');
    for (final chain in chains) {
      stmt.execute([
        chain.uid,
        chain.value,
      ]);
    }
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<Map<Keyword, Set<Location>>> search(Set<Keyword> keywords,
      {int findexHandle = -1}) async {
    return await Findex.search(keywords, findexHandle: findexHandle);
  }

  static int fetchEntriesCallback(
    Pointer<Uint8> outputEntryTableLinesPointer,
    Pointer<Uint32> outputEntryTableLinesLength,
    Pointer<Uint8> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapSyncFetchCallback(
      SqliteFindex.fetchEntries,
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
    return Findex.wrapSyncFetchCallback(
      SqliteFindex.fetchChains,
      outputChainTableLinesPointer,
      outputChainTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }

  static Future<Set<Keyword>> add(Map<IndexedValue, Set<Keyword>> additions,
      {int findexHandle = -1}) async {
    log("add: handle: $findexHandle");
    return Findex.add(additions, findexHandle: findexHandle);
  }

  static int upsertEntriesCallback(
    Pointer<Uint8> outputRejectedEntriesListPointer,
    Pointer<Uint32> outputRejectedEntriesListLength,
    Pointer<Uint8> oldValuesPointer,
    int oldValuesLength,
    Pointer<Uint8> newValuesPointer,
    int newValuesLength,
  ) {
    return Findex.wrapSyncUpsertEntriesCallback(
      SqliteFindex.upsertEntries,
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
    return Findex.wrapSyncInsertEntriesCallback(
      SqliteFindex.insertEntries,
      entriesListPointer,
      entriesListLength,
    );
  }

  static int insertChainsCallback(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.wrapSyncInsertChainsCallback(
      SqliteFindex.insertChains,
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

  static Future<void> verify(String dbPath) async {
    final findexKey = FindexKey.fromJson(jsonDecode(
        await File('test/resources/findex/master_key.json').readAsString()));

    init(dbPath, findexKey, "Some Label");

    expect(SqliteFindex.count('entry_table'), greaterThan(0));
    expect(SqliteFindex.count('chain_table'), greaterThan(0));

    {
      final searchResults = await search({Keyword.fromString("France")});
      expect(searchResults.length, equals(1));

      final keyword = searchResults.entries.toList()[0].key;
      final indexedValues = searchResults.entries.toList()[0].value;
      final usersIds = indexedValues.map((location) {
        return location.number;
      }).toList();
      usersIds.sort();

      expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
      expect(usersIds.length, expectedUsersIdsForFrance.length);
    }

    await indexAllFromFile('test/resources/findex/single_user.json');

    {
      final searchResults = await search({Keyword.fromString("France")});

      expect(searchResults.length, 1);

      final keyword = searchResults.entries.toList()[0].key;
      final indexedValues = searchResults.entries.toList()[0].value;
      final usersIds = indexedValues.map((location) {
        return location.number;
      }).toList();
      usersIds.sort();

      expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
      expect(usersIds.length, expectedUsersIdsForFrance.length + 1);
    }
  }
}
