import 'dart:typed_data';

import 'package:cloudproof/src/cover_crypt/clear_text_header.dart';

import 'ffi.dart';

class CoverCryptDecryption {
  Uint8List asymmetricDecryptionKey;

  CoverCryptDecryption(this.asymmetricDecryptionKey);

  ClearTextHeader decryptHeader(Uint8List abeHeader) {
    final ffi = Ffi();
    return ffi.decryptHeader(asymmetricDecryptionKey, abeHeader);
  }

  Uint8List decryptBlock(Uint8List symmetricKey, Uint8List encryptedBytes,
      Uint8List uid, int blockNumber) {
    final ffi = Ffi();
    return ffi.decryptBlock(symmetricKey, encryptedBytes, uid, blockNumber);
  }

  Uint8List decrypt(Uint8List encryptedData) {
    final ffi = Ffi();
    final headerSize = ffi.getEncryptedHeaderSize(encryptedData);
    final asymmetricHeader =
        Uint8List.sublistView(encryptedData, 4, 4 + headerSize);

    final encryptedSymmetricBytes =
        Uint8List.sublistView(encryptedData, 4 + headerSize);

    final cleartextHeader = decryptHeader(asymmetricHeader);

    return decryptBlock(cleartextHeader.symmetricKey, encryptedSymmetricBytes,
        cleartextHeader.metadata.uid, 0);
  }
}

class CoverCryptDecryptionWithCache {
  late int cacheHandle;

  CoverCryptDecryptionWithCache(Uint8List asymmetricDecryptionKey) {
    final ffi = Ffi();
    cacheHandle = ffi.createDecryptionCache(asymmetricDecryptionKey);
  }

  void destroyDecryptionCache() {
    final ffi = Ffi();
    ffi.destroyDecryptionCache(cacheHandle);
  }

  ClearTextHeader decryptHeader(Uint8List abeHeader) {
    final ffi = Ffi();
    return ffi.decryptHeaderWithCache(cacheHandle, abeHeader);
  }

  Uint8List decryptBlock(Uint8List symmetricKey, Uint8List encryptedBytes,
      Uint8List uid, int blockNumber) {
    final ffi = Ffi();
    return ffi.decryptBlock(symmetricKey, encryptedBytes, uid, blockNumber);
  }

  Uint8List decrypt(Uint8List encryptedData) {
    final ffi = Ffi();
    final headerSize = ffi.getEncryptedHeaderSize(encryptedData);
    final asymmetricHeader =
        Uint8List.sublistView(encryptedData, 4, 4 + headerSize);

    final encryptedSymmetricBytes =
        Uint8List.sublistView(encryptedData, 4 + headerSize);

    final cleartextHeader = decryptHeader(asymmetricHeader);

    return decryptBlock(cleartextHeader.symmetricKey, encryptedSymmetricBytes,
        cleartextHeader.metadata.uid, 0);
  }
}
