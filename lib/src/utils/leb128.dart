import 'dart:typed_data';

const maxLeb128EncodingSize = 8;

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

  static Uint8List encodeUnsigned(int value) {
    if (value < 0) {
      throw Exception(
          "value $value should always be positive because Dart 2.10 doesn't support `>>>` (`>>` and `>>>` are the same for positive numbers)");
    }
    int remaining = value >> 7;

    var output = Uint8List(8); // 8 being the maximum len
    int position = 0;
    while (remaining != 0) {
      output[position] = ((value & 0x7f) | 0x80);
      position++;
      value = remaining;
      remaining >>= 7;
    }

    output[position] = (value & 0x7f);
    position++;
    output = output.sublist(0, position);
    return output;
  }
}
