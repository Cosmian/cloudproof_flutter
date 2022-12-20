import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';

import 'encryption_test_vector.dart';
import 'user_secret_key_test_vector.dart';

class NonRegressionTestVectors {
  Uint8List publicKey;
  Uint8List masterSecretKey;
  Uint8List policy;
  UserSecretKeyTestVector topSecretMkgFinKey;
  UserSecretKeyTestVector mediumSecretMkgKey;
  UserSecretKeyTestVector topSecretFinKey;
  EncryptionTestVector lowSecretMkgTestVector;
  EncryptionTestVector topSecretMkgTestVector;
  EncryptionTestVector lowSecretFinTestVector;

  NonRegressionTestVectors(
      this.publicKey,
      this.masterSecretKey,
      this.policy,
      this.topSecretMkgFinKey,
      this.mediumSecretMkgKey,
      this.topSecretFinKey,
      this.lowSecretMkgTestVector,
      this.topSecretMkgTestVector,
      this.lowSecretFinTestVector);

  void verify() {
    // top_secret_fin_key
    lowSecretFinTestVector.decrypt(topSecretFinKey.key);
    try {
      lowSecretMkgTestVector.decrypt(topSecretFinKey.key);
    } catch (e) {
      // failing expected
    }
    try {
      topSecretMkgTestVector.decrypt(topSecretFinKey.key);
    } catch (e) {
      // failing expected
    }

    // top_secret_mkg_fin_key
    lowSecretFinTestVector.decrypt(topSecretMkgFinKey.key);
    lowSecretMkgTestVector.decrypt(topSecretMkgFinKey.key);
    topSecretMkgTestVector.decrypt(topSecretMkgFinKey.key);

    // medium_secret_mkg_fin_key
    try {
      lowSecretFinTestVector.decrypt(mediumSecretMkgKey.key);
    } catch (e) {
      // failing expected
    }
    lowSecretMkgTestVector.decrypt(mediumSecretMkgKey.key);
    try {
      topSecretMkgTestVector.decrypt(mediumSecretMkgKey.key);
    } catch (e) {
      // failing expected
    }
  }

  static NonRegressionTestVectors generate() {
    final policy = Policy.withMaxAttributeCreations(100)
        .addAxis(
            "Security Level",
            [
              "Protected",
              "Low Secret",
              "Medium Secret",
              "High Secret",
              "Top Secret"
            ],
            true)
        .addAxis("Department", ["R&D", "HR", "MKG", "FIN"], false);

    CoverCryptMasterKeys masterKeys = CoverCrypt.generateMasterKeys(policy);

    final topSecretMkgFinKey = UserSecretKeyTestVector.generate(
        masterKeys.masterSecretKey,
        policy,
        "(Department::MKG || Department:: FIN) && Security Level::Top Secret");
    final mediumSecretMkgKey = UserSecretKeyTestVector.generate(
        masterKeys.masterSecretKey,
        policy,
        "Security Level::Medium Secret && Department::MKG");
    final topSecretFinKey = UserSecretKeyTestVector.generate(
        masterKeys.masterSecretKey,
        policy,
        "Security Level::Top Secret && Department::FIN");

    final topSecretMkgTestVector = EncryptionTestVector.generate(
        policy,
        masterKeys.publicKey,
        "Department::MKG && Security Level::Top Secret",
        "TopSecretMkgPlaintext",
        Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        Uint8List.fromList([7, 8, 9, 10, 11]));

    final lowSecretMkgTestVector = EncryptionTestVector.generate(
        policy,
        masterKeys.publicKey,
        "Department::MKG && Security Level::Low Secret",
        "LowSecretMkgPlaintext",
        Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        Uint8List.fromList([]));

    final lowSecretFinTestVector = EncryptionTestVector.generate(
        policy,
        masterKeys.publicKey,
        "Department::FIN && Security Level::Low Secret",
        "LowSecretFinPlaintext",
        Uint8List.fromList([]),
        Uint8List.fromList([]));

    return NonRegressionTestVectors(
        masterKeys.publicKey,
        masterKeys.masterSecretKey,
        Uint8List.fromList(policy.toString().codeUnits),
        topSecretMkgFinKey,
        mediumSecretMkgKey,
        topSecretFinKey,
        lowSecretMkgTestVector,
        topSecretMkgTestVector,
        lowSecretFinTestVector);
  }

  NonRegressionTestVectors.fromJson(Map<String, dynamic> json)
      : publicKey = base64Decode(json['public_key']),
        masterSecretKey = base64Decode(json['master_secret_key']),
        policy = base64Decode(json['policy']),
        topSecretMkgFinKey =
            UserSecretKeyTestVector.fromJson(json['top_secret_mkg_fin_key']),
        mediumSecretMkgKey =
            UserSecretKeyTestVector.fromJson(json['medium_secret_mkg_key']),
        topSecretFinKey =
            UserSecretKeyTestVector.fromJson(json['top_secret_fin_key']),
        lowSecretMkgTestVector =
            EncryptionTestVector.fromJson(json['low_secret_mkg_test_vector']),
        topSecretMkgTestVector =
            EncryptionTestVector.fromJson(json['top_secret_mkg_test_vector']),
        lowSecretFinTestVector =
            EncryptionTestVector.fromJson(json['low_secret_fin_test_vector']);

  Map<String, dynamic> toJson() => {
        'public_key': base64Encode(publicKey),
        'master_secret_key': base64Encode(masterSecretKey),
        'policy': base64Encode(policy),
        'top_secret_mkg_fin_key': topSecretMkgFinKey.toJson(),
        'medium_secret_mkg_key': mediumSecretMkgKey.toJson(),
        'top_secret_fin_key': topSecretFinKey.toJson(),
        'low_secret_mkg_test_vector': lowSecretMkgTestVector.toJson(),
        'top_secret_mkg_test_vector': topSecretMkgTestVector.toJson(),
        'low_secret_fin_test_vector': lowSecretFinTestVector.toJson(),
      };
}
