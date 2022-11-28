import 'dart:convert';
import 'dart:typed_data';

class CoverCryptMasterKeys {
  Uint8List masterSecretKey;
  Uint8List publicKey;

  CoverCryptMasterKeys(this.masterSecretKey, this.publicKey);

  static CoverCryptMasterKeys create(Uint8List masterKeys) {
    if (masterKeys.length < 4) {
      throw Exception(
          "Cannot create a MasterKeys: input bytes length must be at least 4");
    }

    final header = masterKeys.sublist(0, 4);
    final headerSize = header.buffer.asByteData().getInt32(0);
    if (headerSize <= 0) {
      throw Exception(
          "Invalid header: convert int32 must be strictly positive");
    }

    final masterSecretKeyBytes = masterKeys.sublist(4, 4 + headerSize);
    final publicKeyBytes = masterKeys.sublist(4 + headerSize);

    return CoverCryptMasterKeys(masterSecretKeyBytes, publicKeyBytes);
  }

  CoverCryptMasterKeys.fromJson(Map<String, dynamic> json)
      : publicKey = base64Decode(json['public_key']),
        masterSecretKey = base64Decode(json['master_secret_key']);

  Map<String, dynamic> toJson() => {
        'public_key': base64Encode(publicKey),
        'master_secret_key': base64Encode(masterSecretKey),
      };
}
