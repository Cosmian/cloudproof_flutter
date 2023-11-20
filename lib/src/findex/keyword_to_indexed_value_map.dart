import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';

import '../utils/leb128.dart';

class KeywordToIndexedValueMap {
  static Map<Keyword, List<IndexedValue>> deserialize(Uint8List bytes) {
    Map<Keyword, List<IndexedValue>> result = {};

    Iterator<int> iterator = bytes.iterator;
    final length = Leb128.decodeUnsigned(iterator);
    if (length == 0) {
      return {};
    }

    for (int idx = 0; idx < length; idx++) {
      // Get Keyword
      final keyword = Keyword.deserialize(iterator);

      // Get corresponding list of IndexedValues
      final indexedValues = IndexedValue.deserializeFromIterator(iterator);

      result[keyword] = indexedValues;
    }

    return result;
  }
}
