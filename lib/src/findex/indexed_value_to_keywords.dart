import 'dart:developer';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';

import '../utils/leb128.dart';
import '../utils/ser_de.dart';

class IndexedValueToKeywordsMap {
  Map<IndexedValue, Set<Keyword>> map;
  IndexedValueToKeywordsMap(this.map);

  // Get the bound to allocate before serializing
  static int boundSerializedSize(Map<IndexedValue, Set<Keyword>> map) {
    int size = maxLeb128EncodingSize;
    for (MapEntry<IndexedValue, Set<Keyword>> entry in map.entries) {
      size += maxLeb128EncodingSize + entry.key.bytes.length;
      for (Keyword keyword in entry.value) {
        size += maxLeb128EncodingSize + keyword.bytes.length;
      }
    }

    return size;
  }

  static int serialize(Uint8List output, Map<IndexedValue, Set<Keyword>> map) {
    log("[iv_to_keywords] serialize: entering");
    if (map.isEmpty) {
      return 1;
    }
    //
    // Write: LEB128(number of elements in map)
    //
    final numItems = Leb128.encodeUnsigned(map.length);
    output.setAll(0, numItems);

    var idx = numItems.length;

    for (MapEntry<IndexedValue, Set<Keyword>> entry in map.entries) {
      //
      // Write: LEB128(size of indexed value) | indexed value
      //
      log("[iv_to_keywords] serialize: iv: ${entry.key.bytes}");
      idx = SerDe.writeVector(output, idx, entry.key.bytes);

      //
      // Write: LEB128(nb of keywords) | LEB128(size of keyword) | keyword | ...
      //
      final numKeywords = Leb128.encodeUnsigned(entry.value.length);
      idx = SerDe.write(output, idx, numKeywords);
      log("[iv_to_keywords] serialize: numKeywords $numKeywords");
      int keywordsCount = 0;
      for (Keyword keyword in entry.value) {
        idx = SerDe.writeVector(output, idx, keyword.bytes);
        keywordsCount++;
        log("[iv_to_keywords] serialize: keyword OK: $keywordsCount");
      }
    }
    log("[iv_to_keywords] serialize: exiting: idx: $idx");
    return idx;
  }
}
