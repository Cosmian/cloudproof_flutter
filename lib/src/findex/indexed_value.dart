import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import '../utils/leb128.dart';
import '../utils/ser_de.dart';
import 'keyword.dart';
import 'location.dart';

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
    return deserializeFromIterator(bytes.iterator);
  }

  static List<IndexedValue> deserializeFromIterator(Iterator<int> iterator) {
    log("deserializeFromIterator: start: bytes: $iterator");
    List<IndexedValue> indexedValues = [];

    final length = Leb128.decodeUnsigned(iterator);
    if (length == 0) {
      return [];
    }
    log("deserializeFromIterator: number of element: $length");

    for (int idx = 0; idx < length; idx++) {
      // Get fixed-size UID
      final indexedValue =
          SerDe.copyFromIterator(iterator, Leb128.decodeUnsigned(iterator));
      final iv = IndexedValue(indexedValue);
      if (!indexedValues.contains(iv)) {
        indexedValues.add(iv);
      }
      log("deserializeFromIterator: add element: $indexedValue");
    }
    log("deserializeFromIterator: $indexedValues");

    return indexedValues;
  }
}
