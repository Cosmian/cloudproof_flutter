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
    final decrypted = CoverCrypt.decryptWithAuthenticationData(
        key, ciphertext, authenticationData);

    expect(decrypted.plaintext, plaintext);
    expect(decrypted.headerMetadata, headerMetadata);
  }

  static EncryptionTestVector generate(
      Policy policy,
      Uint8List publicKey,
      String encryptionPolicy,
      String plaintext,
      Uint8List headerMetadata,
      Uint8List authenticationData) {
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
    final ciphertext = CoverCrypt.encryptWithAuthenticationData(
        policy,
        publicKey,
        encryptionPolicy,
        plaintextBytes,
        headerMetadata,
        authenticationData);
    return EncryptionTestVector(encryptionPolicy, plaintextBytes, ciphertext,
        headerMetadata, authenticationData);
  }

  EncryptionTestVector.fromJson(Map<String, dynamic> json)
      : encryptionPolicy = json['encryption_policy'],
        plaintext = base64Decode(json['plaintext']),
        ciphertext = base64Decode(json['ciphertext']),
        headerMetadata = base64Decode(json['header_metadata']),
        authenticationData = base64Decode(json['authentication_data']);

  Map<String, dynamic> toJson() => {
        'encryption_policy': encryptionPolicy,
        'plaintext': base64Encode(plaintext),
        'ciphertext': base64Encode(ciphertext),
        'header_metadata': base64Encode(headerMetadata),
        'authentication_data': base64Encode(authenticationData),
      };
}
