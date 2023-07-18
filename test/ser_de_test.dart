import 'dart:ffi';
import 'dart:typed_data';

import 'package:cloudproof/src/findex/uid_and_value.dart';
import 'package:cloudproof/src/findex/upsert_data.dart';
import 'package:cloudproof/src/utils/leb128.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UpsertData', () {
    final bytes = Uint8List.fromList([9, 9, 9, 9]);
    UpsertData upsertData = UpsertData(Uint8List(32), bytes, bytes);
    List<UpsertData> upsertDataList = [];
    upsertDataList.add(upsertData);

    final output = Uint8List(43);
    UpsertData.serialize(output, upsertDataList);
    final expectedSerialized = Uint8List.fromList([1]) +
        Uint8List(32) +
        Uint8List.fromList([4, 9, 9, 9, 9, 4, 9, 9, 9, 9]);
    expect(output, equals(expectedSerialized));

    List<UpsertData> deserialized = UpsertData.deserialize(output);
    final deserializedUpsertData = deserialized[0];
    expect(deserializedUpsertData.uid, upsertData.uid);
    expect(deserializedUpsertData.oldValue, upsertData.oldValue);
    expect(deserializedUpsertData.newValue, upsertData.newValue);
  });

  test('UidAndValue', () {
    final bytes = Uint8List.fromList([9, 9, 9, 9]);
    UidAndValue indexTable = UidAndValue(Uint8List(32), bytes);
    List<UidAndValue> indexTableList = [];
    indexTableList.add(indexTable);

    // final output = Uint8List(43);
    const expectedOutputLength = 38;
    final outputPointer = calloc<Uint8>(43);
    final outputLength = calloc<Uint32>(1);
    outputLength.value = 43;

    UidAndValue.serialize(outputPointer, outputLength, indexTableList);
    expect(outputLength.value, expectedOutputLength);
    final output = outputPointer.cast<Uint8>().asTypedList(outputLength.value);
    final expectedSerialized = Uint8List.fromList([1]) +
        Uint8List(32) +
        Uint8List.fromList([4, 9, 9, 9, 9]);
    expect(output, equals(expectedSerialized));

    List<UidAndValue> deserialized = UidAndValue.deserialize(output);
    final deserializedIndexTable = deserialized[0];
    expect(deserializedIndexTable.uid, indexTable.uid);
    expect(deserializedIndexTable.value, indexTable.value);

    calloc.free(outputPointer);
    calloc.free(outputLength);
  });

  test('Leb128', () {
    final encodedSize = Leb128.encodeUnsigned(8);
    final decodedBytes = Leb128.decodeUnsigned(encodedSize.iterator);
    expect(encodedSize, Uint8List.fromList([8]));
    expect(decodedBytes, 8);
  });
}
