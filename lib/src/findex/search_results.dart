import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';

import '../utils/leb128.dart';

class SearchResults {
  static Map<Keyword, Set<Location>> deserialize(Uint8List bytes) {
    if (bytes.isEmpty) {
      return {};
    }
    Map<Keyword, Set<Location>> result = {};
    Iterator<int> iterator = bytes.iterator;
    final length = Leb128.decodeUnsigned(iterator);
    if (length == 0) {
      return {};
    }

    for (int idx = 0; idx < length; idx++) {
      // Get Keyword
      final keyword = Keyword.deserialize(iterator);
      if (keyword.bytes.isNotEmpty) {
        // Get corresponding list of Location
        final locations = Location.deserializeFromIterator(iterator);

        result[keyword] = locations;
      }
    }

    return result;
  }
}
