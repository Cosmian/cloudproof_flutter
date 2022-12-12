import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Directory, Platform;
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:cloudproof/src/findex/generated_bindings.dart';
import 'package:cloudproof/src/utils/blob_conversion.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

const findexErrorMessageMaxLength = 3000;
const defaultOutputSizeInBytes = 131072;
const errorCodeInCaseOfCallbackException = 42;
const uidLength = 32;

class Findex {
  static FindexNativeLibrary? _library;

  static FindexNativeLibrary get library {
    if (_library != null) {
      return _library as FindexNativeLibrary;
    }

    String? libraryPath;
    if (Platform.isMacOS) {
      libraryPath = path.join(
          Directory.current.path, 'resources', 'libcosmian_findex.dylib');
    } else if (Platform.isWindows) {
      libraryPath = path.join(
          Directory.current.path, 'resources', 'libcosmian_findex.dll');
    } else if (Platform.isAndroid) {
      libraryPath = "libcosmian_findex.so";
    } else if (Platform.isLinux) {
      libraryPath = path.join(
          Directory.current.path, 'resources', 'libcosmian_findex.so');
    }

    final library = FindexNativeLibrary(libraryPath == null
        ? DynamicLibrary.process()
        : DynamicLibrary.open(libraryPath));
    _library = library;
    return library;
  }

  //
  // Callbacks implementations
  //
  static bool progressCallback(
    Pointer<Uint8> uidsListPointer,
    int uidsListLength,
  ) {
    return true;
  }

  //
  // FFI functions
  //
  static Future<void> upsert(
    FindexMasterKey masterKey,
    Uint8List label,
    Map<IndexedValue, List<Keyword>> indexedValuesAndKeywords,
    FetchEntryTableCallback fetchEntries,
    UpsertEntryTableCallback upsertEntries,
    InsertChainTableCallback upsertChains,
  ) async {
    //
    // FFI INPUT parameters
    //
    // Master key
    final Pointer<Int> masterKeyPointer =
        masterKey.k.allocateInt8Pointer().cast<Int>();

    // Label
    final labelPointer = label.allocateUint8Pointer();

    // Data to index to encode in base64 and JSON
    final Pointer<Utf8> indexedValuesAndKeywordsPointer = jsonEncode(
            indexedValuesAndKeywords.map((key, value) => MapEntry(
                key.toBase64(), value.map((e) => e.toBase64()).toList())))
        .toNativeUtf8(allocator: malloc);

    try {
      final result = library.h_upsert(
        masterKeyPointer,
        masterKey.k.length,
        labelPointer.cast<Int>(),
        label.length,
        indexedValuesAndKeywordsPointer.cast<Char>(),
        fetchEntries,
        upsertEntries,
        upsertChains,
      );

      if (result != 0) {
        throw Exception("Fail to upsert: ${getLastError()}");
      }
    } finally {
      calloc.free(labelPointer);
      malloc.free(indexedValuesAndKeywordsPointer);
    }
  }

  static Future<List<IndexedValue>> search(
      Uint8List k,
      Uint8List label,
      List<Keyword> keywords,
      FetchEntryTableCallback fetchEntries,
      FetchChainTableCallback fetchChains,
      {int outputSizeInBytes = defaultOutputSizeInBytes}) async {
    //
    // FFI INPUT parameters
    //
    final kPointer = k.allocateUint8Pointer();
    final labelPointer = label.allocateUint8Pointer();
    final Pointer<Utf8> keywordsPointer =
        jsonEncode(keywords.map((value) => value.toBase64()).toList())
            .toNativeUtf8();

    //
    // FFI OUTPUT parameters
    //
    final output = calloc<Uint8>(outputSizeInBytes);
    final outputLengthPointer = calloc<Int32>(1);
    outputLengthPointer.value = outputSizeInBytes;

    try {
      final result = library.h_search(
        output.cast<Char>(),
        outputLengthPointer.cast<Int>(),
        kPointer.cast<Char>(),
        k.length,
        labelPointer.cast<Int>(),
        label.length,
        keywordsPointer.cast<Char>(),
        0,
        0,
        0, // Progress callback is not used for now.
        fetchEntries,
        fetchChains,
      );

      if (result != 0) {
        // If Rust tells us that our buffer is too small for the search results
        // retry with the correct buffer size.
        if (outputLengthPointer.value > outputSizeInBytes) {
          return search(k, label, keywords, fetchEntries, fetchChains,
              outputSizeInBytes: outputLengthPointer.value);
        }
        throw Exception("Fail to search ${getLastError()}");
      }
      return IndexedValue.deserialize(
          output.asTypedList(outputLengthPointer.value));
    } finally {
      calloc.free(output);
      calloc.free(outputLengthPointer);
      malloc.free(keywordsPointer);
      calloc.free(kPointer);
      calloc.free(labelPointer);
    }
  }

  static String getLastError() {
    final errorPointer = calloc<Uint8>(findexErrorMessageMaxLength);
    final errorLength = calloc<Int>(1);
    errorLength.value = findexErrorMessageMaxLength;

    try {
      final result =
          library.get_last_error(errorPointer.cast<Char>(), errorLength);

      if (result != 0) {
        return "Fail to fetch last error…";
      } else {
        final message = const Utf8Decoder()
            .convert(errorPointer.asTypedList(errorLength.value));

        return message;
      }
    } finally {
      calloc.free(errorPointer);
      calloc.free(errorLength);
    }
  }
}

extension Uint8ListBlobConversion on Uint8List {
  /// Allocates a pointer filled with the Uint8List data.
  Pointer<Uint8> allocateUint8Pointer() {
    final blob = calloc<Uint8>(length);
    final blobBytes = blob.asTypedList(length);
    blobBytes.setAll(0, this);
    return blob;
  }
}
