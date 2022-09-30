import 'dart:typed_data';

import 'package:cloudproof/src/cover_crypt/clear_text_header.dart';

import 'ffi.dart';

class CoverCryptHybridDecryption {
  Uint8List asymmetricDecryptionKey;

  CoverCryptHybridDecryption(this.asymmetricDecryptionKey);

  ClearTextHeader decryptHybridHeader(Uint8List abeHeader) {
    final ffi = Ffi();
    return ffi.decryptHybridHeader(asymmetricDecryptionKey, abeHeader);
  }

  Uint8List decryptHybridBlock(Uint8List symmetricKey, Uint8List encryptedBytes,
      Uint8List uid, int blockNumber) {
    final ffi = Ffi();
    return ffi.decryptHybridBlock(
        symmetricKey, encryptedBytes, uid, blockNumber);
  }

  Uint8List decrypt(Uint8List encryptedData) {
    final ffi = Ffi();
    final headerSize = ffi.getEncryptedHeaderSize(encryptedData);
    final asymmetricHeader =
        Uint8List.sublistView(encryptedData, 4, 4 + headerSize);

    final encryptedSymmetricBytes =
        Uint8List.sublistView(encryptedData, 4 + headerSize);

    final cleartextHeader = decryptHybridHeader(asymmetricHeader);

    return decryptHybridBlock(cleartextHeader.symmetricKey,
        encryptedSymmetricBytes, cleartextHeader.metadata.uid, 0);
  }

  // public decrypt(encryptedData: Uint8Array): Uint8Array {
  //   logger.log(() => `decrypt for encryptedData: ${encryptedData.toString()}`);

  //   // Encrypted value is composed of: HEADER_LEN | HEADER | AES_DATA
  //   const headerSize = webassembly_get_encrypted_header_size(encryptedData);
  //   const asymmetricHeader = encryptedData.slice(4, 4 + headerSize);
  //   const encryptedSymmetricBytes = encryptedData.slice(
  //     4 + headerSize,
  //     encryptedData.length
  //   );

  //   //
  //   logger.log(() => `decrypt for headerSize: ${headerSize}`);
  //   logger.log(
  //     () => `decrypt for asymmetricHeader: ${asymmetricHeader.toString()}`
  //   );

  //   // HEADER decryption: asymmetric decryption
  //   const cleartextHeader = this.decryptHybridHeader(asymmetricHeader);
  //   logger.log(() => "decrypt for cleartextHeader: " + cleartextHeader);

  //   // AES_DATA: AES Symmetric part decryption
  //   const cleartext = this.decryptHybridBlock(
  //     cleartextHeader.symmetricKey,
  //     encryptedSymmetricBytes,
  //     cleartextHeader.metadata.uid,
  //     0
  //   );
  //   logger.log(() => "cleartext: " + new TextDecoder().decode(cleartext));
  //   return cleartext;
  // }
}
