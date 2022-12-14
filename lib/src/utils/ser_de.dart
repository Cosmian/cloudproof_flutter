import 'dart:typed_data';

import 'leb128.dart';

/// This class centralizes some functions to serialize/deserialize

class SerDe {
  static int write(Uint8List output, int atIndex, Uint8List input) {
    if (output.length < input.length) {
      throw Exception(
          "SerDe::write: cannot write to vector: insufficient vector length: ${output.length} against ${input.length}");
    }
    output.setAll(atIndex, input);
    atIndex += input.length;
    return atIndex;
  }

  static int writeVector(Uint8List output, int atIndex, Uint8List input) {
    final inputLength = Leb128.encodeUnsigned(input.lengthInBytes);
    if (output.length < inputLength.length + input.length) {
      throw Exception(
          "SerDe::writeVector: cannot write to vector: insufficient vector length: ${output.length} against ${inputLength.length + input.length}");
    }
    output.setAll(atIndex, inputLength);
    atIndex += inputLength.length;
    output.setAll(atIndex, input);
    atIndex += input.length;
    return atIndex;
  }

  static Uint8List copyFromIterator(Iterator<int> iterator, int sizeOfElement) {
    Uint8List output = Uint8List(sizeOfElement);
    for (int j = 0; j < sizeOfElement; j++) {
      if (!iterator.moveNext()) {
        throw Exception("End of Input");
      }
      output[j] = iterator.current;
    }
    return output;
  }
}
