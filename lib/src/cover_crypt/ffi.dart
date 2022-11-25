import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/src/cover_crypt/generated_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'cleartext_header.dart';

const errorMessageMaxLength = 3000;
const defaultHeaderMetadataSizeInBytes = 4096;

class Ffi {
  static NativeLibrary? _library;

  static NativeLibrary get library {
    if (_library != null) {
      return _library as NativeLibrary;
    }

    String? libraryPath;
    if (Platform.isMacOS) {
      libraryPath = path.join(
          Directory.current.path, 'resources', 'libcosmian_cover_crypt.dylib');
    } else if (Platform.isWindows) {
      libraryPath = path.join(
          Directory.current.path, 'resources', 'libcosmian_cover_crypt.dll');
    } else if (Platform.isAndroid) {
      libraryPath = "libcosmian_cover_crypt.so";
    } else if (Platform.isLinux) {
      libraryPath = path.join(
          Directory.current.path, 'resources', 'libcosmian_cover_crypt.so');
    }

    final library = NativeLibrary(libraryPath == null
        ? DynamicLibrary.process()
        : DynamicLibrary.open(libraryPath));
    _library = library;
    return library;
  }

  static CleartextHeader decryptWithAuthenticationData(
      Uint8List asymmetricDecryptionKey,
      Uint8List ciphertextBytes,
      Uint8List authenticationDataBytes) {
    final cleartextPointer = calloc<Uint8>(ciphertextBytes.length);
    final cleartextLength = calloc<Int>(1);
    cleartextLength.value = ciphertextBytes.length;

    final headerMetadataPointer =
        calloc<Uint8>(defaultHeaderMetadataSizeInBytes);
    final headerMetadataLength = calloc<Int>(1);
    headerMetadataLength.value = defaultHeaderMetadataSizeInBytes;

    final ciphertextPointer =
        ciphertextBytes.allocateInt8Pointer().cast<Char>();

    final authenticationDataPointer =
        authenticationDataBytes.allocateInt8Pointer().cast<Char>();

    final asymmetricDecryptionKeyPointer =
        asymmetricDecryptionKey.allocateInt8Pointer().cast<Char>();

    try {
      final result = library.h_aes_decrypt(
          cleartextPointer.cast<Char>(),
          cleartextLength,
          headerMetadataPointer.cast<Char>(),
          headerMetadataLength,
          ciphertextPointer,
          ciphertextBytes.length,
          authenticationDataPointer,
          authenticationDataBytes.length,
          asymmetricDecryptionKeyPointer,
          asymmetricDecryptionKey.length);
      if (result != 0) {
        throw Exception("Call to `h_aes_decrypt` fail. ${getLastError()}");
      }

      final cleartext = CleartextHeader(
        Uint8List.fromList(cleartextPointer.asTypedList(cleartextLength.value)),
        Uint8List.fromList(
            headerMetadataPointer.asTypedList(headerMetadataLength.value)),
      );
      return cleartext;
    } finally {
      calloc.free(cleartextPointer);
      calloc.free(cleartextLength);
      calloc.free(headerMetadataPointer);
      calloc.free(headerMetadataLength);
      calloc.free(authenticationDataPointer);
    }
  }

  static CleartextHeader decrypt(
      Uint8List asymmetricDecryptionKey, Uint8List ciphertextBytes) {
    return decryptWithAuthenticationData(
        asymmetricDecryptionKey, ciphertextBytes, Uint8List.fromList([]));
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
