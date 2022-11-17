import 'dart:typed_data';

import 'ffi.dart';

class CoverCryptDecryption {
  Uint8List asymmetricDecryptionKey;

  CoverCryptDecryption(this.asymmetricDecryptionKey);

  Uint8List decrypt(Uint8List ciphertextBytes) {
    return Ffi.decrypt(asymmetricDecryptionKey, ciphertextBytes);
  }
}
