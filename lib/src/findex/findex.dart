import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io' show Directory, Platform, sleep;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:cloudproof/src/findex/generated_bindings.dart';
import 'package:cloudproof/src/utils/leb128.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'package:tuple/tuple.dart';

const findexErrorMessageMaxLength = 3000;
const defaultOutputSizeInBytes = 131072;

typedef FetchCallback = Future<Map<Uint8List, Uint8List>> Function(
  List<Uint8List>,
);
typedef FetchCallbackSync = Map<Uint8List, Uint8List> Function(List<Uint8List>);
typedef FetchChainsCallback = Future<Map<Uint8List, Uint8List>> Function(
  List<Uint8List>,
);
typedef UpsertCallback = Future<void> Function(Map<Uint8List, Uint8List>);
typedef UpsertCallbackSync = void Function(Map<Uint8List, Uint8List>);

const errorCodeInCaseOfCallbackException = 42;

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

  static int fetchWrapper(
    Pointer<Char> outputPointer,
    Pointer<UnsignedInt> outputLength,
    Pointer<UnsignedChar> uidsListPointer,
    int uidsListLength,
    FetchCallback callback,
  ) {
    final donePointer = calloc<Bool>(1);
    donePointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            final uids = Leb128.deserializeList(
                Pointer<Uint8>.fromAddress(message.item3)
                    .asTypedList(uidsListLength));

            final values = await callback(uids);

            final output = Pointer<Uint8>.fromAddress(message.item1)
                .asTypedList(Pointer<Int32>.fromAddress(message.item2).value);

            Leb128.serializeHashMap(output, values);
          } catch (e) {
            log("Excepting in fetch isolate. $e");
          } finally {
            Pointer<Bool>.fromAddress(message.item4).value = true;
          }
        },
        Tuple4(
          outputPointer.address,
          outputLength.address,
          uidsListPointer.address,
          donePointer.address,
        ),
      );

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }

      return 0;
    } catch (e, stacktrace) {
      log("Exception during fetch wrapper $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
    }
  }

  static int fetchWrapperWithoutIsolate(
    Pointer<Char> outputPointer,
    Pointer<UnsignedInt> outputLength,
    Pointer<UnsignedChar> uidsListPointer,
    int uidsListLength,
    FetchCallbackSync callback,
  ) {
    try {
      final uids = Leb128.deserializeList(
          uidsListPointer.cast<Uint8>().asTypedList(uidsListLength));

      final values = callback(uids);

      final output =
          outputPointer.cast<Uint8>().asTypedList(outputLength.value);

      Leb128.serializeHashMap(output, values);

      return 0;
    } catch (e, stacktrace) {
      log("Exception during fetch wrapper $e $stacktrace");
      rethrow;
    }
  }

  static void upsertWrapper(
    Pointer<UnsignedChar> valuesByUidsPointer,
    int valuesByUidsLength,
    UpsertCallback callback,
  ) {
    final donePointer = calloc<Bool>(1);
    donePointer.value = false;

    try {
      Isolate.spawn(
        (message) async {
          try {
            final valuesByUids = Leb128.deserializeHashMap(
                Pointer<Uint8>.fromAddress(message.item1)
                    .asTypedList(valuesByUidsLength));

            await callback(valuesByUids);
          } catch (e) {
            log("Excepting in upsert isolate. $e");
          } finally {
            Pointer<Bool>.fromAddress(message.item2).value = true;
          }
        },
        Tuple2(
          valuesByUidsPointer.address,
          donePointer.address,
        ),
      );

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }
    } catch (e, stacktrace) {
      log("Exception during upsert wrapper $e $stacktrace");
      rethrow;
    } finally {
      calloc.free(donePointer);
    }
  }

  static void upsertWrapperWithoutIsolate(
    Pointer<UnsignedChar> valuesByUidsPointer,
    int valuesByUidsLength,
    UpsertCallbackSync callback,
  ) {
    try {
      final valuesByUids = Leb128.deserializeHashMap(
        valuesByUidsPointer.cast<Uint8>().asTypedList(valuesByUidsLength),
      );

      callback(valuesByUids);
    } catch (e, stacktrace) {
      log("Exception during upsert wrapper $e $stacktrace");
      rethrow;
    }
  }

  static Future<void> upsert(
    FindexMasterKeys masterKeys,
    Uint8List label,
    Map<IndexedValue, List<Word>> indexedValuesAndWords,
    FetchEntryTableCallback fetchEntries,
    UpdateEntryTableCallback upsertEntries,
    UpdateChainTableCallback upsertChains,
  ) async {
    final indexedValuesAndWordsString = indexedValuesAndWords.map(
        (key, value) =>
            MapEntry(key.toBase64(), value.map((e) => e.toBase64()).toList()));

    final masterKeysJson = jsonEncode(masterKeys.toJson());
    final Pointer<Utf8> masterKeysPointer =
        masterKeysJson.toNativeUtf8(allocator: malloc);

    final indexedValuesAndWordsJson = jsonEncode(indexedValuesAndWordsString);
    final Pointer<Utf8> indexedValuesAndWordsPointer =
        indexedValuesAndWordsJson.toNativeUtf8(allocator: malloc);

    final labelPointer = label.allocateUint8Pointer();

    try {
      final result = library.h_upsert(
        masterKeysPointer.cast<Char>(),
        labelPointer.cast<Int>(),
        label.length,
        indexedValuesAndWordsPointer.cast<Char>(),
        fetchEntries,
        upsertEntries,
        upsertChains,
      );

      if (result != 0) {
        throw Exception("Fail to upsert");
      }
    } finally {
      calloc.free(labelPointer);
      malloc.free(masterKeysPointer);
      malloc.free(indexedValuesAndWordsPointer);
    }
  }

  static Future<List<IndexedValue>> search(
      Uint8List k,
      Uint8List label,
      List<Word> words,
      FetchEntryTableCallback fetchEntries,
      FetchChainTableCallback fetchChains,
      {int outputSizeInBytes = defaultOutputSizeInBytes}) async {
    final wordsString = words.map((value) => value.toBase64()).toList();

    final output = calloc<Uint8>(outputSizeInBytes);
    final outputSizeInBytesPointer = calloc<Int32>(1);
    outputSizeInBytesPointer.value = outputSizeInBytes;

    final wordsJson = jsonEncode(wordsString);
    final Pointer<Utf8> wordsPointer = wordsJson.toNativeUtf8();

    final kPointer = k.allocateUint8Pointer();
    final labelPointer = label.allocateUint8Pointer();

    try {
      final result = library.h_search(
        output.cast<Char>(),
        outputSizeInBytesPointer.cast<Int>(),
        kPointer.cast<Char>(),
        k.length,
        labelPointer.cast<Int>(),
        label.length,
        wordsPointer.cast<Char>(),
        0,
        0,
        0, // Progress callback is not used for now.
        fetchEntries,
        fetchChains,
      );

      if (result != 0) {
        // If Rust tells us that our buffer is too small for the search results
        // retry with the correct buffer size.
        if (outputSizeInBytesPointer.value > outputSizeInBytes) {
          return search(k, label, words, fetchEntries, fetchChains,
              outputSizeInBytes: outputSizeInBytesPointer.value);
        }
        throw Exception("Fail to search ${getLastError()}");
      }

      return Leb128.deserializeList(output.asTypedList(outputSizeInBytes))
          .map((bytes) => IndexedValue(bytes))
          .toList();
    } finally {
      calloc.free(output);
      calloc.free(outputSizeInBytesPointer);
      malloc.free(wordsPointer);
      calloc.free(kPointer);
      calloc.free(labelPointer);
    }
  }

  static bool progressCallback(
    Pointer<Uint8> uidsListPointer,
    int uidsListLength,
  ) {
    return true;
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
