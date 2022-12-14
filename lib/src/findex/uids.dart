import 'dart:developer';
import 'dart:typed_data';

import '../utils/leb128.dart';
import '../utils/ser_de.dart';
import 'findex.dart';

class Uids {
  late List<Uint8List> uids;

  Uids() : uids = [];

  static Uids deserialize(Uint8List bytes) {
    log("Uids: start");
    Uids values = Uids();

    Iterator<int> iterator = bytes.iterator;

    final length = Leb128.decodeUnsigned(iterator);
    if (length == 0) {
      return Uids();
    }

    for (int idx = 0; idx < length; idx++) {
      // Get fixed-size UID
      final uid = SerDe.copyFromIterator(iterator, uidLength);
      log("Uids: add element: $uid");
      values.uids.add(uid);
    }
    log("Uids: $values");

    return values;
  }
}
