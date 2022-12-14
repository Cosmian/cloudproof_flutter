// ignore_for_file: avoid_print
//

// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

import 'non_regression_test_vectors.dart';

void main() {
  group('CoverCrypt', () {
    test('nonRegressionTest', () async {
      final dir = Directory('test/resources/cover_crypt/');
      final List<FileSystemEntity> entities = await dir.list().toList();
      entities.whereType<File>().forEach((element) async {
        NonRegressionTestVectors.fromJson(
                jsonDecode(await File(element.path).readAsString()))
            .verify();
        print("... OK: Non regression test file: ${element.path}");
      });
    });

    test('generateNonRegressionTest', () async {
      final json = NonRegressionTestVectors.generate().toJson();
      final file = File('build/non_regression_test_vector.json');

      // Write the file
      return file.writeAsString(jsonEncode(json));
    });
  });
}
