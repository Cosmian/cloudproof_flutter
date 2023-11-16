import 'dart:developer';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';

import '../utils/leb128.dart';
import '../utils/ser_de.dart';

class Keywords {
  Set<Keyword> set;

  Keywords(this.set);

  // Get the bound to allocate before serializing
  static int boundSerializedSize(Set<Keyword> set) {
    int size = maxLeb128EncodingSize;
    for (Keyword keyword in set) {
      size += maxLeb128EncodingSize + keyword.bytes.length;
    }

    return size;
  }

  static int serialize(Uint8List output, Set<Keyword> set) {
    log("[keywords] serialize: entering: set length: ${set.length}");
    if (set.isEmpty) {
      return 1;
    }
    //
    // Write: LEB128(number of elements in map)
    //
    final numItems = Leb128.encodeUnsigned(set.length);
    output.setAll(0, numItems);

    var idx = numItems.length;

    for (Keyword keyword in set) {
      //
      // Write: LEB128(size of indexed value) | indexed value
      //
      log("[keywords] serialize: keyword: ${keyword.bytes}");
      idx = SerDe.writeVector(output, idx, keyword.bytes);
    }
    log("[keywords] serialize: exiting: idx: $idx");
    return idx;
  }
}
