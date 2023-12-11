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
    log("[uid_value] deserialize: bytes len: ${bytes.length}");
    List<UidAndValue> values = [];
    if (bytes.isEmpty) {
      log("[uid_value] deserialize: bytes empty: returning []");
      return [];
    }
    if (bytes.length == 1) {
      log("[uid_value] deserialize: bytes size equals to 1: returning []");
      return [];
    }

    // Get number of elements in input
    Iterator<int> iterator = bytes.iterator;
    final numItems = Leb128.decodeUnsigned(iterator);
    if (numItems == 0) {
      log("[uid_value] deserialize: number elements is zero: returning []");
      return [];
    }

    log("[uid_value] deserialize: number of elements: $numItems");

    for (int idx = 0; idx < numItems; idx++) {
      log("[uid_value] deserialize: idx: $idx");
      // Get fixed-size UID
      final key = SerDe.copyFromIterator(iterator, uidLength);
      log("[uid_value] deserialize: key: $key");
      // Get value
      final value =
          SerDe.copyFromIterator(iterator, Leb128.decodeUnsigned(iterator));
      log("[uid_value] deserialize: value: $value");

      values.add(UidAndValue(key, value));
    }

    log("[uid_value] deserialize: exiting: number of elements: ${values.length}");
    return values;
  }

  static int serializeToList(Uint8List output, List<UidAndValue> values) {
    log("serializeToList: output.length: ${output.length}");

    // Check if output length is enough
    int totalSize = values.fold(
        0, (int accumulator, UidAndValue uv) => accumulator + uv.size());
    log("serializeList: totalSize: $totalSize");
    if (totalSize > output.length) {
      throw Exception(
          "Unable to serialize: output length (${output.length}) is insufficient, $totalSize bytes needed. Is the number of Entry Table correct?");
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

  static int serialize(Pointer<Uint8> outputPointer,
      Pointer<Uint32> outputLength, List<UidAndValue> values) {
    log("[uid_value] serialize: values len: ${values.length}");
    log("[uid_value] serialize: outputLength: ${outputLength.value}");
    if (outputLength.value == 0) {
      throw Exception("Unable to serialize: output length value is 0");
    }
    log("[uid_value] serialize: outputLength.value: ${outputLength.value}");
    // Check if output length is enough
    int totalSize = values.fold(
        0, (int accumulator, UidAndValue uv) => accumulator + uv.size());
    log("[uid_value] serialize: totalSize: $totalSize");

    if (totalSize == 0) {
      outputLength.value = 1;
      return 0;
    }

    if (totalSize > outputLength.value) {
      // Let us return the required output length
      final length = serializeToList(Uint8List(2 * totalSize), values);
      log("[uid_value] Unable to serialize: output length ${outputLength.value} is insufficient, $length bytes needed. Is the number of Entry Table correct?");
      outputLength.value = length;
      return 1;
    }
    var output = outputPointer.cast<Uint8>().asTypedList(outputLength.value);

    final length = serializeToList(output, values);
    log("[uid_value] serialize: outputLength.value (3): ${outputLength.value}, length: $length, totalSize: $totalSize");
    outputLength.value = length;
    return 0;
  }
}
