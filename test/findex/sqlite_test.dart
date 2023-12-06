// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_findex.dart';

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
      final findexKey = FindexKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));
      SqliteFindex.init(dbPath, findexKey, "Some Label");

      final upsertResults = await SqliteFindex.indexAll();
      expect(upsertResults.length, 583);

      try {
        SqliteFindex.throwInsideFetchEntries = true;

        await SqliteFindex.search({Keyword.fromString("France")});

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
              "test/findex/sqlite_findex.dart:231:7"), // When moving stuff inside this file, this assertion could fail because the line number change. Please set the line number to the line below containing :ExceptionLine
        );
      } finally {
        SqliteFindex.throwInsideFetchEntries = false;
      }

      try {
        SqliteFindex.returnOnlyUidInsideFetchChains = true;

        await SqliteFindex.search({Keyword.fromString("France")});

        throw Exception("search should throw");
      } catch (e) {
        expect(
            e.toString(),
            startsWith(
                "findex `search` error: database interface error: serialization: serialization error: crypto error: incorrect length for encrypted value: 32 bytes give, 114 bytes expected"));
      } finally {
        SqliteFindex.returnOnlyUidInsideFetchChains = false;
      }

      try {
        SqliteFindex.returnOnlyValueInsideFetchChains = true;

        await SqliteFindex.search({Keyword.fromString("France")});

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

        await SqliteFindex.search({Keyword.fromString("France")});

        throw Exception("search should throw");
      } catch (e) {
        expect(
            e.toString(),
            startsWith(
                "findex `search` error: database interface error: serialization: serialization error: crypto error: incorrect length for encrypted value: 32 bytes give, 108 bytes expected"));
      } finally {
        SqliteFindex.returnOnlyUidInsideFetchEntries = false;
      }

      try {
        SqliteFindex.returnOnlyValueInsideFetchEntries = true;

        await SqliteFindex.search({Keyword.fromString("France")});

        throw Exception("search should throw");
      } catch (e) {
        expect(
          e.toString(),
          "`uid` should be of length 32. Actual length is 108 bytes.",
        );
      } finally {
        SqliteFindex.returnOnlyValueInsideFetchEntries = false;
      }
    }, tags: 'sqlite');

    test('search/upsert', () async {
      const dbPath = "./build/sqlite.db";

      await initDb(dbPath);

      final findexKey = FindexKey.fromJson(jsonDecode(
          await File('test/resources/findex/master_key.json').readAsString()));

      SqliteFindex.init(dbPath, findexKey, "Some Label");

      expect(SqliteFindex.count('entry_table'), equals(0));
      expect(SqliteFindex.count('chain_table'), equals(0));

      final upsertResults = await SqliteFindex.indexAll();
      expect(upsertResults.length, 583);

      expect(SqliteFindex.count('entry_table'), equals(583));
      expect(SqliteFindex.count('chain_table'), equals(618));

      final searchResults =
          await SqliteFindex.search({Keyword.fromString("France")});

      expect(searchResults.length, 1);

      final keyword = searchResults.entries.toList()[0].key;
      final locations = searchResults.entries.toList()[0].value;
      final usersIds = locations.map((location) {
        return location.number;
      }).toList();
      usersIds.sort();

      expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
      expect(usersIds, equals(expectedUsersIdsForFrance));
    }, tags: 'sqlite');

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
    }, tags: 'sqlite');
  });
}
