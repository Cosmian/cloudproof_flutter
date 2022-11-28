import 'dart:typed_data';

import 'ffi.dart';
import 'plaintext_header.dart';

class CoverCryptDecryption {
  Uint8List asymmetricDecryptionKey;

  CoverCryptDecryption(this.asymmetricDecryptionKey);

  PlaintextHeader decryptWithAuthenticationData(
      Uint8List ciphertextBytes, Uint8List authenticationData) {
    return Ffi.decryptWithAuthenticationData(
        asymmetricDecryptionKey, ciphertextBytes, authenticationData);
  }

  PlaintextHeader decrypt(Uint8List ciphertextBytes) {
    return Ffi.decrypt(asymmetricDecryptionKey, ciphertextBytes);
  }
}
