import 'dart:typed_data';

import 'package:cloudproof/src/cover_crypt/clear_text_header.dart';

import 'ffi.dart';

class CoverCryptDecryption {
  Uint8List asymmetricDecryptionKey;

  CoverCryptDecryption(this.asymmetricDecryptionKey);

  ClearTextHeader decryptHeader(Uint8List abeHeader) {
    return Ffi.decryptHeader(asymmetricDecryptionKey, abeHeader);
  }

  Uint8List decryptBlock(Uint8List symmetricKey, Uint8List encryptedBytes,
      Uint8List uid, int blockNumber) {
    return Ffi.decryptBlock(symmetricKey, encryptedBytes, uid, blockNumber);
  }

  Uint8List decrypt(Uint8List encryptedData) {
    final headerSize = Ffi.getEncryptedHeaderSize(encryptedData);
    final asymmetricHeader =
        Uint8List.sublistView(encryptedData, 4, 4 + headerSize);

    final encryptedSymmetricBytes =
        Uint8List.sublistView(encryptedData, 4 + headerSize);

    final cleartextHeader = decryptHeader(asymmetricHeader);

    return decryptBlock(cleartextHeader.symmetricKey, encryptedSymmetricBytes,
        cleartextHeader.metadata.uid, 0);
  }
}

class CoverCryptDecryptionWithCache extends CoverCryptDecryption {
  late int cacheHandle;

  CoverCryptDecryptionWithCache(super.asymmetricDecryptionKey) {
    cacheHandle = Ffi.createDecryptionCache(asymmetricDecryptionKey);
  }

  void destroyDecryptionCache() {
    Ffi.destroyDecryptionCache(cacheHandle);
  }

  @override
  ClearTextHeader decryptHeader(Uint8List abeHeader) {
    return Ffi.decryptHeaderWithCache(cacheHandle, abeHeader);
  }
}
