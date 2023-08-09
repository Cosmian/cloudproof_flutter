// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'sqlite_findex.dart';

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
      final upsertResults = await SqliteFindex.indexAll(masterKey, label);
      expect(upsertResults.length, 583);

      try {
        SqliteFindex.throwInsideFetchEntries = true;

        await SqliteFindex.search(
          masterKey.k,
          label,
          [Keyword.fromString("France")],
        );

        throw Exception("search should throw");
      } catch (e, stacktrace) {
        // When an exception is thrown inside a callback
        // we should rethrow the exception from our functions
        // instead of throwing a generic Findex exception.
        // The message should be the same
        // The stacktrace should point to the correct line inside the user callback.
        // This is working saving by the exceptions during the callbacks runs, returning a
        // specific error code, Findex forwards the specific error code, Flutter catch the
        // error code at the end of the search/upsert operation and find the saved exception
        // to rethrow.
        expect(
          e.toString(),
          "Unsupported operation: Some message",
        );
        expect(stacktrace.toString(), contains("SqliteFindex.fetchEntries"));
        expect(
          stacktrace.toString(),
          contains(
              "test/findex/sqlite_findex.dart:273:7"), // When moving stuff inside this file, this assertion could fail because the line number change. Please set the line number to the line below containing :ExceptionLine
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
          "`uid` should be of length 32. Actual length is 114 bytes.",
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
          "`uid` should be of length 32. Actual length is 108 bytes.",
        );
      } finally {
        SqliteFindex.returnOnlyValueInsideFetchEntries = false;
      }
    });

    Future<void> insertNewIndexes(
        String dbPath,
        FindexMasterKey masterKey,
        Uint8List label,
        Map<IndexedValue, List<Keyword>> indexedValuesAndKeywords,
        {int expectedNumberOfIndexes = 1}) async {
      await initDb(dbPath);
      SqliteFindex.init(dbPath);

      expect(SqliteFindex.count('entry_table'), equals(0));
      expect(SqliteFindex.count('chain_table'), equals(0));

      await SqliteFindex.upsert(masterKey, label, indexedValuesAndKeywords, {});

      expect(
          SqliteFindex.count('entry_table'), equals(expectedNumberOfIndexes));
      expect(
          SqliteFindex.count('chain_table'), equals(expectedNumberOfIndexes));
    }

    void checkResults(
        Map<Keyword, List<Location>> searchResults, List<int> expectedIds,
        {String word = "John"}) {
      expect(searchResults.length, 1);

      final keyword = searchResults.entries.first.key;
      final indexedValues = searchResults.entries.first.value;
      final usersIds =
          indexedValues.map((location) => location.number).toList();
      usersIds.sort();
      expect(Keyword.fromString(word).toBase64(), keyword.toBase64());
      expect(usersIds, equals(expectedIds));
    }

    test('multi entry tables', () async {
      final masterKey = FindexMasterKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));
      final label = Uint8List.fromList(utf8.encode("Some Label"));

      const db1Path = "./build/sqlite_multi_entry_tables_1.db";
      const db2Path = "./build/sqlite_multi_entry_tables_2.db";
      const db3Path = "./build/sqlite_multi_entry_tables_3.db";

      await insertNewIndexes(db1Path, masterKey, label, {
        IndexedValue.fromLocation(Location.fromNumber(1)): [
          Keyword.fromString("John")
        ]
      });
      await insertNewIndexes(db2Path, masterKey, label, {
        IndexedValue.fromLocation(Location.fromNumber(2)): [
          Keyword.fromString("John")
        ]
      });
      await insertNewIndexes(db3Path, masterKey, label, {
        IndexedValue.fromLocation(Location.fromNumber(3)): [
          Keyword.fromString("John")
        ]
      });

      SqliteFindexMultiEntryTables.init([db1Path, db2Path, db3Path]);

      // Bad entry table number (should be 3)
      try {
        await SqliteFindexMultiEntryTables.search(
            masterKey.k, label, [Keyword.fromString("John")],
            entryTableNumber: 2);
      } catch (e) {
        expect(
          e.toString(),
          "callback 'fetch entries' returned an error code: 1",
        );
      }

      // Searching words without the correct entry tables number. The `fetchEntries` callback fails in the rust part but the callback returns the correct amount of memory and then the rust part retries with this amount (and finally succeed). This behavior is analogous with the java behavior.
      var searchResults = await SqliteFindexMultiEntryTables.search(
          masterKey.k, label, [Keyword.fromString("John")],
          entryTableNumber: 1);
      checkResults(searchResults, [1, 2, 3]);

      // Same research but with the correct number of entry tables
      searchResults = await SqliteFindexMultiEntryTables.search(
          masterKey.k, label, [Keyword.fromString("John")],
          entryTableNumber: 3);
      checkResults(searchResults, [1, 2, 3]);
    });

    test('multi entry tables asymmetric tables', () async {
      final masterKey = FindexMasterKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));
      final label = Uint8List.fromList(utf8.encode("Some Label"));

      const db1Path = "./build/sqlite_multi_entry_tables_1.db";
      const db2Path = "./build/sqlite_multi_entry_tables_2.db";

      await insertNewIndexes(
          db1Path,
          masterKey,
          label,
          {
            IndexedValue.fromLocation(Location.fromNumber(1)): [
              Keyword.fromString("John")
            ],
            IndexedValue.fromLocation(Location.fromNumber(2)): [
              Keyword.fromString("Marie")
            ]
          },
          expectedNumberOfIndexes: 2);

      await insertNewIndexes(
        db2Path,
        masterKey,
        label,
        {
          IndexedValue.fromLocation(Location.fromNumber(1)): [
            Keyword.fromString("John")
          ],
          IndexedValue.fromLocation(Location.fromNumber(1)): [
            Keyword.fromString("Marie")
          ]
        },
      );

      SqliteFindexMultiEntryTables.init([db1Path, db2Path]);

      // Search tests
      var searchResults = await SqliteFindexMultiEntryTables.search(
          masterKey.k, label, [Keyword.fromString("John")],
          entryTableNumber: 2);
      checkResults(searchResults, [1]);

      searchResults = await SqliteFindexMultiEntryTables.search(
          masterKey.k, label, [Keyword.fromString("Marie")],
          entryTableNumber: 2);
      checkResults(searchResults, [1, 2], word: "Marie");

      searchResults = await SqliteFindexMultiEntryTables.search(masterKey.k,
          label, [Keyword.fromString("Marie"), Keyword.fromString("John")],
          entryTableNumber: 2);
      expect(searchResults.length, 2);

      for (var entry in searchResults.entries) {
        if (entry.key.toBase64() == Keyword.fromString("John").toBase64()) {
          final usersIds =
              entry.value.map((location) => location.number).toList();
          usersIds.sort();
          expect(usersIds, equals([1]));
        } else if (entry.key.toBase64() ==
            Keyword.fromString("Marie").toBase64()) {
          final usersIds =
              entry.value.map((location) => location.number).toList();
          usersIds.sort();
          expect(usersIds, equals([1, 2]));
        }
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

      final upsertResults = await SqliteFindex.indexAll(masterKey, label);
      expect(upsertResults.length, 583);

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
      for (File file in entities.whereType<File>()) {
        final newPath =
            path.join(Directory.systemTemp.path, path.basename(file.path));
        print("Test findex file: $newPath");
        file.copySync(newPath);
        try {
          await SqliteFindex.verify(newPath);
        } catch (e) {
          print("Exception on $newPath: $e");
          rethrow;
        }
        print("... OK: Findex non regression test file: $newPath");
      }
    });
  });
}
