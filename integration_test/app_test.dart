// integration_test/app_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/src/findex/indexed_value.dart';
import 'package:cloudproof/src/findex/master_key.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/findex/sqlite_findex.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('findex test', () {
    testWidgets('go to the list and detail views', (WidgetTester tester) async {
      const dbPath = "./sqlite.db";

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
      final indexedValues = searchResults.entries.toList()[0].value;
      final usersIds = indexedValues.map((indexedValue) {
        return indexedValue.location.bytes[0];
      }).toList();
      usersIds.sort();

      expect(Keyword.fromString("France").toBase64(), keyword.toBase64());
      expect(usersIds, equals(expectedUsersIdsForFrance));
    });
  });
}
