import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io' show Directory, Platform, sleep;
import 'dart:isolate';
import 'dart:typed_data';
import 'package:cloudproof/cloudproof.dart';
import 'package:cloudproof/src/utils/leb128.dart';
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';
import 'package:tuple/tuple.dart';

const errorMessageMaxLength = 3000;
const defaultOutputSizeInBytes = 131072;

typedef NativeUpsertFunc = Int32 Function(
  Pointer<Utf8>,
  Pointer<Uint8>,
  Int32,
  Pointer<Utf8>,
  Pointer<NativeFunction<FetchEntriesFfiCallback>>,
  Pointer<NativeFunction<UpsertEntriesFfiCallback>>,
  Pointer<NativeFunction<UpsertChainsFfiCallback>>,
);

typedef HUpsert = int Function(
  Pointer<Utf8>,
  Pointer<Uint8>,
  int,
  Pointer<Utf8>,
  Pointer<NativeFunction<FetchEntriesFfiCallback>>,
  Pointer<NativeFunction<UpsertEntriesFfiCallback>>,
  Pointer<NativeFunction<UpsertChainsFfiCallback>>,
);

typedef NativeSearchFunc = Int32 Function(
  Pointer<Uint8>,
  Pointer<Int32>,
  Pointer<Uint8>,
  Int32,
  Pointer<Uint8>,
  Int32,
  Pointer<Utf8>,
  Int32,
  Int32,
  Pointer<NativeFunction<ProgressFFiCallback>>,
  Pointer<NativeFunction<FetchEntriesFfiCallback>>,
  Pointer<NativeFunction<FetchChainsFfiCallback>>,
);

typedef HSearch = int Function(
  Pointer<Uint8>,
  Pointer<Int32>,
  Pointer<Uint8>,
  int,
  Pointer<Uint8>,
  int,
  Pointer<Utf8>,
  int,
  int,
  Pointer<NativeFunction<ProgressFFiCallback>>,
  Pointer<NativeFunction<FetchEntriesFfiCallback>>,
  Pointer<NativeFunction<FetchChainsFfiCallback>>,
);

typedef FetchEntriesFfiCallback = Int32 Function(
  Pointer<Uint8>,
  Pointer<Uint32>,
  Pointer<Uint8>,
  Uint32,
);

typedef ProgressFFiCallback = Bool Function(
  Pointer<Uint8>,
  Uint32,
);

typedef ProgressCallback = bool Function(
  Pointer<Uint8>,
  int,
);

typedef FetchEntriesCallback = Future<Map<Uint8List, Uint8List>> Function(
  List<Uint8List>,
);

typedef FetchCallback = Future<Map<Uint8List, Uint8List>> Function(
  List<Uint8List>,
);

typedef FetchChainsFfiCallback = Int32 Function(
  Pointer<Uint8>,
  Pointer<Uint32>,
  Pointer<Uint8>,
  Uint32,
);
typedef FetchChainsCallback = Future<Map<Uint8List, Uint8List>> Function(
  List<Uint8List>,
);

typedef UpsertEntriesFfiCallback = Int32 Function(
  Pointer<Uint8>,
  Uint32,
);
typedef UpsertEntriesCallback = Future<void> Function(
  Map<Uint8List, Uint8List>,
);
typedef UpsertCallback = Future<void> Function(Map<Uint8List, Uint8List>);

typedef UpsertChainsFfiCallback = Int32 Function(
  Pointer<Uint8>,
  Uint32,
);
typedef UpsertChainsCallback = Future<void> Function(
  Map<Uint8List, Uint8List>,
);

const errorCodeInCaseOfCallbackException = 42;

class Findex {
  static DynamicLibrary? _dylib;

  static DynamicLibrary get dylib {
    if (_dylib != null) {
      return _dylib as DynamicLibrary;
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

    final dylib = libraryPath != null
        ? DynamicLibrary.open(libraryPath)
        : DynamicLibrary.process();
    _dylib = dylib;
    return dylib;
  }

  static int fetchWrapper(
    Pointer<Uint8> outputPointer,
    Pointer<Uint32> outputLength,
    Pointer<Uint8> uidsListPointer,
    int uidsListLength,
    FetchCallback callback,
  ) {
    try {
      final donePointer = calloc<Bool>(1);

      Isolate.spawn((message) async {
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
          Tuple4(outputPointer.address, outputLength.address,
              uidsListPointer.address, donePointer.address));

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }

      calloc.free(donePointer);
      return 0;
    } catch (e, stacktrace) {
      log("Exception during fetch wrapper $e $stacktrace");
      rethrow;
    }
  }

  static int upsertWrapper(
    Pointer<Uint8> valuesByUidsPointer,
    int valuesByUidsLength,
    UpsertCallback callback,
  ) {
    try {
      final donePointer = calloc<Bool>(1);

      Isolate.spawn((message) async {
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
      }, Tuple2(valuesByUidsPointer.address, donePointer.address));

      while (!donePointer.value) {
        sleep(const Duration(milliseconds: 10));
      }

      calloc.free(donePointer);
      return 0;
    } catch (e, stacktrace) {
      log("Exception during upsert wrapper $e $stacktrace");
      rethrow;
    }
  }

  static Future<void> upsert(
    MasterKeys masterKeys,
    Uint8List label,
    Map<IndexedValue, List<Word>> indexedValuesAndWords,
    Pointer<NativeFunction<FetchEntriesFfiCallback>> fetchEntries,
    Pointer<NativeFunction<UpsertEntriesFfiCallback>> upsertEntries,
    Pointer<NativeFunction<UpsertChainsFfiCallback>> upsertChains,
  ) async {
    final HUpsert hUpsert =
        dylib.lookup<NativeFunction<NativeUpsertFunc>>('h_upsert').asFunction();

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
      final result = hUpsert(
        masterKeysPointer,
        labelPointer,
        label.length,
        indexedValuesAndWordsPointer,
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
      Pointer<NativeFunction<FetchEntriesFfiCallback>> fetchEntries,
      Pointer<NativeFunction<FetchChainsFfiCallback>> fetchChains,
      {int outputSizeInBytes = defaultOutputSizeInBytes}) async {
    final HSearch hSearch =
        dylib.lookup<NativeFunction<NativeSearchFunc>>('h_search').asFunction();

    final wordsString = words.map((value) => value.toBase64()).toList();

    final output = calloc<Uint8>(outputSizeInBytes);
    final outputSizeInBytesPointer = calloc<Int32>(1);
    outputSizeInBytesPointer.value = outputSizeInBytes;

    final wordsJson = jsonEncode(wordsString);
    final Pointer<Utf8> wordsPointer = wordsJson.toNativeUtf8();

    final kPointer = k.allocateUint8Pointer();
    final labelPointer = label.allocateUint8Pointer();

    try {
      final result = hSearch(
        output,
        outputSizeInBytesPointer,
        kPointer,
        k.length,
        labelPointer,
        label.length,
        wordsPointer,
        0,
        0,
        Pointer.fromFunction(Findex.progressCallback, true),
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
    late final getLastErrorPointer =
        dylib.lookup<NativeFunction<Int Function(Pointer<Char>, Pointer<Int>)>>(
            'get_last_error');

    final getLastError = getLastErrorPointer
        .asFunction<int Function(Pointer<Char>, Pointer<Int>)>();

    final errorPointer = calloc<Uint8>(errorMessageMaxLength);
    final errorLength = calloc<Int>(1);
    errorLength.value = errorMessageMaxLength;

    try {
      final result = getLastError(errorPointer.cast<Char>(), errorLength);

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
