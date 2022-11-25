import 'dart:convert';
import 'dart:typed_data';

class UserSecretKeyTestVector {
  String accessPolicy;
  Uint8List key;

  UserSecretKeyTestVector(this.accessPolicy, this.key);

  UserSecretKeyTestVector.fromJson(Map<String, dynamic> json)
      : accessPolicy = json['access_policy'],
        key = base64Decode(json['key']);

  Map<String, dynamic> toJson(String keyId) => {
        'access_policy': accessPolicy,
        'key': base64Encode(key),
      };
}
