import 'dart:developer';
import 'dart:typed_data';

import '../utils/leb128.dart';
import '../utils/ser_de.dart';

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

  static Set<Location> deserialize(Uint8List bytes) {
    return deserializeFromIterator(bytes.iterator);
  }

  static Set<Location> deserializeFromIterator(Iterator<int> iterator) {
    log("deserializeFromIterator: start: bytes: $iterator");
    Set<Location> locations = {};

    final length = Leb128.decodeUnsigned(iterator);
    if (length == 0) {
      return {};
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
