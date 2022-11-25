import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';

class EncryptionTestVector {
  String encryptionPolicy;
  Uint8List plaintext;
  Uint8List ciphertext;
  Uint8List headerMetadata;
  Uint8List authenticationData;

  EncryptionTestVector(
    this.encryptionPolicy,
    this.plaintext,
    this.ciphertext,
    this.headerMetadata,
    this.authenticationData,
  );

  void decrypt(Uint8List key) {
    final cc = CoverCryptDecryption(key);
    final cleartext =
        cc.decryptWithAuthenticationData(ciphertext, authenticationData);

    expect(cleartext.cleartext, plaintext);
    expect(cleartext.metadata, headerMetadata);
  }

  EncryptionTestVector.fromJson(Map<String, dynamic> json)
      : encryptionPolicy = json['encryption_policy'],
        plaintext = base64Decode(json['plaintext']),
        ciphertext = base64Decode(json['ciphertext']),
        headerMetadata = base64Decode(json['meta_data']),
        authenticationData = base64Decode(json['authentication_data']);

  Map<String, dynamic> toJson(String keyId) => {
        'encryption_policy': encryptionPolicy,
        'plaintext': base64Encode(plaintext),
        'ciphertext': base64Encode(ciphertext),
        'meta_data': base64Encode(headerMetadata),
        'authentication_data': base64Encode(authenticationData),
      };
}
