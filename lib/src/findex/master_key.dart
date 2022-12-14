import 'dart:convert';
import 'dart:typed_data';

class FindexMasterKey {
  Uint8List k;

  FindexMasterKey(this.k);

  FindexMasterKey.fromJson(Map<String, dynamic> json)
      : k = base64Decode(json['k']);

  Map<String, dynamic> toJson() => {
        'k': base64Encode(k),
      };
}
