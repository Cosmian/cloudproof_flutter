import 'dart:convert';
import 'dart:typed_data';

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

  // NonRegressionTestVectors generate() {
  //   NonRegressionTestVectors output = new NonRegressionTestVectors();
  //   return output;
  // }

  NonRegressionTestVectors.fromJson(Map<String, dynamic> json)
      : publicKey = base64Decode(json['public_key']),
        masterSecretKey = base64Decode(json['master_private_key']),
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
      };
}
