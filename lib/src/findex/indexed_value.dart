import 'dart:convert';
import 'dart:typed_data';

class Word {
  Uint8List bytes;

  Word(this.bytes);

  factory Word.fromString(String value) {
    return Word(Uint8List.fromList(utf8.encode(value)));
  }

  String toBase64() {
    return base64Encode(bytes);
  }
}

class Location {
  Uint8List bytes;

  Location(this.bytes);
}

class IndexedValue {
  static const lPrefix = 108;
  static const wPrefix = 119;

  Uint8List bytes;

  IndexedValue(this.bytes) {
    if (bytes.first != lPrefix && bytes.first != wPrefix) {
      throw Exception("`IndexedValue` must be prefixed by 'l' or 'w' in byte");
    }
  }

  factory IndexedValue.fromLocation(Location location) {
    return IndexedValue(
        Uint8List.fromList(Uint8List.fromList([lPrefix]) + location.bytes));
  }

  factory IndexedValue.fromWord(Word word) {
    return IndexedValue(
        Uint8List.fromList(Uint8List.fromList([wPrefix]) + word.bytes));
  }

  Location get location {
    if (bytes.first == lPrefix) {
      return Location(bytes.sublist(1));
    }

    throw Exception("`IndexedValue` is not a `Location`");
  }

  Word get word {
    if (bytes.first == wPrefix) {
      return Word(bytes.sublist(1));
    }

    throw Exception("`IndexedValue` is not a `Word`");
  }

  String toBase64() {
    return base64Encode(bytes);
  }
}
