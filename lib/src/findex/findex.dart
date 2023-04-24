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

class ExceptionThrown {
  DateTime datetime;
  Object e;
  StackTrace stacktrace;

  ExceptionThrown(this.datetime, this.e, this.stacktrace);
}

class Findex {
  static List<ExceptionThrown> exceptions = [];
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
      final start = DateTime.now();
      final errorCode = library.h_upsert(
        masterKeyPointer,
        masterKey.k.length,
        labelPointer.cast<Int>(),
        label.length,
        indexedValuesAndKeywordsPointer.cast<Char>(),
        fetchEntries,
        upsertEntries,
        insertChains,
      );
      final end = DateTime.now();

      await throwOnErrorCode(errorCode, start, end);
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
    FetchChainTableCallback fetchChains, {
    int outputSizeInBytes = defaultOutputSizeInBytes,
    int insecureFetchChainsBatchSize = 0,
  }) async {
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
      final start = DateTime.now();
      final errorCode = library.h_search(
        output.cast<Char>(),
        outputLengthPointer.cast<Int>(),
        kPointer.cast<Char>(),
        k.length,
        labelPointer.cast<Int>(),
        label.length,
        keywordsPointer.cast<Char>(),
        0,
        0,
        insecureFetchChainsBatchSize,
        0, // Progress callback is not used for now.
        fetchEntries,
        fetchChains,
      );
      final end = DateTime.now();

      if (errorCode != 0 && outputLengthPointer.value > outputSizeInBytes) {
        return search(k, label, keywords, fetchEntries, fetchChains,
            outputSizeInBytes: outputLengthPointer.value);
      }

      await throwOnErrorCode(errorCode, start, end);

      return deserializeSearchResults(
        output.asTypedList(outputLengthPointer.value),
      );
    } finally {
      calloc.free(output);
      calloc.free(outputLengthPointer);
      malloc.free(keywordsPointer);
      calloc.free(kPointer);
      calloc.free(labelPointer);
    }
  }

  static Future<void> throwOnErrorCode(
    int errorCode,
    DateTime start,
    DateTime end,
  ) async {
    if (errorCode == 0) return;

    // Allow to give back the hand to the event loop to allow
    // the Isolate error port listeners to run and put exceptions
    // inside the Findex.exceptions array.
    await Future.delayed(const Duration(milliseconds: 10));

    final exceptions = Findex.exceptions.where((element) =>
        element.datetime.isAfter(start) && element.datetime.isBefore(end));

    if (exceptions.isNotEmpty) {
      // We currently only rethrow the first exception but if multiple exceptions are thrown during this
      // FFI call maybe we should give this information to the user.
      // Multiple exceptions can be thrown if there is multiple concurrent request.

      // In async callback wrapper the error code is not `errorCodeInCaseOfCallbackException`
      // because the exception is happening inside an isolate and not reported back to the
      // real callback that spawn the isolate. So the real callback return 0 (everything is fine)
      // and the Rust part is failing because the data from inside the pointer is wrong.
      // We need to report the user exception in this case but maybe the exception is from somewhere
      // else / has nothing to do with the current problem. In this case we still rethrow the user exception because
      // there is 99% of chance that this is the problem. But we log the Rust error for completeness.
      if (errorCode != errorCodeInCaseOfCallbackException) {
        log("An exception occurred during the callback but the errorCode was $errorCode but we expect $errorCodeInCaseOfCallbackException if a user exception happen inside a callback. The Rust error was: ${getLastError()} (it may be something unrelated or the real error). While using async wrapper this is the normal behavior because user exceptions do not return the correct error code.");
      }

      Error.throwWithStackTrace(
        exceptions.first.e,
        exceptions.first.stacktrace,
      );
    }

    throw FindexException(getLastError());
  }

  static ReceivePort isolateErrorPort() {
    final now = DateTime.now();
    final errorPort = ReceivePort();
    errorPort.listen((messages) {
      final e = AsyncCallbackExceptionWrapper(messages[0]);
      Findex.exceptions
          .add(ExceptionThrown(now, e, StackTrace.fromString(messages[1])));
    });

    return errorPort;
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
        onError: Findex.isolateErrorPort().sendPort,
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
        onError: Findex.isolateErrorPort().sendPort,
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
          } finally {
            Pointer<Bool>.fromAddress(message.item2).value = true;
          }
        },
        Tuple2(
          chainsListPointer.address,
          donePointer.address,
        ),
        onError: Findex.isolateErrorPort().sendPort,
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
      Findex.exceptions.add(ExceptionThrown(DateTime.now(), e, stacktrace));
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
      Findex.exceptions.add(ExceptionThrown(DateTime.now(), e, stacktrace));
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
      Findex.exceptions.add(ExceptionThrown(DateTime.now(), e, stacktrace));
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

class AsyncCallbackExceptionWrapper implements Exception {
  String message;

  AsyncCallbackExceptionWrapper(this.message);

  @override
  String toString() {
    return message;
  }
}

class FindexException implements Exception {
  String message;

  FindexException(this.message);

  @override
  String toString() {
    return message;
  }
}
