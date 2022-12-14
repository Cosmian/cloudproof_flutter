import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';

class UserSecretKeyTestVector {
  String accessPolicy;
  Uint8List key;

  UserSecretKeyTestVector(this.accessPolicy, this.key);

  static UserSecretKeyTestVector generate(
      Uint8List masterSecretKey, String policy, String accessPolicyArg) {
    Uint8List userPrivateKey = CoverCrypt.generateUserSecretKey(
        accessPolicyArg, policy, masterSecretKey);
    return UserSecretKeyTestVector(accessPolicyArg, userPrivateKey);
  }

  UserSecretKeyTestVector.fromJson(Map<String, dynamic> json)
      : accessPolicy = json['access_policy'],
        key = base64Decode(json['key']);

  Map<String, dynamic> toJson() => {
        'access_policy': accessPolicy,
        'key': base64Encode(key),
      };
}
