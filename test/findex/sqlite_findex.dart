// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

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

// Class used to test multiple Entry Table behind Findex
class SqliteFindexMultiEntryTables {
  static List<String>? dbs;

  static void init(List<String> dbsArg) {
    dbs = dbsArg;
  }

  static List<String> get getDbs {
    if (dbs != null) {
      return dbs as List<String>;
    }
    throw Exception("Database not initialized");
  }

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

  // only concat the results of fetching in both databases
  static List<UidAndValue> fetchEntries(Uids uids) {
    List<UidAndValue> output = [];
    for (String filepath in getDbs) {
      SqliteFindex.init(filepath);
      List<UidAndValue> results = SqliteFindex.fetchEntries(uids);
      output.addAll(results);
    }
    return output;
  }

  // only concat the results of fetching in both databases
  static List<UidAndValue> fetchChains(Uids uids) {
    List<UidAndValue> output = [];
    for (String filepath in getDbs) {
      SqliteFindex.init(filepath);
      List<UidAndValue> results = SqliteFindex.fetchChains(uids);
      output.addAll(results);
    }
    return output;
  }

  static int fetchEntriesCallback(
    Pointer<Uint8> outputEntryTableLinesPointer,
    Pointer<Uint32> outputEntryTableLinesLength,
    Pointer<Uint8> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapSyncFetchCallback(
      SqliteFindexMultiEntryTables.fetchEntries,
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
      SqliteFindexMultiEntryTables.fetchChains,
      outputChainTableLinesPointer,
      outputChainTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }
}

// Sqlite test class: everything is static du to Pointer.fromFunction
class SqliteFindex {
  static Database? singletonDb;
  static bool throwInsideFetchEntries = false;
  static bool returnOnlyUidInsideFetchEntries = false;
  static bool returnOnlyValueInsideFetchEntries = false;
  static bool returnOnlyUidInsideFetchChains = false;
  static bool returnOnlyValueInsideFetchChains = false;

  static Database init(String filepath) {
    final newDb = sqlite3.open(filepath);
    singletonDb = newDb;
    return newDb;
  }

  static Database get db {
    if (singletonDb != null) {
      return singletonDb as Database;
    }
    throw Exception("Database not initialized");
  }

  static Future<void> indexAll(
      FindexMasterKey masterKey, Uint8List label) async {
    final users = allUsers();

    final indexedValuesAndKeywords = {
      for (final user in users)
        IndexedValue.fromLocation(user.location): user.indexedWords,
    };

    await upsert(masterKey, label, indexedValuesAndKeywords, {});
  }

  static Future<void> indexAllFromFile(
      String usersFilepath, FindexMasterKey masterKey, Uint8List label) async {
    final users = jsonDecode(await File(usersFilepath).readAsString());

    final indexedValuesAndKeywords = {
      for (final user in users)
        IndexedValue.fromLocation(Location.fromNumber(user['id'])): [
          Keyword.fromString(user['firstName']),
          Keyword.fromString(user['lastName']),
          Keyword.fromString(user['phone']),
          Keyword.fromString(user['email']),
          Keyword.fromString(user['country']),
          Keyword.fromString(user['region']),
          Keyword.fromString(user['employeeNumber']),
          Keyword.fromString(user['security'])
        ],
    };

    await upsert(masterKey, label, indexedValuesAndKeywords, {});
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
      print(row['uid']);
      print(row['value']);

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
    if (SqliteFindex.throwInsideFetchEntries) {
      throw UnsupportedError("Some message"); // :ExceptionLine
    }

    var questions = ("?," * uids.uids.length);
    questions = questions.substring(0, questions.length - 1);

    final ResultSet resultSet = db.select(
        'SELECT * FROM entry_table WHERE uid IN ($questions)', uids.uids);

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

  static void upsertEntry(UpsertData entry) {
    final stmt = db.prepare(
        'INSERT OR REPLACE INTO entry_table (uid, value) VALUES (?, ?)');
    stmt.execute([
      entry.uid,
      entry.newValue,
    ]);
  }

  static List<UidAndValue> upsertEntries(List<UpsertData> entries) {
    List<UidAndValue> rejectedEntries = [];
    final stmt = db.prepare(
        'INSERT INTO entry_table (uid, value) VALUES (?, ?) ON CONFLICT (uid)  DO UPDATE SET value = ? WHERE value = ?');
    for (final entry in entries) {
      stmt.execute([
        entry.uid,
        entry.newValue,
        entry.newValue,
        entry.oldValue,
      ]);

      if (db.getUpdatedRows() == 0) {
        try {
          final ResultSet resultSet = db
              .select('SELECT value FROM entry_table WHERE uid=?', [entry.uid]);
          if (resultSet.length != 1) {
            throw Exception(
                "1 entry is expected, found ${resultSet.length} entries");
          }
          final Row row = resultSet[0];
          rejectedEntries.add(UidAndValue(entry.uid, row['value']));
        } catch (e) {
          rethrow;
        }
      }
    }

    return rejectedEntries;
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
        insertChainsCallback,
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

  static int upsertEntriesCallback(
    Pointer<Uint8> outputRejectedEntriesListPointer,
    Pointer<Uint32> outputRejectedEntriesListLength,
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.wrapSyncUpsertEntriesCallback(
      SqliteFindex.upsertEntries,
      outputRejectedEntriesListPointer,
      outputRejectedEntriesListLength,
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

  static Future<void> verify(String dbPath) async {
    final masterKey = FindexMasterKey.fromJson(jsonDecode(
        await File('test/resources/findex/master_key.json').readAsString()));
    final label = Uint8List.fromList(utf8.encode("Some Label"));

    init(dbPath);

    expect(SqliteFindex.count('entry_table'), greaterThan(0));
    expect(SqliteFindex.count('chain_table'), greaterThan(0));

    {
      final searchResults =
          await search(masterKey.k, label, [Keyword.fromString("France")]);

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

    await indexAllFromFile(
        'test/resources/findex/single_user.json', masterKey, label);

    {
      final searchResults =
          await search(masterKey.k, label, [Keyword.fromString("France")]);

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
