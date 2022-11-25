import 'dart:typed_data';

import 'cleartext_header.dart';
import 'ffi.dart';

class CoverCryptDecryption {
  Uint8List asymmetricDecryptionKey;

  CoverCryptDecryption(this.asymmetricDecryptionKey);

  CleartextHeader decryptWithAuthenticationData(
      Uint8List ciphertextBytes, Uint8List authenticationData) {
    return Ffi.decryptWithAuthenticationData(
        asymmetricDecryptionKey, ciphertextBytes, authenticationData);
  }

  CleartextHeader decrypt(Uint8List ciphertextBytes) {
    return Ffi.decrypt(asymmetricDecryptionKey, ciphertextBytes);
  }
}
