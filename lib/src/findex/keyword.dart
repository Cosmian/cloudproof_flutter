import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import '../utils/leb128.dart';
import '../utils/ser_de.dart';

class Keyword {
  Uint8List bytes;

  Keyword(this.bytes);

  factory Keyword.fromString(String value) {
    return Keyword(Uint8List.fromList(utf8.encode(value)));
  }

  String toBase64() {
    return base64Encode(bytes);
  }

  static Keyword deserialize(Iterator<int> iterator) {
    log("Keyword::deserialize: start: bytes: $iterator ");

    final length = Leb128.decodeUnsigned(iterator);
    if (length == 0) {
      // return [];
      throw Exception("Unable to deserialize Keyword");
    }

    final keyword = SerDe.copyFromIterator(iterator, length);

    log("Keyword::deserialize: keyword: $keyword ");

    return Keyword(keyword);
  }
}
