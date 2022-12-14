import 'dart:developer';
import 'dart:typed_data';

import '../utils/leb128.dart';
import '../utils/ser_de.dart';
import 'findex.dart';

class UpsertData {
  Uint8List uid;
  Uint8List oldValue;
  Uint8List newValue;

  UpsertData(this.uid, this.oldValue, this.newValue);

  static List<UpsertData> deserialize(Uint8List bytes) {
    List<UpsertData> values = [];

    // Get number of elements in input
    Iterator<int> iterator = bytes.iterator;
    final numItems = Leb128.decodeUnsigned(iterator);
    log("upsertData: deserialize: contains $numItems items");
    if (numItems == 0) {
      return values;
    }

    for (int idx = 0; idx < numItems; idx++) {
      log("upsertData: deserialize: round $idx");
      // Get fixed-size UID
      final key = SerDe.copyFromIterator(iterator, uidLength);

      // Get old value
      final oldValue =
          SerDe.copyFromIterator(iterator, Leb128.decodeUnsigned(iterator));

      var length = Leb128.decodeUnsigned(iterator);
      if (length == 0) {
        throw Exception("Expecting `new value` after a `old value`");
      }

      // Get old value
      final newValue = SerDe.copyFromIterator(iterator, length);

      values.add(UpsertData(key, oldValue, newValue));
    }

    return values;
  }

  static void serialize(Uint8List output, List<UpsertData> values) {
    log("upsertData: serialize: values.entries: $values \net output: $output");
    //TODO: check output size

    final numItems = Leb128.encodeUnsigned(values.length);
    output.setAll(0, numItems);
    log("upsertData: serialize: output: $output");

    var idx = numItems.length;
    for (var entry in values) {
      idx = SerDe.write(output, idx, entry.uid);
      idx = SerDe.writeVector(output, idx, entry.oldValue);
      idx = SerDe.writeVector(output, idx, entry.newValue);
    }

    // output.setAll(0, [0]);
    // output = Uint8List.sublistView(output, 1);
    log("upsertData: serialize: output: $output");
  }
}
