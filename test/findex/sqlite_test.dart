import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

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
  group('Findex SQLite', () {
    test('search/upsert', () async {
      await initDb();

      final masterKey = FindexMasterKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_keys.json').readAsString()));

      final label = Uint8List.fromList(utf8.encode("Some Label"));

      expect(SqliteFindex.count('entry_table'), equals(0));
      expect(SqliteFindex.count('chain_table'), equals(0));

      await SqliteFindex.indexAll(masterKey, label);

      expect(SqliteFindex.count('entry_table'), equals(583));
      expect(SqliteFindex.count('chain_table'), equals(618));

      log("\n\n\n### Start Searching");
      final indexedValues = await SqliteFindex.search(
          masterKey.k, label, [Keyword.fromString("France")]);

      final usersIds = indexedValues.map((indexedValue) {
        return indexedValue.location.bytes[0];
      }).toList();
      usersIds.sort();

      expect(usersIds, equals(expectedUsersIdsForFrance));
    });
  });
}

String dbPath() {
  return path.join(Directory.systemTemp.path, "findex_tests.database");
}

Future<Database> initDb() async {
  if (await File(dbPath()).exists()) {
    await File(dbPath()).delete();
  }
  final db = sqlite3.open(dbPath());

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

class SqliteFindex {
  static Database? singletonDb;

  static Database get db {
    if (singletonDb != null) {
      return singletonDb as Database;
    }

    final newDb = sqlite3.open(dbPath());
    singletonDb = newDb;
    return newDb;
  }

  static Future<void> indexAll(
      FindexMasterKey masterKey, Uint8List label) async {
    final users = allUsers();

    final indexedValuesAndWords = {
      for (final user in users)
        IndexedValue.fromLocation(user.location): user.indexedWords,
    };

    await upsert(masterKey, label, indexedValuesAndWords);
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

  static List<UidAndValue> fetchEntries(Uids uids) {
    try {
      var questions = ("?," * uids.uids.length);
      questions = questions.substring(0, questions.length - 1);
      log("fetchEntries: questions : $questions");
      for (final uid in uids.uids) {
        log("fetchEntries: questions : uid: $uid");
      }
      final ResultSet resultSet = db.select(
          'SELECT * FROM entry_table WHERE uid IN ($questions)', uids.uids);

      List<UidAndValue> entries = [];
      log("fetchEntries: entries.length : ${entries.length}");
      for (final Row row in resultSet) {
        log("fetchEntries: row: $row");
        entries.add(UidAndValue(row['uid'], row['value']));
      }

      return entries;
    } catch (e, stacktrace) {
      log("fetchEntries: $e, stacktrace: $stacktrace");
      return [];
    }
  }

  static List<UidAndValue> fetchChains(Uids uids) {
    var questions = ("?," * uids.uids.length);
    questions = questions.substring(0, questions.length - 1);
    final ResultSet resultSet = db.select(
        'SELECT * FROM chain_table WHERE uid IN ($questions)', uids.uids);

    List<UidAndValue> entries = [];
    for (final Row row in resultSet) {
      entries.add(UidAndValue(row['uid'], row['value']));
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
    log("upsertEntries: start");
    List<UidAndValue> rejectedEntries = [];
    for (final entry in entries) {
      List<Uint8List> uids = [entry.uid];
      final resultSet = db.select(
        'SELECT value FROM entry_table WHERE uid  = ?',
        uids,
      );
      if (resultSet.length > 1) {
        throw Exception(
            "Invalid Entry table, found multiple rows for same uid");
      }

      if (resultSet.isEmpty) {
        upsertEntry(entry);
      } else {
        log("upsertEntries: exist");
        Uint8List actualValue = resultSet[0]['value'];
        if (actualValue == entry.oldValue) {
          upsertEntry(entry);
        } else {
          rejectedEntries.add(UidAndValue(entry.uid, actualValue));
        }
      }
    }
    return rejectedEntries;
  }

  static void upsertChains(List<UidAndValue> chains) {
    final stmt = db.prepare(
        'INSERT OR REPLACE INTO chain_table (uid, value) VALUES (?, ?)');
    for (final chain in chains) {
      stmt.execute([
        chain.uid,
        chain.value,
      ]);
      log("upsertChains: \nuid (len: ${chain.uid.length}): ${chain.uid}, \noldValue (len: ${chain.value.length}): ${chain.value}");
    }
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
    Map<IndexedValue, List<Keyword>> indexedValuesAndWords,
  ) async {
    await Findex.upsert(
      masterKey,
      label,
      indexedValuesAndWords,
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
    try {
      final uids =
          Uids.deserialize(uidsPointer.cast<Uint8>().asTypedList(uidsNumber));
      final entryTableLines = SqliteFindex.fetchEntries(uids);
      UidAndValue.serialize(outputEntryTableLinesPointer.cast<UnsignedChar>(),
          outputEntryTableLinesLength, entryTableLines);
      return 0;
    } catch (e, stacktrace) {
      log("Exception during fetchEntriesCallback $e $stacktrace");
      rethrow;
    }
  }

  static int fetchChainsCallback(
    Pointer<Char> outputChainTableLinesPointer,
    Pointer<UnsignedInt> outputChainTableLinesLength,
    Pointer<UnsignedChar> uidsPointer,
    int uidsNumber,
  ) {
    try {
      final uids =
          Uids.deserialize(uidsPointer.cast<Uint8>().asTypedList(uidsNumber));
      final entryTableLines = SqliteFindex.fetchChains(uids);
      UidAndValue.serialize(outputChainTableLinesPointer.cast<UnsignedChar>(),
          outputChainTableLinesLength, entryTableLines);
      return 0;
    } catch (e, stacktrace) {
      log("Exception during fetchChainsCallback $e $stacktrace");
      rethrow;
    }
  }

  static void upsertEntriesCallback(
    Pointer<UnsignedChar> entriesListPointer,
    int entriesListLength,
    Pointer<UnsignedChar> outputRejectedEntriesListPointer,
    Pointer<UnsignedInt> outputRejectedEntriesListLength,
  ) {
    try {
      // Deserialize uids and values
      final uidsAndValues = UpsertData.deserialize(
          entriesListPointer.cast<Uint8>().asTypedList(entriesListLength));

      final rejectedEntries = SqliteFindex.upsertEntries(uidsAndValues);
      UidAndValue.serialize(outputRejectedEntriesListPointer,
          outputRejectedEntriesListLength, rejectedEntries);
    } catch (e, stacktrace) {
      log("Exception during upsertEntriesCallback $e $stacktrace");
      rethrow;
    }
  }

  static void upsertChainsCallback(
    Pointer<UnsignedChar> chainsListPointer,
    int chainsListLength,
  ) {
    try {
      final uidsAndValues = UidAndValue.deserialize(
          chainsListPointer.cast<Uint8>().asTypedList(chainsListLength));
      log("upsertWrapperWithoutIsolate: uidsAndValues: $uidsAndValues");

      SqliteFindex.upsertChains(uidsAndValues);
    } catch (e, stacktrace) {
      log("Exception during upsertChainsCallback $e $stacktrace");
      rethrow;
    }
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

  List<Keyword> get indexedWords {
    return [
      Keyword.fromString(firstName),
      Keyword.fromString(lastName),
      Keyword.fromString(phone),
      Keyword.fromString(email),
      Keyword.fromString(country),
      Keyword.fromString(region),
      Keyword.fromString(employeeNumber),
      Keyword.fromString(security)
    ];
  }
}
