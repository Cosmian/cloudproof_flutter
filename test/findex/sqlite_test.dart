// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;

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
      const dbPath = "./build/sqlite.db";

      await initDb(dbPath);

      final masterKey = FindexMasterKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));

      final label = Uint8List.fromList(utf8.encode("Some Label"));

      SqliteFindex.init(dbPath);
      expect(SqliteFindex.count('entry_table'), equals(0));
      expect(SqliteFindex.count('chain_table'), equals(0));

      await SqliteFindex.indexAll(masterKey, label);

      expect(SqliteFindex.count('entry_table'), equals(583));
      expect(SqliteFindex.count('chain_table'), equals(618));

      log("\n\n\n### Start Searching");
      final searchResults = await SqliteFindex.search(
          masterKey.k, label, [Keyword.fromString("France")]);

      expect(searchResults.length, 1);

      final keyword = searchResults.entries.toList()[0].key;
      final indexedValues = searchResults.entries.toList()[0].value;
      final usersIds = indexedValues.map((indexedValue) {
        return indexedValue.location.bytes[0];
      }).toList();
      usersIds.sort();
      log("Found usersIds: $usersIds");

      expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
      expect(usersIds, equals(expectedUsersIdsForFrance));
    });

    test('nonRegressionTest', () async {
      SqliteFindex.verify('test/resources/findex/non_regression/sqlite.db');
      final dir = Directory('test/resources/findex/non_regression/');
      final List<FileSystemEntity> entities = await dir.list().toList();
      entities.whereType<File>().forEach((element) async {
        final newPath =
            path.join(Directory.systemTemp.path, path.basename(element.path));
        element.copySync(newPath);
        await SqliteFindex.verify(newPath);
        print("... OK: Findex non regression test file: $newPath");
      });
    });
  });
}

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

class SqliteFindex {
  static Database? singletonDb;

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

    await upsert(masterKey, label, indexedValuesAndKeywords);
  }

  static Future<void> indexAllFromFile(
      String usersFilepath, FindexMasterKey masterKey, Uint8List label) async {
    final users = jsonDecode(await File(usersFilepath).readAsString());

    final stmt = db.prepare(
        'INSERT INTO users (id, firstName, lastName, phone, email, country, region, employeeNumber, security) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');

    final indexedValuesAndKeywords = {
      for (final user in users)
        IndexedValue.fromLocation(
            Location(Uint8List(4)..buffer.asInt32List()[0] = user['id'])): [
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

    await upsert(masterKey, label, indexedValuesAndKeywords);

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
    final stmt = db.prepare(
        'INSERT INTO entry_table (uid, value) VALUES (?, ?) ON CONFLICT (uid)  DO UPDATE SET value = ? WHERE value = ?');
    for (final entry in entries) {
      stmt.execute([
        entry.uid,
        entry.newValue,
        entry.newValue,
        entry.oldValue,
      ]);
    }
    return [];
  }

  static void insertChains(List<UidAndValue> chains) {
    final stmt = db.prepare(
        'INSERT OR REPLACE INTO chain_table (uid, value) VALUES (?, ?)');
    for (final chain in chains) {
      stmt.execute([
        chain.uid,
        chain.value,
      ]);
      log("insertChains: \nuid (len: ${chain.uid.length}): ${chain.uid}, \noldValue (len: ${chain.value.length}): ${chain.value}");
    }
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<Map<Keyword, List<IndexedValue>>> search(
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
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        insertChainsCallback,
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
    return Findex.wrapSyncFetchCallback(
      SqliteFindex.fetchEntries,
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
    return Findex.wrapSyncFetchCallback(
      SqliteFindex.fetchChains,
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
    return Findex.wrapSyncUpsertEntriesCallback(
      SqliteFindex.upsertEntries,
      outputRejectedEntriesListPointer,
      outputRejectedEntriesListLength,
      entriesListPointer,
      entriesListLength,
    );
  }

  static int insertChainsCallback(
    Pointer<UnsignedChar> chainsListPointer,
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

    expect(SqliteFindex.count('entry_table'), equals(583));
    expect(SqliteFindex.count('chain_table'), equals(618));

    log("\n\n\n### Start Searching");
    {
      final searchResults =
          await search(masterKey.k, label, [Keyword.fromString("France")]);

      expect(searchResults.length, equals(1));

      final keyword = searchResults.entries.toList()[0].key;
      final indexedValues = searchResults.entries.toList()[0].value;
      final usersIds = indexedValues.map((indexedValue) {
        return indexedValue.location.bytes[0];
      }).toList();
      usersIds.sort();
      log("Found usersIds: $usersIds");

      expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
      expect(usersIds.length, expectedUsersIdsForFrance.length);
    }

    log("\n\n\n### Start Upserting");
    await indexAllFromFile(
        'test/resources/findex/single_user.json', masterKey, label);

    log("\n\n\n### Start Searching again");
    {
      final searchResults =
          await search(masterKey.k, label, [Keyword.fromString("France")]);

      expect(searchResults.length, 1);

      final keyword = searchResults.entries.toList()[0].key;
      final indexedValues = searchResults.entries.toList()[0].value;
      final usersIds = indexedValues.map((indexedValue) {
        return indexedValue.location.bytes[0];
      }).toList();
      usersIds.sort();

      expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
      expect(usersIds.length, expectedUsersIdsForFrance.length + 1);
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
    return Location(Uint8List(4)..buffer.asInt32List()[0] = id);
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
