import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io' show Directory, Platform, sleep;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:cloudproof/src/findex/generated_bindings.dart';
import 'package:cloudproof/src/utils/blob_conversion.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'package:tuple/tuple.dart';

import '../utils/leb128.dart';

const findexErrorMessageMaxLength = 3000;
const defaultOutputSizeInBytes = 131072;
const errorCodeInCaseOfCallbackException = 42;
const uidLength = 32;

class Findex {
  static FindexNativeLibrary? cachedLibrary;

  static FindexNativeLibrary get library {
    if (cachedLibrary != null) {
      return cachedLibrary as FindexNativeLibrary;
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
    cachedLibrary = library;
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
    InsertChainTableCallback insertChains,
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
        insertChains,
      );

      if (result != 0) {
        throw Exception("Fail to upsert: ${getLastError()}");
      }
    } finally {
      calloc.free(labelPointer);
      malloc.free(indexedValuesAndKeywordsPointer);
    }
  }

  static Future<Map<Keyword, List<IndexedValue>>> search(
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
      return deserializeSearchResults(
          output.asTypedList(outputLengthPointer.value));
    } finally {
      calloc.free(output);
      calloc.free(outputLengthPointer);
      malloc.free(keywordsPointer);
      calloc.free(kPointer);
      calloc.free(labelPointer);
    }
  }

  static Map<Keyword, List<IndexedValue>> deserializeSearchResults(
      Uint8List bytes) {
    Map<Keyword, List<IndexedValue>> result = {};

    Iterator<int> iterator = bytes.iterator;
    final length = Leb128.decodeUnsigned(iterator);
    if (length == 0) {
      return {};
    }

    for (int idx = 0; idx < length; idx++) {
      // Get Keyword
      final keyword = Keyword.deserialize(iterator);

      // Get corresponding list of IndexedValue
      final indexedValues = IndexedValue.deserializeFromIterator(iterator);

      result[keyword] = indexedValues;
    }

    return result;
  }

  static String getLastError() {
    final errorPointer = calloc<Uint8>(findexErrorMessageMaxLength);
    final errorLength = calloc<Int>(1);
    errorLength.value = findexErrorMessageMaxLength;

    try {
      final result =
          library.get_last_error(errorPointer.cast<Char>(), errorLength);

      if (result != 0) {
        return "Fail to fetch last error???";
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

  static int wrapAsyncFetchCallback(
    Future<List<UidAndValue>> Function(Uids uids) callback,
    Pointer<UnsignedChar> outputEntryTableLinesPointer,
    Pointer<UnsignedInt> outputEntryTableLinesLength,
    Pointer<UnsignedChar> uidsPointer,
    int uidsNumber,
  ) {
    final donePointer = calloc<Bool>(1);
    donePointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            final inputArray = Pointer<Uint8>.fromAddress(message.item3)
                .asTypedList(uidsNumber);

            final uids = Uids.deserialize(inputArray);
            final entryTableLines = await callback(uids);

            UidAndValue.serialize(
                Pointer<UnsignedChar>.fromAddress(message.item1),
                Pointer<UnsignedInt>.fromAddress(message.item2),
                entryTableLines);
          } catch (e) {
            log("Excepting in fetch isolate. $e");
          } finally {
            Pointer<Bool>.fromAddress(message.item4).value = true;
          }
        },
        Tuple4(
          outputEntryTableLinesPointer.address,
          outputEntryTableLinesLength.address,
          uidsPointer.address,
          donePointer.address,
        ),
      );
      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }
      return 0;
    } catch (e, stacktrace) {
      log("Exception during fetch callback ($callback) $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
    }
  }

  static int wrapAsyncUpsertEntriesCallback(
    Future<List<UidAndValue>> Function(List<UpsertData>) callback,
    Pointer<UnsignedChar> outputRejectedEntriesListPointer,
    Pointer<UnsignedInt> outputRejectedEntriesListLength,
    Pointer<UnsignedChar> entriesListPointer,
    int entriesListLength,
  ) {
    final donePointer = calloc<Bool>(1);
    donePointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            final inputArray = Pointer<Uint8>.fromAddress(message.item1)
                .asTypedList(entriesListLength);

            final uidsAndValues = UpsertData.deserialize(inputArray);

            final rejectedEntries = await callback(uidsAndValues);

            UidAndValue.serialize(
                Pointer<UnsignedChar>.fromAddress(message.item4),
                Pointer<UnsignedInt>.fromAddress(message.item3),
                rejectedEntries);
          } catch (e) {
            log("Excepting in upsert isolate. $e");
          } finally {
            Pointer<Bool>.fromAddress(message.item4).value = true;
          }
        },
        Tuple4(
          entriesListPointer.address,
          outputRejectedEntriesListPointer.address,
          outputRejectedEntriesListLength.address,
          donePointer.address,
        ),
      );

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }
      return 0;
    } catch (e, stacktrace) {
      log("Exception during upsertEntriesCallback $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
    }
  }

  static int wrapAsyncInsertChainsCallback(
    Future<void> Function(List<UidAndValue>) callback,
    Pointer<UnsignedChar> chainsListPointer,
    int chainsListLength,
  ) {
    final donePointer = calloc<Bool>(1);
    donePointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            final inputArray = Pointer<Uint8>.fromAddress(message.item1)
                .asTypedList(chainsListLength);

            final uidsAndValues = UidAndValue.deserialize(inputArray);

            await callback(uidsAndValues);
          } catch (e) {
            log("Excepting in upsert isolate. $e");
          } finally {
            Pointer<Bool>.fromAddress(message.item2).value = true;
          }
        },
        Tuple2(
          chainsListPointer.address,
          donePointer.address,
        ),
      );

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }
      return 0;
    } catch (e, stacktrace) {
      log("Exception during insertChainsCallback $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
    }
  }

  static int wrapSyncFetchCallback(
    List<UidAndValue> Function(Uids uids) callback,
    Pointer<UnsignedChar> outputEntryTableLinesPointer,
    Pointer<UnsignedInt> outputEntryTableLinesLength,
    Pointer<UnsignedChar> uidsPointer,
    int uidsNumber,
  ) {
    try {
      final uids =
          Uids.deserialize(uidsPointer.cast<Uint8>().asTypedList(uidsNumber));
      final entryTableLines = callback(uids);
      UidAndValue.serialize(outputEntryTableLinesPointer.cast<UnsignedChar>(),
          outputEntryTableLinesLength, entryTableLines);
      return 0;
    } catch (e, stacktrace) {
      log("Exception during fetch callback ($callback) $e $stacktrace");
      rethrow;
    }
  }

  static int wrapSyncUpsertEntriesCallback(
    List<UidAndValue> Function(List<UpsertData>) callback,
    Pointer<UnsignedChar> outputRejectedEntriesListPointer,
    Pointer<UnsignedInt> outputRejectedEntriesListLength,
    Pointer<UnsignedChar> entriesListPointer,
    int entriesListLength,
  ) {
    try {
      // Deserialize uids and values
      final uidsAndValues = UpsertData.deserialize(
          entriesListPointer.cast<Uint8>().asTypedList(entriesListLength));

      final rejectedEntries = callback(uidsAndValues);
      UidAndValue.serialize(outputRejectedEntriesListPointer,
          outputRejectedEntriesListLength, rejectedEntries);
      return 0;
    } catch (e, stacktrace) {
      log("Exception during upsertEntriesCallback $e $stacktrace");
      rethrow;
    }
  }

  static int wrapSyncInsertChainsCallback(
    void Function(List<UidAndValue>) callback,
    Pointer<UnsignedChar> chainsListPointer,
    int chainsListLength,
  ) {
    try {
      final uidsAndValues = UidAndValue.deserialize(
          chainsListPointer.cast<Uint8>().asTypedList(chainsListLength));

      callback(uidsAndValues);
      return 0;
    } catch (e, stacktrace) {
      log("Exception during insertChainsCallback $e $stacktrace");
      rethrow;
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
