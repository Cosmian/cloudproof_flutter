import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/src/cover_crypt/generated_bindings.dart';
import 'package:cloudproof/src/utils/blob_conversion.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'plaintext_header.dart';

const coverCryptErrorMessageMaxLength = 3000;
const defaultHeaderMetadataSizeInBytes = 4096;

class CoverCrypt {
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

  //
  // DECRYPTION via FFI
  //
  static PlaintextHeader decryptWithAuthenticationData(Uint8List userSecretKey,
      Uint8List ciphertextBytes, Uint8List authenticationDataBytes) {
    // FFI INPUT parameters
    final authenticationDataPointer =
        authenticationDataBytes.allocateInt8Pointer().cast<Char>();
    final userSecretKeyPointer =
        userSecretKey.allocateInt8Pointer().cast<Char>();
    final ciphertextPointer =
        ciphertextBytes.allocateInt8Pointer().cast<Char>();

    // FFI OUTPUT parameters
    final plaintextPointer = calloc<Uint8>(ciphertextBytes.length);
    final plaintextLength = calloc<Int>(1);
    plaintextLength.value = ciphertextBytes.length;
    final headerMetadataPointer =
        calloc<Uint8>(defaultHeaderMetadataSizeInBytes);
    final headerMetadataLength = calloc<Int>(1);
    headerMetadataLength.value = defaultHeaderMetadataSizeInBytes;

    try {
      final result = library.h_aes_decrypt(
          plaintextPointer.cast<Char>(),
          plaintextLength,
          headerMetadataPointer.cast<Char>(),
          headerMetadataLength,
          ciphertextPointer,
          ciphertextBytes.length,
          authenticationDataPointer,
          authenticationDataBytes.length,
          userSecretKeyPointer,
          userSecretKey.length);
      if (result != 0) {
        throw Exception("Call to `h_aes_decrypt` fail. ${getLastError()}");
      }

      final plaintext = PlaintextHeader(
        Uint8List.fromList(plaintextPointer.asTypedList(plaintextLength.value)),
        Uint8List.fromList(
            headerMetadataPointer.asTypedList(headerMetadataLength.value)),
      );
      return plaintext;
    } finally {
      calloc.free(plaintextPointer);
      calloc.free(plaintextLength);
      calloc.free(headerMetadataPointer);
      calloc.free(headerMetadataLength);
      calloc.free(authenticationDataPointer);
    }
  }

  static PlaintextHeader decrypt(
      Uint8List asymmetricDecryptionKey, Uint8List ciphertextBytes) {
    return decryptWithAuthenticationData(
        asymmetricDecryptionKey, ciphertextBytes, Uint8List.fromList([]));
  }

  //
  // ENCRYPTION via FFI
  //
  static Uint8List encryptWithAuthenticationData(
      String policy,
      Uint8List publicKey,
      String encryptionPolicy,
      Uint8List plaintextBytes,
      Uint8List additionalData,
      Uint8List authenticationData) {
    // FFI INPUT parameters
    final policyPointer = policy.toNativeUtf8().cast<Char>();
    final encryptionPolicyPointer =
        encryptionPolicy.toNativeUtf8().cast<Char>();
    final publicKeyPointer = publicKey.allocateInt8Pointer().cast<Char>();
    final plaintextPointer = plaintextBytes.allocateInt8Pointer().cast<Char>();
    final additionalDataPointer =
        additionalData.allocateInt8Pointer().cast<Char>();
    final authenticationDataPointer =
        authenticationData.allocateInt8Pointer().cast<Char>();

    // FFI OUTPUT parameters
    final ciphertextPointer = calloc<Uint8>(8192 + plaintextBytes.length);
    final ciphertextLength = calloc<Int>(1);
    ciphertextLength.value = plaintextBytes.length;

    try {
      final result = library.h_aes_encrypt(
          ciphertextPointer.cast<Char>(),
          ciphertextLength,
          policyPointer,
          publicKeyPointer,
          publicKey.length,
          encryptionPolicyPointer,
          plaintextPointer,
          plaintextBytes.length,
          additionalDataPointer,
          additionalData.length,
          authenticationDataPointer,
          authenticationData.length);
      if (result != 0) {
        throw Exception("Call to `h_aes_encrypt` fail. ${getLastError()}");
      }

      final ciphertext = Uint8List.fromList(
          ciphertextPointer.asTypedList(ciphertextLength.value));
      return ciphertext;
    } finally {
      calloc.free(ciphertextPointer);
      calloc.free(ciphertextLength);
      calloc.free(publicKeyPointer);
      calloc.free(plaintextPointer);
      calloc.free(additionalDataPointer);
      calloc.free(authenticationDataPointer);
    }
  }

  static Uint8List encrypt(String policy, Uint8List publicKey,
      String encryptionPolicy, Uint8List plaintextBytes) {
    return encryptWithAuthenticationData(policy, publicKey, encryptionPolicy,
        plaintextBytes, Uint8List.fromList([]), Uint8List.fromList([]));
  }

  static String getLastError() {
    final errorPointer = calloc<Uint8>(coverCryptErrorMessageMaxLength);
    final errorLength = calloc<Int>(1);
    errorLength.value = coverCryptErrorMessageMaxLength;

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

  // static Uint8List generateMasterKeys(String policy){
  //   Ffi
  // }
}
