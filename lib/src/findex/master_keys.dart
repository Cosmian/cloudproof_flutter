import 'dart:convert';
import 'dart:typed_data';

class MasterKeys {
  Uint8List k;
  Uint8List kStar;

  MasterKeys(this.k, this.kStar);

  MasterKeys.fromJson(Map<String, dynamic> json)
      : k = base64Decode(json['k']),
        kStar = base64Decode(json['k_star']);

  Map<String, dynamic> toJson() => {
        'k': base64Encode(k),
        'k_star': base64Encode(kStar),
      };
}
