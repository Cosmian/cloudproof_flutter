import 'dart:developer';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:tuple/tuple.dart';

/// Naive [List] equality implementation.
bool listEquals<E>(List<E> list1, List<E> list2) {
  if (identical(list1, list2)) {
    return true;
  }

  if (list1.length != list2.length) {
    return false;
  }

  for (var i = 0; i < list1.length; i += 1) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }

  return true;
}

class UpsertData {
  Map<Uint8List, Tuple2<Uint8List, Uint8List>> map;

  UpsertData(this.map);

  static UpsertData deserialize(
      Uint8List oldValuesBytes, Uint8List newValuesBytes) {
    log("[upsert_data] deserialize: entering");
    UpsertData map = UpsertData({});

    log("[upsert_data] deserialize: oldValuesBytes: $oldValuesBytes");
    final oldValues = UidAndValue.deserialize(oldValuesBytes);
    log("[upsert_data] deserialize: newValuesBytes: $newValuesBytes");
    final newValues = UidAndValue.deserialize(newValuesBytes);

    log("[upsert_data] deserialize: oldValues and newValues deserialized");

    for (UidAndValue newValue in newValues) {
      log("[upsert_data] deserialize: newValue.uid ${newValue.uid}");
      bool optionalValueFound = false;
      for (UidAndValue oldValue in oldValues) {
        log("[upsert_data] newValue.uid: ${newValue.uid}");
        log("[upsert_data] oldValue.uid: ${oldValue.uid}");
        if (listEquals(newValue.uid, oldValue.uid) &&
            oldValue.value.isNotEmpty) {
          log("[upsert_data] MATCH uid: ${newValue.uid}");
          map.map[newValue.uid] = Tuple2(oldValue.value, newValue.value);
          optionalValueFound = true;
          break;
        }
      }
      if (!optionalValueFound) {
        map.map[newValue.uid] = Tuple2(Uint8List(0), newValue.value);
      }
    }
    log("[upsert_data] deserialize: exiting: ${map.map.length}");

    return map;
  }
}
