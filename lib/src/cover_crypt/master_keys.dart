import 'dart:convert';
import 'dart:typed_data';

class CoverCryptMasterKeys {
  Uint8List masterSecretKey;
  Uint8List publicKey;

  CoverCryptMasterKeys(this.masterSecretKey, this.publicKey);

  static CoverCryptMasterKeys create(
      Uint8List masterSecretKey, Uint8List masterPublicKey) {
    if (masterSecretKey.length < 4) {
      throw Exception(
          "Cannot create a MasterKeys: secret key input bytes length must be at least 4");
    }
    if (masterPublicKey.length < 4) {
      throw Exception(
          "Cannot create a MasterKeys: public key input bytes length must be at least 4");
    }

    return CoverCryptMasterKeys(masterSecretKey, masterPublicKey);
  }

  CoverCryptMasterKeys.fromJson(Map<String, dynamic> json)
      : publicKey = base64Decode(json['public_key']),
        masterSecretKey = base64Decode(json['master_secret_key']);

  Map<String, dynamic> toJson() => {
        'public_key': base64Encode(publicKey),
        'master_secret_key': base64Encode(masterSecretKey),
      };
}
