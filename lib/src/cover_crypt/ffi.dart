import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloudproof/src/cover_crypt/clear_text_header.dart';
import 'package:cloudproof/src/cover_crypt/generated_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'metadata.dart';

const errorMessageMaxLength = 3000;
const defaultUidSizeInBytes = 32;
const defaultAdditionalDataSizeInBytes = 32;

class Ffi {
  static NativeLibrary? _library;

  static NativeLibrary get library {
    if (_library != null) {
      return _library as NativeLibrary;
    }

    String? libraryPath;
    if (Platform.isMacOS) {
      libraryPath = path.join(
          Directory.current.path, 'resources', 'libcover_crypt.dylib');
    } else if (Platform.isWindows) {
      libraryPath =
          path.join(Directory.current.path, 'resources', 'libcover_crypt.dll');
    } else if (Platform.isAndroid) {
      libraryPath = "libcover_crypt.so";
    } else if (Platform.isLinux) {
      libraryPath =
          path.join(Directory.current.path, 'resources', 'libcover_crypt.so');
    }

    final library = NativeLibrary(libraryPath == null
        ? DynamicLibrary.process()
        : DynamicLibrary.open(libraryPath));
    _library = library;
    return library;
  }

  static int getEncryptedHeaderSize(Uint8List encryptedData) {
    final encryptedDataPointer =
        encryptedData.allocateInt8Pointer().cast<Char>();

    try {
      return library.h_get_encrypted_header_size(
          encryptedDataPointer.cast<Char>(), encryptedData.lengthInBytes);
    } finally {
      calloc.free(encryptedDataPointer);
    }
  }

  static ClearTextHeader decryptHeader(
    Uint8List asymetricDecryptionKey,
    Uint8List abeHeader, {
    int uidSizeInBytes = defaultUidSizeInBytes,
    int additionalDataSizeInBytes = defaultAdditionalDataSizeInBytes,
  }) {
    final symmetricKeyPointer = calloc<Uint8>(ClearTextHeader.symmetricKeySize);
    final symmetricKeyLength = calloc<Int>(1);
    symmetricKeyLength.value = ClearTextHeader.symmetricKeySize;

    final uidPointer = calloc<Uint8>(uidSizeInBytes);
    final uidLength = calloc<Int>(1);
    uidLength.value = uidSizeInBytes;

    final additionalDataPointer = calloc<Uint8>(additionalDataSizeInBytes);
    final additionalDataLength = calloc<Int>(1);
    additionalDataLength.value = additionalDataSizeInBytes;

    final asymetricDecryptionKeyPointer =
        asymetricDecryptionKey.allocateInt8Pointer().cast<Char>();
    final abeHeaderPointer = abeHeader.allocateInt8Pointer().cast<Char>();

    try {
      final result = library.h_aes_decrypt_header(
        symmetricKeyPointer.cast<Char>(),
        symmetricKeyLength,
        uidPointer.cast<Char>(),
        uidLength,
        additionalDataPointer.cast<Char>(),
        additionalDataLength,
        abeHeaderPointer,
        abeHeader.lengthInBytes,
        asymetricDecryptionKeyPointer,
        asymetricDecryptionKey.lengthInBytes,
      );

      if (result != 0) {
        // If FFI tells us that our buffers are too small, retry
        // with the correct sized buffer.
        if (uidLength.value > uidSizeInBytes ||
            additionalDataLength.value > additionalDataSizeInBytes) {
          return decryptHeader(
            asymetricDecryptionKey,
            abeHeader,
            uidSizeInBytes: uidLength.value,
            additionalDataSizeInBytes: additionalDataLength.value,
          );
        }

        throw Exception(
            "Call to `h_aes_decrypt_header` fail. ${getLastError()}");
      }

      return ClearTextHeader(
        Uint8List.fromList(
            symmetricKeyPointer.asTypedList(symmetricKeyLength.value)),
        Metadata(
          Uint8List.fromList(uidPointer.asTypedList(uidLength.value)),
          Uint8List.fromList(
              additionalDataPointer.asTypedList(additionalDataLength.value)),
        ),
      );
    } finally {
      calloc.free(symmetricKeyPointer);
      calloc.free(symmetricKeyLength);
      calloc.free(uidPointer);
      calloc.free(uidLength);
      calloc.free(additionalDataPointer);
      calloc.free(additionalDataLength);
      calloc.free(asymetricDecryptionKeyPointer);
      calloc.free(abeHeaderPointer);
    }
  }

  static ClearTextHeader decryptHeaderWithCache(
    int cacheHandle,
    Uint8List abeHeader, {
    int uidSizeInBytes = defaultUidSizeInBytes,
    int additionalDataSizeInBytes = defaultAdditionalDataSizeInBytes,
  }) {
    final symmetricKeyPointer = calloc<Uint8>(ClearTextHeader.symmetricKeySize);
    final symmetricKeyLength = calloc<Int>(1);
    symmetricKeyLength.value = ClearTextHeader.symmetricKeySize;

    final uidPointer = calloc<Uint8>(uidSizeInBytes);
    final uidLength = calloc<Int>(1);
    uidLength.value = uidSizeInBytes;

    final additionalDataPointer = calloc<Uint8>(additionalDataSizeInBytes);
    final additionalDataLength = calloc<Int>(1);
    additionalDataLength.value = additionalDataSizeInBytes;

    final abeHeaderPointer = abeHeader.allocateInt8Pointer().cast<Char>();

    try {
      final result = library.h_aes_decrypt_header_using_cache(
        symmetricKeyPointer.cast<Char>(),
        symmetricKeyLength,
        uidPointer.cast<Char>(),
        uidLength,
        additionalDataPointer.cast<Char>(),
        additionalDataLength,
        abeHeaderPointer,
        abeHeader.lengthInBytes,
        cacheHandle,
      );

      if (result != 0) {
        // If FFI tells us that our buffers are too small, retry
        // with the correct sized buffer.
        if (uidLength.value > uidSizeInBytes ||
            additionalDataLength.value > additionalDataSizeInBytes) {
          return decryptHeaderWithCache(
            cacheHandle,
            abeHeader,
            uidSizeInBytes: uidLength.value,
            additionalDataSizeInBytes: additionalDataLength.value,
          );
        }

        throw Exception(
            "Call to `h_aes_decrypt_header` fail. ${getLastError()}");
      }

      return ClearTextHeader(
        Uint8List.fromList(
            symmetricKeyPointer.asTypedList(symmetricKeyLength.value)),
        Metadata(
          Uint8List.fromList(uidPointer.asTypedList(uidLength.value)),
          Uint8List.fromList(
              additionalDataPointer.asTypedList(additionalDataLength.value)),
        ),
      );
    } finally {
      calloc.free(symmetricKeyPointer);
      calloc.free(symmetricKeyLength);
      calloc.free(uidPointer);
      calloc.free(uidLength);
      calloc.free(additionalDataPointer);
      calloc.free(additionalDataLength);
      calloc.free(abeHeaderPointer);
    }
  }

  static Uint8List decryptBlock(Uint8List symmetricKey,
      Uint8List encryptedBytes, Uint8List uid, int blockNumber) {
    final clearTextPointer = calloc<Uint8>(3000);
    final clearTextLength = calloc<Int>(1);
    clearTextLength.value = 3000;

    final symmetricKeyPointer = symmetricKey.allocateInt8Pointer().cast<Char>();
    final uidPointer = uid.allocateInt8Pointer().cast<Char>();
    final encryptedBytesPointer =
        encryptedBytes.allocateInt8Pointer().cast<Char>();

    try {
      final result = library.h_aes_decrypt_block(
          clearTextPointer.cast<Char>(),
          clearTextLength,
          symmetricKeyPointer,
          symmetricKey.lengthInBytes,
          uidPointer,
          uid.lengthInBytes,
          blockNumber,
          encryptedBytesPointer,
          encryptedBytes.lengthInBytes);

      if (result != 0) {
        throw Exception(
            "Call to `h_aes_decrypt_block` fail. ${getLastError()}");
      }

      return Uint8List.fromList(
          clearTextPointer.asTypedList(clearTextLength.value));
    } finally {
      calloc.free(clearTextPointer);
      calloc.free(clearTextLength);
      calloc.free(symmetricKeyPointer);
      calloc.free(uidPointer);
      calloc.free(encryptedBytesPointer);
    }
  }

  static int createDecryptionCache(Uint8List userDecryptionKey) {
    var userDecryptionKeyPointer =
        userDecryptionKey.allocateInt8Pointer().cast<Char>();
    Pointer<Int> cacheHandlePointer = calloc<Int>();

    try {
      int result = library.h_aes_create_decryption_cache(cacheHandlePointer,
          userDecryptionKeyPointer, userDecryptionKey.length);

      if (result != 0) {
        throw Exception("FFI create decryption cache failed");
      }

      return cacheHandlePointer.value;
    } finally {
      calloc.free(cacheHandlePointer);
      calloc.free(userDecryptionKeyPointer);
    }
  }

  static void destroyDecryptionCache(int cacheHandle) {
    int result = library.h_aes_destroy_decryption_cache(cacheHandle);

    if (result != 0) {
      throw Exception("FFI create decryption cache failed");
    }
  }

  static String getLastError() {
    final errorPointer = calloc<Uint8>(errorMessageMaxLength);
    final errorLength = calloc<Int>(1);
    errorLength.value = errorMessageMaxLength;

    try {
      final result =
          library.get_last_error(errorPointer.cast<Char>(), errorLength);

      if (result != 0) {
        return "Fail to fetch last error…";
      } else {
        return const Utf8Decoder()
            .convert(errorPointer.asTypedList(errorLength.value));
      }
    } finally {
      calloc.free(errorPointer);
      calloc.free(errorLength);
    }
  }
}

extension Uint8ListBlobConversion on Uint8List {
  /// Allocates a pointer filled with the Uint8List data.
  Pointer<Int8> allocateInt8Pointer() {
    final blob = calloc<Int8>(length);
    final blobBytes = blob.asTypedList(length);
    blobBytes.setAll(0, this);
    return blob;
  }
}
