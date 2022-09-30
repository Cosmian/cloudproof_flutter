import 'dart:typed_data';

/// This class contains static methods you can use to encode and decode
/// integers that follow LEB128 compression format.
class Leb128 {
  static int decodeUnsigned(Iterator<int> bytes) {
    int result = 0;
    int cur;
    int count = 0;

    do {
      if (!bytes.moveNext()) {
        throw Exception("End of Input");
      }
      cur = bytes.current & 0xff;
      result |= (cur & 0x7f) << (count * 7);
      count++;
    } while (((cur & 0x80) == 0x80) && count < 5);

    if ((cur & 0x80) == 0x80) {
      throw Exception("invalid LEB128 sequence");
    }

    return result;
  }

  static Uint8List encodeUnsigned(Uint8List output, int value) {
    if (value < 0) {
      throw Exception(
          "value $value should always be positive because Dart 2.10 doesn't support `>>>` (`>>` and `>>>` are the same for positive numbers)");
    }
    int remaining = value >> 7;

    int position = 0;
    while (remaining != 0) {
      output[position] = ((value & 0x7f) | 0x80);
      position++;
      value = remaining;
      remaining >>= 7;
    }

    output[position] = (value & 0x7f);
    position++;

    return Uint8List.sublistView(output, position);
  }

  static List<Uint8List> deserializeList(Uint8List bytes) {
    List<Uint8List> values = [];

    Iterator<int> iterator = bytes.iterator;
    var length = 0;
    while ((length = Leb128.decodeUnsigned(iterator)) >= 0) {
      if (length == 0) {
        break;
      }

      Uint8List element = Uint8List(length);
      for (int i = 0; i < length; i++) {
        if (!iterator.moveNext()) {
          throw Exception("End of Input");
        }
        element[i] = iterator.current;
      }

      values.add(element);
    }

    return values;
  }

  static void serializeHashMap(
      Uint8List output, Map<Uint8List, Uint8List> values) {
    for (var entry in values.entries) {
      output = Leb128.encodeUnsigned(output, entry.key.lengthInBytes);
      output.setAll(0, entry.key);

      output = Uint8List.sublistView(output, entry.key.lengthInBytes);

      output = Leb128.encodeUnsigned(output, entry.value.lengthInBytes);
      output.setAll(0, entry.value);

      output = Uint8List.sublistView(output, entry.value.lengthInBytes);
    }

    output.setAll(0, [0]);
    output = Uint8List.sublistView(output, 1);
  }

  static Map<Uint8List, Uint8List> deserializeHashMap(Uint8List bytes) {
    Map<Uint8List, Uint8List> values = {};

    Iterator<int> iterator = bytes.iterator;
    var length = 0;
    while ((length = Leb128.decodeUnsigned(iterator)) >= 0) {
      if (length == 0) {
        break;
      }

      Uint8List key = Uint8List(length);
      for (int i = 0; i < length; i++) {
        if (!iterator.moveNext()) {
          throw Exception("End of Input");
        }
        key[i] = iterator.current;
      }

      length = Leb128.decodeUnsigned(iterator);
      if (length == 0) {
        throw Exception("Expecting `value` after a `key`");
      }

      Uint8List value = Uint8List(length);
      for (int i = 0; i < length; i++) {
        if (!iterator.moveNext()) {
          throw Exception("End of Input");
        }
        value[i] = iterator.current;
      }

      values[key] = value;
    }

    return values;
  }
}
