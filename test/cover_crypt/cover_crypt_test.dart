// ignore_for_file: avoid_print
//

// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:cloudproof/src/cover_crypt/policy.dart';
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

    test('policy', () {
      String policyJson =
          "{\"last_attribute_value\":9,\"max_attribute_creations\":100,\"axes\":{\"Department\":[[\"R&D\",\"HR\",\"MKG\",\"FIN\"],false],\"Security Level\":[[\"Protected\",\"Low Secret\",\"Medium Secret\",\"High Secret\",\"Top Secret\"],true]},\"attribute_to_int\":{\"Security Level::Medium Secret\":[3],\"Security Level::Protected\":[1],\"Security Level::High Secret\":[4],\"Department::R&D\":[6],\"Department::HR\":[7],\"Security Level::Low Secret\":[2],\"Department::MKG\":[8],\"Security Level::Top Secret\":[5],\"Department::FIN\":[9]}}";
      final policy = Policy.fromJson(jsonDecode(policyJson));
      expect(policyJson, policy.toString());
    });
  });
}
