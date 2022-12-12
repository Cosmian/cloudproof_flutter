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
    log("IndexedValue: this.bytes: $bytes");
    if (bytes.first != lPrefix && bytes.first != wPrefix) {
      throw Exception("`IndexedValue` must be prefixed by 'l' or 'w' in byte");
    }
  }

  factory IndexedValue.fromLocation(Location location) {
    return IndexedValue(
        Uint8List.fromList(Uint8List.fromList([lPrefix]) + location.bytes));
  }

  factory IndexedValue.fromWord(Keyword word) {
    return IndexedValue(
        Uint8List.fromList(Uint8List.fromList([wPrefix]) + word.bytes));
  }

  Location get location {
    if (bytes.first == lPrefix) {
      return Location(bytes.sublist(1));
    }

    throw Exception("`IndexedValue` is not a `Location`");
  }

  Keyword get word {
    if (bytes.first == wPrefix) {
      return Keyword(bytes.sublist(1));
    }

    throw Exception("`IndexedValue` is not a `Word`");
  }

  String toBase64() {
    return base64Encode(bytes);
  }

  static List<IndexedValue> deserialize(Uint8List bytes) {
    log("deserializeList: start: bytes: $bytes");
    List<IndexedValue> indexedValues = [];

    Iterator<int> iterator = bytes.iterator;
    final length = Leb128.decodeUnsigned(iterator);
    if (length == 0) {
      return [];
    }

    for (int idx = 0; idx < length; idx++) {
      // Get fixed-size UID
      final indexedValue =
          SerDe.copyFromIterator(iterator, Leb128.decodeUnsigned(iterator));
      final iv = IndexedValue(indexedValue);
      if (!indexedValues.contains(iv)) {
        indexedValues.add(iv);
      }
      log("deserialize: add element: $indexedValue");
    }
    log("deserialize: $indexedValues");

    return indexedValues;
  }
}
