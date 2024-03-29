// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloudproof/src/generated_bindings.dart';
import 'package:cloudproof/src/utils/blob_conversion.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import '../../cloudproof.dart';

const coverCryptErrorMessageMaxLength = 3000;
const defaultHeaderMetadataSizeInBytes = 4096;

class CoverCrypt {
  static CloudproofNativeLibrary? _library;

  static CloudproofNativeLibrary get library {
    if (_library != null) {
      return _library as CloudproofNativeLibrary;
    }

    String? libraryPath;
    if (Platform.isMacOS) {
      libraryPath =
          path.join(Directory.current.path, 'resources', 'libcloudproof.dylib');
    } else if (Platform.isWindows) {
      libraryPath =
          path.join(Directory.current.path, 'resources', 'cloudproof.dll');
    } else if (Platform.isAndroid) {
      libraryPath = "libcloudproof.so";
    } else if (Platform.isLinux) {
      libraryPath =
          path.join(Directory.current.path, 'resources', 'libcloudproof.so');
    }

    final library = CloudproofNativeLibrary(libraryPath == null
        ? DynamicLibrary.process()
        : DynamicLibrary.open(libraryPath));
    _library = library;
    return library;
  }

  //
  // DECRYPTION via FFI
  //
  static PlaintextHeader decryptWithAuthenticationData(Uint8List userSecretKey,
      Uint8List ciphertext, Uint8List authenticationData) {
    // FFI INPUT parameters
    final authenticationDataPointer = authenticationData.allocateInt8Pointer();
    final userSecretKeyPointer = userSecretKey.allocateInt8Pointer();
    final ciphertextPointer = ciphertext.allocateInt8Pointer();

    // FFI OUTPUT parameters
    final plaintextPointer = calloc<Int8>(ciphertext.length);
    final plaintextLength = calloc<Int32>(1);
    plaintextLength.value = ciphertext.length;
    final headerMetadataPointer =
        calloc<Int8>(defaultHeaderMetadataSizeInBytes);
    final headerMetadataLength = calloc<Int32>(1);
    headerMetadataLength.value = defaultHeaderMetadataSizeInBytes;

    try {
      final result = library.h_hybrid_decrypt(
          plaintextPointer,
          plaintextLength,
          headerMetadataPointer,
          headerMetadataLength,
          ciphertextPointer,
          ciphertext.length,
          authenticationDataPointer,
          authenticationData.length,
          userSecretKeyPointer,
          userSecretKey.length);
      if (result != 0) {
        throw Exception("Call to `h_hybrid_decrypt` fail. ${getLastError()}");
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
      Policy policy,
      Uint8List publicKey,
      String encryptionPolicy,
      Uint8List plaintext,
      Uint8List headerMetaData,
      Uint8List authenticationData) {
    // FFI INPUT parameters
    final policyPointer = policy.toBytes().allocateInt8Pointer();
    final encryptionPolicyPointer =
        encryptionPolicy.toNativeUtf8().cast<Int8>();
    final publicKeyPointer = publicKey.allocateInt8Pointer();
    final plaintextPointer = plaintext.allocateInt8Pointer();
    final headerMetaDataPointer = headerMetaData.allocateInt8Pointer();
    final authenticationDataPointer = authenticationData.allocateInt8Pointer();

    // FFI OUTPUT parameters
    final ciphertextPointer = calloc<Int8>(8192 + plaintext.length);
    final ciphertextLength = calloc<Int32>(1);
    ciphertextLength.value = 8192 + plaintext.length;

    try {
      final result = library.h_hybrid_encrypt(
          ciphertextPointer.cast<Int8>(),
          ciphertextLength,
          policyPointer,
          policy.toBytes().length,
          publicKeyPointer,
          publicKey.length,
          encryptionPolicyPointer,
          plaintextPointer,
          plaintext.length,
          headerMetaDataPointer,
          headerMetaData.length,
          authenticationDataPointer,
          authenticationData.length);
      if (result != 0) {
        throw Exception("Call to `h_hybrid_encrypt` fail. ${getLastError()}");
      }

      final ciphertext = Uint8List.fromList(
          ciphertextPointer.asTypedList(ciphertextLength.value));
      return ciphertext;
    } finally {
      calloc.free(policyPointer);
      calloc.free(ciphertextPointer);
      calloc.free(ciphertextLength);
      calloc.free(publicKeyPointer);
      calloc.free(plaintextPointer);
      calloc.free(headerMetaDataPointer);
      calloc.free(authenticationDataPointer);
    }
  }

  static Uint8List encrypt(Policy policy, Uint8List publicKey,
      String encryptionPolicy, Uint8List plaintext) {
    return encryptWithAuthenticationData(policy, publicKey, encryptionPolicy,
        plaintext, Uint8List.fromList([]), Uint8List.fromList([]));
  }

  static String getLastError() {
    final errorPointer = calloc<Int8>(coverCryptErrorMessageMaxLength);
    final errorLength = calloc<Int32>(1);
    errorLength.value = coverCryptErrorMessageMaxLength;

    try {
      final result = library.h_get_error(errorPointer, errorLength);

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

  static CoverCryptMasterKeys generateMasterKeys(Policy policy) {
    // FFI INPUT parameters
    final policyPointer = policy.toBytes().allocateInt8Pointer();

    // FFI OUTPUT parameters
    const arbitraryLargeSize = 8192;
    final masterSecretKeyPointer = calloc<Int8>(arbitraryLargeSize);
    final masterSecretKeyLength = calloc<Int32>(1);
    masterSecretKeyLength.value = arbitraryLargeSize;
    final masterPublicKeyPointer = calloc<Int8>(arbitraryLargeSize);
    final masterPublicKeyLength = calloc<Int32>(1);
    masterPublicKeyLength.value = arbitraryLargeSize;

    try {
      final result = library.h_generate_master_keys(
          masterSecretKeyPointer,
          masterSecretKeyLength,
          masterPublicKeyPointer,
          masterPublicKeyLength,
          policyPointer,
          policy.toBytes().length);
      if (result != 0) {
        throw Exception(
            "Call to `h_generate_master_keys` fail. ${getLastError()}");
      }

      return CoverCryptMasterKeys.create(
        Uint8List.fromList(
            masterSecretKeyPointer.asTypedList(masterSecretKeyLength.value)),
        Uint8List.fromList(
            masterPublicKeyPointer.asTypedList(masterPublicKeyLength.value)),
      );
    } finally {
      calloc.free(policyPointer);
      calloc.free(masterSecretKeyPointer);
      calloc.free(masterSecretKeyLength);
      calloc.free(masterPublicKeyPointer);
      calloc.free(masterPublicKeyLength);
    }
  }

  static Uint8List generateUserSecretKey(
      String booleanAccessPolicy, Policy policy, Uint8List masterSecretKey) {
    // FFI INPUT parameters
    final accessPolicyPointer = booleanAccessPolicy.toNativeUtf8().cast<Int8>();
    final policyPointer = policy.toBytes().allocateInt8Pointer();

    final masterSecretKeyPointer = masterSecretKey.allocateInt8Pointer();

    // FFI OUTPUT parameters
    final userPrivateKeyPointer = calloc<Int8>(8192);
    final userPrivateKeyLength = calloc<Int32>(1);
    userPrivateKeyLength.value = 8192;

    try {
      final result = library.h_generate_user_secret_key(
          userPrivateKeyPointer,
          userPrivateKeyLength,
          masterSecretKeyPointer,
          masterSecretKey.length,
          accessPolicyPointer,
          policyPointer,
          policy.toBytes().length);
      if (result != 0) {
        throw Exception(
            "Call to `h_generate_user_secret_key` fail. ${getLastError()}");
      }

      return Uint8List.fromList(
          userPrivateKeyPointer.asTypedList(userPrivateKeyLength.value));
    } finally {
      calloc.free(userPrivateKeyPointer);
      calloc.free(userPrivateKeyLength);
      calloc.free(policyPointer);
      calloc.free(accessPolicyPointer);
      calloc.free(masterSecretKeyPointer);
    }
  }

  static Uint8List generatePolicy() {
    // FFI OUTPUT parameters
    const arbitraryLargeSize = 8192;
    final policyPointer = calloc<Int8>(arbitraryLargeSize);
    final policyLength = calloc<Int32>(1);
    policyLength.value = arbitraryLargeSize;

    try {
      final result = library.h_policy(policyPointer, policyLength);
      if (result != 0) {
        throw Exception("Call to `h_policy` fail. ${getLastError()}");
      }

      return Uint8List.fromList(policyPointer.asTypedList(policyLength.value));
    } finally {
      calloc.free(policyPointer);
      calloc.free(policyLength);
    }
  }

  static Uint8List addPolicyAxis(Policy currentPolicy, PolicyAxis axis) {
    // FFI INPUT parameters
    final currentPolicyPointer = currentPolicy.toBytes().allocateInt8Pointer();
    final axisPointer = axis.toString().toNativeUtf8();

    // FFI OUTPUT parameters
    const arbitraryLargeSize = 8192;
    final outputPolicyPointer = calloc<Int8>(arbitraryLargeSize);
    final outputPolicyLength = calloc<Int32>(1);
    outputPolicyLength.value = arbitraryLargeSize;

    try {
      final result = library.h_add_policy_axis(
        outputPolicyPointer.cast<Int8>(),
        outputPolicyLength,
        currentPolicyPointer,
        currentPolicy.toBytes().length,
        axisPointer.cast<Int8>(),
      );
      if (result != 0) {
        throw Exception("Call to `h_add_policy_axis` fail. ${getLastError()}");
      }

      return Uint8List.fromList(
          outputPolicyPointer.asTypedList(outputPolicyLength.value));
    } finally {
      calloc.free(outputPolicyPointer);
      calloc.free(outputPolicyLength);
      calloc.free(currentPolicyPointer);
      calloc.free(axisPointer);
    }
  }
}
