// ignore_for_file: avoid_print

// Dart imports:
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Package imports:
import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuple/tuple.dart';

import 'non_regression_test_vectors.dart';

void main() {
  group('CoverCrypt', () {
    test('nonRegressionTest', () async {
      final dir = Directory('test/resources/cover_crypt/non_regression/');
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
      final file = File('build/non_regression_vector.json');

      // Write the file
      return file.writeAsString(jsonEncode(json));
    });

    test('encrypt decrypt', () async {
      final policy = Policy.init()
          .addAxis(
              "Security Level",
              [
                const Tuple2("Protected", false),
                const Tuple2("Confidential", false),
                const Tuple2("Top Secret", false)
              ],
              true)
          .addAxis(
              "Department",
              [
                const Tuple2("FIN", false),
                const Tuple2("HR", false),
                const Tuple2("MKG", false)
              ],
              false);

      CoverCryptMasterKeys masterKeys = CoverCrypt.generateMasterKeys(policy);

      //
      // Generating ciphertexts
      //
      final protectedMkgCiphertext = CoverCrypt.encrypt(
          policy,
          masterKeys.publicKey,
          "Department::MKG && Security Level::Protected",
          Uint8List.fromList(utf8.encode("ProtectedMkgPlaintext")));

      final topSecretMkgCiphertext = CoverCrypt.encrypt(
          policy,
          masterKeys.publicKey,
          "Department::MKG && Security Level::Top Secret",
          Uint8List.fromList(utf8.encode("TopSecretMkgPlaintext")));

      final protectedFinCiphertext = CoverCrypt.encrypt(
          policy,
          masterKeys.publicKey,
          "Department::FIN && Security Level::Protected",
          Uint8List.fromList(utf8.encode("ProtectedFinPlaintext")));

      //
      // Generating user secret keys
      //
      final confidentialMkgKey = CoverCrypt.generateUserSecretKey(
        "Security Level::Confidential && Department::MKG",
        policy,
        masterKeys.masterSecretKey,
      );
      final topSecretMkgFinKey = CoverCrypt.generateUserSecretKey(
        "(Department::MKG || Department:: FIN) && Security Level::Top Secret",
        policy,
        masterKeys.masterSecretKey,
      );

      //
      // Decrypting ciphertexts
      //
      // medium_secret_mkg_fin_key
      try {
        CoverCrypt.decrypt(confidentialMkgKey, protectedFinCiphertext);
      } catch (e) {
        // failing expected
      }
      CoverCrypt.decrypt(confidentialMkgKey, protectedMkgCiphertext);
      try {
        CoverCrypt.decrypt(confidentialMkgKey, topSecretMkgCiphertext);
      } catch (e) {
        // failing expected
      }

      CoverCrypt.decrypt(topSecretMkgFinKey, protectedFinCiphertext);
      CoverCrypt.decrypt(topSecretMkgFinKey, protectedMkgCiphertext);
      CoverCrypt.decrypt(topSecretMkgFinKey, topSecretMkgCiphertext);
    });
  });
}
