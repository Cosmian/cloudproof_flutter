import 'dart:developer';
import 'dart:ffi';
import 'dart:typed_data';

import '../utils/leb128.dart';
import '../utils/ser_de.dart';
import 'findex.dart';

class UidAndValue {
  Uint8List uid;
  Uint8List value;

  UidAndValue(this.uid, this.value) {
    if (uid.lengthInBytes != 32) {
      throw FindexException(
        "`uid` should be of length 32. Actual length is ${uid.lengthInBytes} bytes.",
      );
    }
  }

  int size() {
    return uid.length + value.length;
  }

  static List<UidAndValue> deserialize(Uint8List bytes) {
    List<UidAndValue> values = [];

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

      values.add(UidAndValue(key, value));
    }

    return values;
  }

  static int serializeToList(Uint8List output, List<UidAndValue> values) {
    log("serializeToList: output.length: ${output.length}");

    // Check if output length is enough
    int totalSize = values.fold(
        0, (int accumulator, UidAndValue uv) => accumulator + uv.size());
    log("serializeList: totalSize: $totalSize");
    if (totalSize > output.length) {
      log("Unable to serialize: output length (${output.length}) is insufficient, $totalSize bytes needed. Is the number of Entry Table correct?");
      return 1;
    }

    try {
      log("serializeToList: values.length: ${values.length}");
      final numItems = Leb128.encodeUnsigned(values.length);
      output.setAll(0, numItems);

      var idx = numItems.length;
      for (var entry in values) {
        log("serializeToList: entry.uid.length: ${entry.uid.length} + ${entry.value.length}");
        idx = SerDe.write(output, idx, entry.uid);
        idx = SerDe.writeVector(output, idx, entry.value);
      }

      return idx;
    } catch (e, stacktrace) {
      log("Exception during UidAndValue serialize $e $stacktrace");
      return 0;
    }
  }

  static int serialize(Pointer<UnsignedChar> outputPointer,
      Pointer<UnsignedInt> outputLength, List<UidAndValue> values) {
    if (outputLength.value == 0) {
      throw Exception("Unable to serialize: output length value is 0");
    }
    log("serialize: outputLength.value: ${outputLength.value}");
    // Check if output length is enough
    int totalSize = values.fold(
        0, (int accumulator, UidAndValue uv) => accumulator + uv.size());
    log("serialize: totalSize: $totalSize");

    if (totalSize == 0) {
      outputLength.value = 1;
      return 0;
    }

    if (totalSize > outputLength.value) {
      // Let us return the required output length
      final length = serializeToList(Uint8List(2 * totalSize), values);
      log("Unable to serialize: output length ${outputLength.value} is insufficient, $length bytes needed. Is the number of Entry Table correct?");
      outputLength.value = length;
      return 1;
    }
    var output = outputPointer.cast<Uint8>().asTypedList(outputLength.value);

    final length = serializeToList(output, values);
    log("serialize: outputLength.value (3): ${outputLength.value}, length: $length, totalSize: $totalSize");
    outputLength.value = length;
    return 0;
  }
}
