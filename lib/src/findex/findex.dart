import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io' show Directory, Platform, sleep;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:cloudproof/src/generated_bindings.dart';
import 'package:cloudproof/src/utils/blob_conversion.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'package:tuple/tuple.dart';

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
  static CloudproofNativeLibrary? cachedLibrary;
  static int? _handle;

  static CloudproofNativeLibrary get library {
    if (cachedLibrary != null) {
      return cachedLibrary as CloudproofNativeLibrary;
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
    cachedLibrary = library;
    return library;
  }

  //
  // Callbacks implementations
  //
  static int defaultInterruptCallback(
    Pointer<Uint8> uidsListPointer,
    int uidsListLength,
  ) {
    return 0;
  }

  //
  // FFI functions
  //
  static int instantiateFindex(
      FindexKey key,
      String label,
      Fetch fetchEntries,
      Fetch fetchChains,
      Upsert upsertEntries,
      Insert insertEntries,
      Insert insertChains,
      Delete deleteEntries,
      Delete deleteChains,
      DumpTokens dumpTokens,
      {int entryTableNumber = 1}) {
    //
    // FFI INPUT parameters
    //
    // Master key
    final Pointer<Uint8> findexKeyPointer =
        key.key.allocateInt8Pointer().cast<Uint8>();

    // Label
    final labelPointer = label.toNativeUtf8().cast<Int8>();

    //
    // FII OUTPUT
    //
    final findexHandlePointer = calloc<Int32>(1);

    try {
      final errorCode = library.h_instantiate_with_custom_interface(
          findexHandlePointer,
          findexKeyPointer,
          key.key.length,
          labelPointer,
          entryTableNumber,
          fetchEntries,
          fetchChains,
          upsertEntries,
          insertEntries,
          insertChains,
          deleteEntries,
          deleteChains,
          dumpTokens);
      if (errorCode != 0) {
        throw FindexException(getLastError());
      }
      _handle = findexHandlePointer.value;
      return findexHandlePointer.value;
    } finally {
      calloc.free(findexHandlePointer);
      calloc.free(findexKeyPointer);
    }
  }

  static Future<Set<Keyword>> add(Map<IndexedValue, Set<Keyword>> associations,
      {int outputSizeInBytes = 0, int findexHandle = -1}) async {
    //
    // FFI INPUT parameters
    //

    // Serialize data to index
    log("add: associations len: ${associations.length}");
    final associationsBytes =
        Uint8List(IndexedValueToKeywordsMap.boundSerializedSize(associations));
    final associationsSerializedSize =
        IndexedValueToKeywordsMap.serialize(associationsBytes, associations);
    final associationsPointer = associationsBytes.allocateUint8Pointer();
    log("add: serialization associations OK: $associationsSerializedSize");

    log("add: associations len: ${associationsBytes.length}");

    //
    // FFI OUTPUT parameters
    //
    final output = calloc<Uint8>(outputSizeInBytes);
    final outputLengthPointer = calloc<Int32>(1);
    outputLengthPointer.value = outputSizeInBytes;

    final handle = findexHandle == -1 ? _handle! : findexHandle;
    log("add: handle: $handle");
    try {
      final start = DateTime.now();
      log("add with: outputLengthPointer.value: ${outputLengthPointer.value}");
      final errorCode = library.h_add(
        output,
        outputLengthPointer,
        handle,
        associationsPointer,
        associationsSerializedSize,
      );
      final end = DateTime.now();

      if (errorCode != 1) {
        await throwOnErrorCode(errorCode, start, end);
      }
      if (outputSizeInBytes == 0 &&
          errorCode == 1 &&
          outputLengthPointer.value > 0) {
        log("retrying: outputSizeInBytes == 0, outputLengthPointer.value: ${outputLengthPointer.value}");

        return add(associations,
            outputSizeInBytes: outputLengthPointer.value, findexHandle: handle);
      }
      log("add: exiting");
      if (outputSizeInBytes != 0 && errorCode == 0) {
        return Keywords.deserialize(
          output.asTypedList(outputLengthPointer.value),
        );
      }

      return {};
    } finally {
      calloc.free(output);
      calloc.free(outputLengthPointer);
      malloc.free(associationsPointer);
    }
  }

  static Future<Set<Keyword>> delete(
      Map<IndexedValue, Set<Keyword>> associations,
      {int outputSizeInBytes = 0,
      int findexHandle = -1}) async {
    //
    // FFI INPUT parameters
    //

    // Serialize data to index
    log("delete: associations len: ${associations.length}");
    final associationsBytes =
        Uint8List(IndexedValueToKeywordsMap.boundSerializedSize(associations));
    final associationsSerializedSize =
        IndexedValueToKeywordsMap.serialize(associationsBytes, associations);
    final associationsPointer = associationsBytes.allocateUint8Pointer();
    log("delete: serialization associations OK: $associationsSerializedSize");

    log("delete: associations len: ${associationsBytes.length}");

    //
    // FFI OUTPUT parameters
    //
    final output = calloc<Uint8>(outputSizeInBytes);
    final outputLengthPointer = calloc<Int32>(1);
    outputLengthPointer.value = outputSizeInBytes;

    try {
      final start = DateTime.now();
      log("delete with: outputLengthPointer.value: ${outputLengthPointer.value}");
      final errorCode = library.h_delete(
        output,
        outputLengthPointer,
        findexHandle == -1 ? _handle! : findexHandle,
        associationsPointer,
        associationsSerializedSize,
      );
      final end = DateTime.now();

      if (errorCode != 1) {
        await throwOnErrorCode(errorCode, start, end);
      }
      if (outputSizeInBytes == 0 &&
          errorCode == 1 &&
          outputLengthPointer.value > 0) {
        log("retrying: outputSizeInBytes == 0, outputLengthPointer.value: ${outputLengthPointer.value}");

        return add(associations, outputSizeInBytes: outputLengthPointer.value);
      }
      log("delete: exiting");
      if (outputSizeInBytes != 0 && errorCode == 0) {
        return Keywords.deserialize(
          output.asTypedList(outputLengthPointer.value),
        );
      }

      return {};
    } finally {
      calloc.free(output);
      calloc.free(outputLengthPointer);
      malloc.free(associationsPointer);
    }
  }

  static Future<Map<Keyword, Set<Location>>> search(Set<Keyword> keywords,
      {int outputSizeInBytes = defaultOutputSizeInBytes,
      bool verbose = false,
      int findexHandle = -1}) async {
    log("search: handle: $findexHandle");
    return searchWithInterruption(
        keywords,
        Pointer.fromFunction(
          defaultInterruptCallback,
          errorCodeInCaseOfCallbackException,
        ),
        outputSizeInBytes: outputSizeInBytes,
        findexHandle: findexHandle);
  }

  static Future<Map<Keyword, Set<Location>>> searchWithInterruption(
      Set<Keyword> keywords, Interrupt interruptCallback,
      {int outputSizeInBytes = defaultOutputSizeInBytes,
      int findexHandle = -1}) async {
    //
    // FFI INPUT parameters
    //

    if (keywords.isEmpty) {
      return {};
    }

    final keywordsBytes = Uint8List(Keywords.boundSerializedSize(keywords));
    final keywordsSerializedSize = Keywords.serialize(keywordsBytes, keywords);
    log("search: serialization keywords OK: $keywordsSerializedSize");
    final keywordsPointer = keywordsBytes.allocateUint8Pointer();

    //
    // FFI OUTPUT parameters
    //
    final output = calloc<Uint8>(outputSizeInBytes);
    final outputLengthPointer = calloc<Int32>(1);
    outputLengthPointer.value = outputSizeInBytes;

    final handle = findexHandle == -1 ? _handle! : findexHandle;
    log("searchWithInterruption: handle: $handle");

    try {
      final start = DateTime.now();
      final errorCode = library.h_search(
        output,
        outputLengthPointer,
        handle,
        keywordsPointer,
        keywordsSerializedSize,
        interruptCallback,
      );

      final end = DateTime.now();

      if (errorCode != 0 && outputLengthPointer.value > outputSizeInBytes) {
        return searchWithInterruption(keywords, interruptCallback,
            outputSizeInBytes: outputLengthPointer.value, findexHandle: handle);
      }

      await throwOnErrorCode(errorCode, start, end);

      return SearchResults.deserialize(
        output.asTypedList(outputLengthPointer.value),
      );
    } finally {
      calloc.free(output);
      calloc.free(outputLengthPointer);
      malloc.free(keywordsPointer);
    }
  }

  static Future<void> throwOnErrorCode(
    int errorCode,
    DateTime start,
    DateTime end,
  ) async {
    if (errorCode == 0) return;

    // The async callbacks errors are raised with a Dart listener which run inside
    // the async event loop. We are in sync code since the start of the FFI call
    // so even if an error was raised, the listener didn't have the time to run
    // (because the sync code blocks the event loop). Putting an `await` here allows
    // the event loop to do some work before continuing the function. The listener
    // will be run and the potential exception will be stored inside the `Findex.exceptions` array.
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
    log("isolateErrorCode: entering");
    final now = DateTime.now();
    final errorPort = ReceivePort();
    log("isolateErrorCode: errorPort: $errorPort");
    errorPort.listen((messages) {
      log("isolateErrorPort: messages: $messages");
      final e = AsyncCallbackExceptionWrapper(messages[0]);
      log("isolateErrorPort: e: $e");
      Findex.exceptions
          .add(ExceptionThrown(now, e, StackTrace.fromString(messages[1])));
    });

    return errorPort;
  }

  static String getLastError() {
    final errorPointer = calloc<Int8>(findexErrorMessageMaxLength);
    final errorLength = calloc<Int32>(1);
    errorLength.value = findexErrorMessageMaxLength;

    try {
      final result = library.get_last_error(errorPointer, errorLength);

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
    Pointer<Uint8> outputEntryTableLinesPointer,
    Pointer<Uint32> outputEntryTableLinesLength,
    Pointer<Uint8> uidsPointer,
    int uidsNumber,
  ) {
    final donePointer = calloc<Bool>(1);
    final exceptionIndicatorPointer = calloc<Bool>(1);
    donePointer.value = false;
    exceptionIndicatorPointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            final inputArray = Pointer<Uint8>.fromAddress(message.item3)
                .asTypedList(uidsNumber);

            final uids = Uids.deserialize(inputArray);
            final entryTableLines = await callback(uids);

            final ret = UidAndValue.serialize(
                Pointer<Uint8>.fromAddress(message.item1),
                Pointer<Uint32>.fromAddress(message.item2),
                entryTableLines);
            if (ret != 0) {
              throw Exception(
                  "Isolate wrapAsyncFetchCallback exception: Unable to serialize callback results: serialize error code: $ret. Rust output buffer is too small. Is the number of entry tables correct?");
            }
          } catch (e, stacktrace) {
            Pointer<Bool>.fromAddress(message.item5).value = true;
            log("[wrapperAsyncFetchCallback] exception caught: $e $stacktrace");
            rethrow;
          } finally {
            Pointer<Bool>.fromAddress(message.item4).value = true;
          }
        },
        Tuple5(
            outputEntryTableLinesPointer.address,
            outputEntryTableLinesLength.address,
            uidsPointer.address,
            donePointer.address,
            exceptionIndicatorPointer.address),
        onError: Findex.isolateErrorPort().sendPort,
      );

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }

      if (exceptionIndicatorPointer.value) {
        throw Exception(
            "Exception indicator raised: exception during fetch callback");
      }
      return 0;
    } catch (e, stacktrace) {
      log("Exception during fetch callback ($callback) $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
      calloc.free(exceptionIndicatorPointer);
    }
  }

  static int wrapAsyncUpsertEntriesCallback(
    Future<List<UidAndValue>> Function(UpsertData) callback,
    Pointer<Uint8> outputRejectedEntriesListPointer,
    Pointer<Uint32> outputRejectedEntriesListLength,
    Pointer<Uint8> oldValuesPointer,
    int oldValuesLength,
    Pointer<Uint8> newValuesPointer,
    int newValuesLength,
  ) {
    final donePointer = calloc<Bool>(1);
    final exceptionIndicatorPointer = calloc<Bool>(1);
    donePointer.value = false;
    exceptionIndicatorPointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            log("[wrapAsyncUpsertEntriesCallback] entering");

            final oldValues = Pointer<Uint8>.fromAddress(message.item1)
                .asTypedList(oldValuesLength);
            final newValues = Pointer<Uint8>.fromAddress(message.item2)
                .asTypedList(newValuesLength);
            final upsertData = UpsertData.deserialize(oldValues, newValues);

            log("[wrapAsyncUpsertEntriesCallback] oldValues: $oldValues");
            log("[wrapAsyncUpsertEntriesCallback] newValues: $newValues");
            log("[wrapAsyncUpsertEntriesCallback] upsertData length: ${upsertData.map.length}");

            final rejectedEntries = await callback(upsertData);

            log("[wrapAsyncUpsertEntriesCallback] rejectedEntries: $rejectedEntries");
            final returnCode = UidAndValue.serialize(
                Pointer<Uint8>.fromAddress(message.item3),
                Pointer<Uint32>.fromAddress(message.item4),
                rejectedEntries);
            log("[wrapAsyncUpsertEntriesCallback] exiting with return code: $returnCode");
            if (returnCode != 0) {
              throw Exception(
                  "Isolate wrapAsyncUpsertEntriesCallback exception: Unable to serialize callback results: serialize error code: $returnCode. Rust output buffer is too small. Is the number of entry tables correct?");
            }
          } catch (e, stacktrace) {
            Pointer<Bool>.fromAddress(message.item6).value = true;
            log("[wrapperAsyncUpsertCallback] exception caught: $e $stacktrace");
            rethrow;
          } finally {
            Pointer<Bool>.fromAddress(message.item5).value = true;
          }
        },
        Tuple6(
            oldValuesPointer.address,
            newValuesPointer.address,
            outputRejectedEntriesListPointer.address,
            outputRejectedEntriesListLength.address,
            donePointer.address,
            exceptionIndicatorPointer.address),
        onError: Findex.isolateErrorPort().sendPort,
      );

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
        log("sleep(10)");
      }
      if (exceptionIndicatorPointer.value) {
        throw Exception(
            "Exception indicator raised: exception during upsert callback");
      }

      return 0;
    } catch (e, stacktrace) {
      log("Exception during upsertEntriesCallback $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
      calloc.free(exceptionIndicatorPointer);
    }
  }

  static int wrapAsyncInsertEntriesCallback(
    Future<void> Function(List<UidAndValue>) callback,
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    final donePointer = calloc<Bool>(1);
    final exceptionIndicatorPointer = calloc<Bool>(1);
    donePointer.value = false;
    exceptionIndicatorPointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            final inputArray = Pointer<Uint8>.fromAddress(message.item1)
                .asTypedList(entriesListLength);

            final uidsAndValues = UidAndValue.deserialize(inputArray);

            await callback(uidsAndValues);
          } catch (e, stacktrace) {
            Pointer<Bool>.fromAddress(message.item3).value = true;
            log("[wrapAsyncInsertEntriesCallback] exception caught: $e $stacktrace");
            rethrow;
          } finally {
            Pointer<Bool>.fromAddress(message.item2).value = true;
          }
        },
        Tuple3(entriesListPointer.address, donePointer.address,
            exceptionIndicatorPointer.address),
        onError: Findex.isolateErrorPort().sendPort,
      );

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }

      if (exceptionIndicatorPointer.value) {
        throw Exception(
            "Exception indicator raised: exception during insert callback");
      }

      return 0;
    } catch (e, stacktrace) {
      log("Exception during insertEntriesCallback $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
      calloc.free(exceptionIndicatorPointer);
    }
  }

  static int wrapAsyncInsertChainsCallback(
    Future<void> Function(List<UidAndValue>) callback,
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    final donePointer = calloc<Bool>(1);
    final exceptionIndicatorPointer = calloc<Bool>(1);
    donePointer.value = false;
    exceptionIndicatorPointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            // Cast to list
            final inputArray = Pointer<Uint8>.fromAddress(message.item1)
                .asTypedList(chainsListLength);

            final uidsAndValues = UidAndValue.deserialize(inputArray);

            await callback(uidsAndValues);
          } catch (e, stacktrace) {
            Pointer<Bool>.fromAddress(message.item3).value = true;
            log("[wrapAsyncInsertChainsCallback] exception caught: $e $stacktrace");
            rethrow;
          } finally {
            Pointer<Bool>.fromAddress(message.item2).value = true;
          }
        },
        Tuple3(chainsListPointer.address, donePointer.address,
            exceptionIndicatorPointer.address),
        onError: Findex.isolateErrorPort().sendPort,
      );

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }

      if (exceptionIndicatorPointer.value) {
        throw Exception(
            "Exception indicator raised: exception during insert callback");
      }

      return 0;
    } catch (e, stacktrace) {
      log("Exception during insertChainsCallback $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
      calloc.free(exceptionIndicatorPointer);
    }
  }

  static int wrapSyncFetchCallback(
    List<UidAndValue> Function(Uids uids) callback,
    Pointer<Uint8> outputEntryTableLinesPointer,
    Pointer<Uint32> outputEntryTableLinesLength,
    Pointer<Uint8> uidsPointer,
    int uidsNumber,
  ) {
    try {
      final uids =
          Uids.deserialize(uidsPointer.cast<Uint8>().asTypedList(uidsNumber));
      final entryTableLines = callback(uids);

      return UidAndValue.serialize(outputEntryTableLinesPointer.cast<Uint8>(),
          outputEntryTableLinesLength, entryTableLines);
    } catch (e, stacktrace) {
      Findex.exceptions.add(ExceptionThrown(DateTime.now(), e, stacktrace));
      log("Exception during fetch callback ($callback) $e $stacktrace");
      rethrow;
    }
  }

  static int wrapSyncUpsertEntriesCallback(
    List<UidAndValue> Function(UpsertData) callback,
    Pointer<Uint8> outputRejectedEntriesListPointer,
    Pointer<Uint32> outputRejectedEntriesListLength,
    Pointer<Uint8> oldValuesPointer,
    int oldValuesLength,
    Pointer<Uint8> newValuesPointer,
    int newValuesLength,
  ) {
    try {
      // Deserialize uids and values
      log("[wrapSyncUpsertEntriesCallback] entering");

      final oldValues =
          oldValuesPointer.cast<Uint8>().asTypedList(oldValuesLength);
      final newValues =
          newValuesPointer.cast<Uint8>().asTypedList(newValuesLength);
      final upsertData = UpsertData.deserialize(oldValues, newValues);

      log("[wrapSyncUpsertEntriesCallback] oldValues: $oldValues");
      log("[wrapSyncUpsertEntriesCallback] newValues: $newValues");
      log("[wrapSyncUpsertEntriesCallback] upsertData length: ${upsertData.map.length}");

      final rejectedEntries = callback(upsertData);
      log("[wrapSyncUpsertEntriesCallback] rejectedEntries: $rejectedEntries");
      final returnCode = UidAndValue.serialize(outputRejectedEntriesListPointer,
          outputRejectedEntriesListLength, rejectedEntries);
      log("[wrapSyncUpsertEntriesCallback] exiting with return code: $returnCode");
      return returnCode;
    } catch (e, stacktrace) {
      Findex.exceptions.add(ExceptionThrown(DateTime.now(), e, stacktrace));
      log("Exception during upsertEntriesCallback $e $stacktrace");
      rethrow;
    }
  }

  static int wrapSyncInsertEntriesCallback(
    void Function(List<UidAndValue>) callback,
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    try {
      final uidsAndValues = UidAndValue.deserialize(
          entriesListPointer.cast<Uint8>().asTypedList(entriesListLength));

      callback(uidsAndValues);
      return 0;
    } catch (e, stacktrace) {
      Findex.exceptions.add(ExceptionThrown(DateTime.now(), e, stacktrace));
      log("Exception during insertEntriesCallback $e $stacktrace");
      rethrow;
    }
  }

  static int wrapSyncInsertChainsCallback(
    void Function(List<UidAndValue>) callback,
    Pointer<Uint8> chainsListPointer,
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

  static int wrapInterruptCallback(
    int Function(Map<Keyword, List<IndexedValue>>) callback,
    Pointer<Uint8> uidsPointer,
    int uidsLength,
  ) {
    try {
      final Map<Keyword, List<IndexedValue>> keywordsToIndexedValueMap =
          KeywordToIndexedValueMap.deserialize(
              uidsPointer.cast<Uint8>().asTypedList(uidsLength));
      return callback(keywordsToIndexedValueMap);
    } catch (e, stacktrace) {
      Findex.exceptions.add(ExceptionThrown(DateTime.now(), e, stacktrace));
      log("Exception during progressCallback $e $stacktrace");
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
