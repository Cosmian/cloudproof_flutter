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

class Location {
  late Uint8List bytes;

  Location(this.bytes);

  /// Numbers are encoded in big-endian 8 bytes.
  Location.fromNumber(int number) {
    final bytes = ByteData(8);
    bytes.setInt64(0, number, Endian.big);

    this.bytes = bytes.buffer.asUint8List();
  }

  /// Numbers are encoded in big-endian 8 bytes.
  int get number {
    if (bytes.length != 8) {
      throw Exception(
        "The location is of length ${bytes.length}, 8 bytes expected for a number.",
      );
    }

    return bytes.buffer.asByteData().getInt64(0, Endian.big);
  }

  static List<Location> deserialize(Uint8List bytes) {
    return deserializeFromIterator(bytes.iterator);
  }

  static List<Location> deserializeFromIterator(Iterator<int> iterator) {
    log("deserializeFromIterator: start: bytes: $iterator");
    List<Location> locations = [];

    final length = Leb128.decodeUnsigned(iterator);
    if (length == 0) {
      return [];
    }
    log("deserializeFromIterator: number of element: $length");

    for (int idx = 0; idx < length; idx++) {
      // Get fixed-size UID
      final locationBytes =
          SerDe.copyFromIterator(iterator, Leb128.decodeUnsigned(iterator));
      final location = Location(locationBytes);
      if (!locations.contains(location)) {
        locations.add(location);
      }
      log("deserializeFromIterator: add element: $locationBytes");
    }
    log("deserializeFromIterator: $locations");

    return locations;
  }
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
