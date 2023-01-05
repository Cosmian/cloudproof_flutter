// ignore_for_file: avoid_print

// Dart imports:
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Package imports:
import 'package:cloudproof/cloudproof.dart';
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

    test('publicDoc', () async {
      final policy = Policy.withMaxAttributeCreations(100)
          .addAxis("Security Level",
              ["Protected", "Confidential", "Top Secret"], true)
          .addAxis("Department", ["FIN", "HR", "MKG"], false);

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

    test('policy', () {
      String policyJson =
          "{\"last_attribute_value\":9,\"max_attribute_creations\":100,\"axes\":{\"Department\":[[\"R&D\",\"HR\",\"MKG\",\"FIN\"],false],\"Security Level\":[[\"Protected\",\"Low Secret\",\"Medium Secret\",\"High Secret\",\"Top Secret\"],true]},\"attribute_to_int\":{\"Security Level::Medium Secret\":[3],\"Security Level::Protected\":[1],\"Security Level::High Secret\":[4],\"Department::R&D\":[6],\"Department::HR\":[7],\"Security Level::Low Secret\":[2],\"Department::MKG\":[8],\"Security Level::Top Secret\":[5],\"Department::FIN\":[9]}}";
      final policy = Policy.fromJson(jsonDecode(policyJson));
      expect(policyJson, policy.toString());
    });
  });
}
