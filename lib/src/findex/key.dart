import 'dart:convert';
import 'dart:typed_data';

class FindexKey {
  Uint8List key;

  FindexKey(this.key);

  FindexKey.fromJson(Map<String, dynamic> json) : key = base64Decode(json['k']);

  Map<String, dynamic> toJson() => {
        'k': base64Encode(key),
      };
}
