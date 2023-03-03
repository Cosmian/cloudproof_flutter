// ignore_for_file: avoid_print

import 'dart:convert';
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
    test('errors', () async {
      const dbPath = "./build/sqlite2.db";
      await initDb(dbPath);
      SqliteFindex.init(dbPath);

      final masterKey = FindexMasterKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));
      final label = Uint8List.fromList(utf8.encode("Some Label"));
      await SqliteFindex.indexAll(masterKey, label);

      try {
        SqliteFindex.throwInsideFetchEntries = true;

        await SqliteFindex.search(
          masterKey.k,
          label,
          [Keyword.fromString("France")],
        );

        throw Exception("search should throw");
      } catch (e, stacktrace) {
        expect(
          e.toString(),
          "callback returned with error code 42: fetch entries",
        );
        expect(stacktrace.toString(), contains("SqliteFindex.search"));
        expect(
          stacktrace.toString(),
          contains("src/findex/findex.dart:229:5"), // :ExceptionLine
        );
      } finally {
        SqliteFindex.throwInsideFetchEntries = false;
      }

      try {
        await SqliteFindex.search(
          masterKey.k.sublist(0, 4),
          label,
          [Keyword.fromString("France")],
        );

        throw Exception("search should throw");
      } catch (e) {
        expect(
          e.toString(),
          "error deserializing master secret key: wrong size when parsing bytes: 4 given should be 16",
        );
      }

      try {
        SqliteFindex.returnOnlyUidInsideFetchChains = true;

        await SqliteFindex.search(
          masterKey.k,
          label,
          [Keyword.fromString("France")],
        );

        throw Exception("search should throw");
      } catch (e) {
        expect(
          e.toString(),
          startsWith(
              "fail to decrypt one of the `value` returned by the fetch chains callback (uid was"),
        );
      } finally {
        SqliteFindex.returnOnlyUidInsideFetchChains = false;
      }

      try {
        SqliteFindex.returnOnlyValueInsideFetchChains = true;

        await SqliteFindex.search(
          masterKey.k,
          label,
          [Keyword.fromString("France")],
        );

        throw Exception("search should throw");
      } catch (e) {
        expect(
          e.toString(),
          "callback returned with error code 42: fetch chains",
        );
      } finally {
        SqliteFindex.returnOnlyValueInsideFetchChains = false;
      }

      try {
        SqliteFindex.returnOnlyUidInsideFetchEntries = true;

        await SqliteFindex.search(
          masterKey.k,
          label,
          [Keyword.fromString("France")],
        );

        throw Exception("search should throw");
      } catch (e) {
        expect(
          e.toString(),
          startsWith(
              "fail to decrypt one of the `value` returned by the fetch entries callback (uid was"),
        );
      } finally {
        SqliteFindex.returnOnlyUidInsideFetchEntries = false;
      }

      try {
        SqliteFindex.returnOnlyValueInsideFetchEntries = true;

        await SqliteFindex.search(
          masterKey.k,
          label,
          [Keyword.fromString("France")],
        );

        throw Exception("search should throw");
      } catch (e) {
        expect(
          e.toString(),
          "callback returned with error code 42: fetch entries",
        );
      } finally {
        SqliteFindex.returnOnlyValueInsideFetchEntries = false;
      }
    });

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

      final searchResults = await SqliteFindex.search(
          masterKey.k, label, [Keyword.fromString("France")]);

      expect(searchResults.length, 1);

      final keyword = searchResults.entries.toList()[0].key;
      final locations = searchResults.entries.toList()[0].value;
      final usersIds = locations.map((location) {
        return location.number;
      }).toList();
      usersIds.sort();

      expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
      expect(usersIds, equals(expectedUsersIdsForFrance));
    });

    test('nonRegressionTest', () async {
      final dir = Directory('test/resources/findex/non_regression/');
      final List<FileSystemEntity> entities = await dir.list().toList();
      entities.whereType<File>().forEach((element) async {
        final newPath =
            path.join(Directory.systemTemp.path, path.basename(element.path));
        print("Test findex file: $newPath");
        element.copySync(newPath);
        try {
          await SqliteFindex.verify(newPath);
        } catch (e) {
          print("Exception on $newPath: $e");
          rethrow;
        }
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

  static int progress(Map<Keyword, List<IndexedValue>> progressResults) {
    final keyword = progressResults.entries.toList()[0].key;
    final indexedValues = progressResults.entries.toList()[0].value;

    expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
    expect(indexedValues.length, 30);

    return 1;
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<Map<Keyword, List<Location>>> search(
    Uint8List keyK,
    Uint8List label,
    List<Keyword> words,
  ) async {
    return await Findex.searchWithProgress(
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
        Pointer.fromFunction(
          progressCallback,
          errorCodeInCaseOfCallbackException,
        ));
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

  static int progressCallback(
    Pointer<UnsignedChar> uidsListPointer,
    int uidsListLength,
  ) {
    return Findex.wrapProgressCallback(
      SqliteFindex.progress,
      uidsListPointer,
      uidsListLength,
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
      final locations = searchResults.entries.toList()[0].value;
      final usersIds = locations.map((location) {
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
      final locations = searchResults.entries.toList()[0].value;
      final usersIds = locations.map((location) {
        return location.number;
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
    return Location.fromNumber(id);
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
