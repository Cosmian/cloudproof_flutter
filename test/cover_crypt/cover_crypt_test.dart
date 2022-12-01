// ignore_for_file: avoid_print
//

// Dart imports:
import 'dart:convert';
import 'dart:io';

// Project imports:
import 'package:cloudproof/cloudproof.dart';
import 'package:cloudproof/src/cover_crypt/cover_crypt.dart';
// Package imports:
import 'package:flutter_test/flutter_test.dart';

import 'non_regression_test_vectors.dart';

final ciphertext = base64Decode(
    "eDrJ+GpP63RFedSHqmIqoT2gAH9PA7y13u22bWQ1+XxuJZeHzanQAKk9Y/TxlNfrIShTvvyGBEYFryVu/FpBNQK0+yO++Uqau2tHcmxjSX8kRZieMfHD9CF42lIVK1PNUjadmMoxFeF4WoH4qjmJa2uiViWCCatYkZjvYjpvnnzi6FGVeIpRJCIQ+pT9wafg0iY3HDugISqoY7d9Xb7PIuzwgQPASU9lPyaoce6nSRiqinDGmwos0uQXu8pL8z3ydSC+Fwq5uGGmtwAvxGqAkgzEMKwIIIYJVwE0rT0dom11A7LkYqAgDi7MTUdZHKtHLe7qS0aH2DJHAGMqkheQvIERrU7z19DHyT7aDsGkZg==");

final key = base64Decode(
    "1gQaQuzgSmCwHBog+ADpfjOVfWC4Ue6FIEYmjvfHcQhD0MqNNL1cvyF324IIFK9w5FOwWDDKXLKifVskjCjJBwqxeGROFHknVx93TyLEnHkbH+0xqTtHF9mcb1FT0oVZCT7hecwZ4fcxqBrMVVDFFJg3nBhf9oBUrlPNd+C2wr0NVz8lwr/Ujf2wkAuVvyF65cGd1O4nt7dJolz5ouqVowQyP0WqE8mpPMnBkKX1N2g50suTLTffLbXhGXVyqhvuDQ2z/TkA/DxykKux78tGviWkwpVBVybgDw/WQ1W391oDAA6LLC4Ozgi8ow6njXSLLREOW+ezF8AAZahzKDJm1QPLNc97X1g1aASin+3Xz026j2EcamZ+X9CJZ+/05Cb7CXH4JXyapuNAEZRcu0JvnLVMkyT5aWnCe3AWalA4388HOzkc/nVozC0n+oAZJ2/RBUpMwBBHifmvn7BQNYt8Wws57rkdpmywZtW6YfzNcCdGPvKXyRZ6n+eki2KYjj46CA==");

final plaintext = base64Decode("TXkgc2VjcmV0IG1lc3NhZ2U=");

void main() {
  group('CoverCrypt', () {
    test('CoverCryptDecryption.decrypt', () async {
      final result = CoverCrypt.decrypt(key, ciphertext);
      expect(result.plaintext, equals(plaintext));
    });

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
