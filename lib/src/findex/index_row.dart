import 'dart:developer';
import 'dart:ffi';
import 'dart:typed_data';

import '../utils/leb128.dart';
import '../utils/ser_de.dart';
import 'findex.dart';

class IndexRow {
  Uint8List uid;
  Uint8List value;

  IndexRow(this.uid, this.value);

  static List<IndexRow> deserialize(Uint8List bytes) {
    List<IndexRow> values = [];

    // Get number of elements in input
    Iterator<int> iterator = bytes.iterator;
    final numItems = Leb128.decodeUnsigned(iterator);
    if (numItems == 0) {
      return [];
    }

    for (int idx = 0; idx < numItems; idx++) {
      // Get fixed-size UID
      final key = SerDe.copyFromIterator(iterator, uidLength);
      // Get value
      final value =
          SerDe.copyFromIterator(iterator, Leb128.decodeUnsigned(iterator));

      values.add(IndexRow(key, value));
    }

    return values;
  }

  static int serializeToList(Uint8List output, List<IndexRow> values) {
    log("serialize: output: $output");
    if (output.isEmpty) {
      throw Exception("Unable to serialize: output length value is 0");
    }
    try {
      final numItems = Leb128.encodeUnsigned(values.length);
      output.setAll(0, numItems);

      var idx = numItems.length;
      for (var entry in values) {
        idx = SerDe.write(output, idx, entry.uid);
        idx = SerDe.writeVector(output, idx, entry.value);
      }

      return idx;
    } catch (e, stacktrace) {
      log("Exception during IndexRow serialize $e $stacktrace");
      return 0;
    }
  }

  static int serialize(Pointer<UnsignedChar> outputPointer,
      Pointer<UnsignedInt> outputLength, List<IndexRow> values) {
    if (outputLength.value == 0) {
      throw Exception("Unable to serialize: output length value is 0");
    }
    var output = outputPointer.cast<Uint8>().asTypedList(outputLength.value);

    final length = serializeToList(output, values);
    outputLength.value = length;
    return length;
  }
}
