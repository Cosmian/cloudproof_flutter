# Cloudproof Flutter Library

The Cloudproof Flutter library provides a Flutter-friendly API to the [Cosmian Cloudproof Encryption product](https://docs.cosmian.com/cloudproof_encryption/use_cases_benefits/).

In summary, Cloudproof Encryption product secures data repositories in the cloud with attributes-based access control encryption and encrypted search.

<!-- toc -->

- [Getting started](#getting-started)
  - [CoverCrypt](#covercrypt)
  - [Findex](#findex)
- [Installation](#installation)
- [Example](#example)
- [Tests](#tests)
  - [WARNINGS](#warnings)
  - [Implementation details](#implementation-details)
- [FFI libs notes](#ffi-libs-notes)
  - [Generating `.h`](#generating-h)
    - [iOS WARNING](#ios-warning)
  - [Building `.so`, `.a`…](#building-so-a)
    - [Linux](#linux)
    - [Android](#android)
    - [iOS](#ios)
  - [Supported versions](#supported-versions)
- [Cloudproof versions Correspondence](#cloudproof-versions-correspondence)

<!-- tocstop -->

## Getting started

### CoverCrypt

CoverCrypt allows to decrypt data previously encrypted with one of our libraries (Java, Python, Rust…).

Two classes are available: `CoverCryptDecryption` and `CoverCryptDecryptionWithCache` which is a little bit faster (omit the initialization phase during decryption). See `test/covercrypt_test.dart`.

### Findex

Findex allows to do encrypted search queries on an encrypted index. To use Findex you need a driver which is able to store and update indexes (it could be SQLite, Redis, or any other storage method). You can find in `test/findex_redis_test.dart` and `test/findex_sqlite_test.dart` two example of implementation.

To search, you need:

1. copy/paste the following lines
2. replace `TODO_ReplaceThisByTheNameOfYourClassOrTheRawFunction` by the name of your class
3. implement `fetchEntries` and `fetchChains`

```dart
  static List<UidAndValue> fetchEntries(Uids uids) async {
    // Implement me!
  }

  static List<UidAndValue> fetchChains(Uids uids) async {
    // Implement me!
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<Map<Keyword, List<IndexedValue>>> search(
    Uint8List keyK,
    Uint8List label,
    List<Keyword> words,
  ) async {
    return await Findex.search(
      keyK,
      label,
      words,
      Pointer.fromFunction(
        fetchEntriesCallback,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        fetchChainsCallback,
        errorCodeInCaseOfCallbackException,
      ),
    );
  }

  static int fetchEntriesCallback(
    Pointer<UnsignedChar> outputEntryTableLinesPointer,
    Pointer<UnsignedInt> outputEntryTableLinesLength,
    Pointer<UnsignedChar> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapSyncFetchCallback(
      TODO_ReplaceThisByTheNameOfYourClassOrTheRawFunction.fetchEntries,
      outputEntryTableLinesPointer,
      outputEntryTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }

  static int fetchChainsCallback(
    Pointer<UnsignedChar> outputChainTableLinesPointer,
    Pointer<UnsignedInt> outputChainTableLinesLength,
    Pointer<UnsignedChar> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapSyncFetchCallback(
      TODO_ReplaceThisByTheNameOfYourClassOrTheRawFunction.fetchChains,
      outputChainTableLinesPointer,
      outputChainTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }
```

To upsert, you need:

1. copy/paste the following lines
2. replace `TODO_ReplaceThisByTheNameOfYourClassOrTheRawFunction` by the name of your class
3. implement `fetchEntries`, `upsertEntries` and `insertChains`

```dart
  static List<UidAndValue> fetchEntries(Uids uids) async {
    // Implement me!
  }

  static Future<List<UidAndValue>> upsertEntries(List<UpsertData> entries) async {
    // Implement me!
  }

  static void insertChains(List<UidAndValue> entries) async {
    // Implement me!
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<void> upsert(
    MasterKey masterKey,
    Uint8List label,
    Map<IndexedValue, List<Word>> indexedValuesAndWords,
  ) async {
    await Findex.upsert(
      masterKey,
      label,
      indexedValuesAndWords,
      Pointer.fromFunction(
        fetchEntriesCallback,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        upsertEntriesCallback,
        errorCodeInCaseOfCallbackException,
      ),
      Pointer.fromFunction(
        insertChainsCallback,
        errorCodeInCaseOfCallbackException,
      ),
    );
  }

  static int upsertEntriesCallback(
    Pointer<UnsignedChar> outputRejectedEntriesListPointer,
    Pointer<UnsignedInt> outputRejectedEntriesListLength,
    Pointer<UnsignedChar> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.wrapSyncUpsertEntriesCallback(
      TODO_ReplaceThisByTheNameOfYourClassOrTheRawFunction.upsertEntries,
      outputRejectedEntriesListPointer,
      outputRejectedEntriesListLength,
      entriesListPointer,
      entriesListLength,
    );
  }

  static int insertChainsCallback(
    Pointer<UnsignedChar> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.wrapSyncInsertChainsCallback(
      TODO_ReplaceThisByTheNameOfYourClassOrTheRawFunction.insertChains,
      chainsListPointer,
      chainsListLength,
    );
  }
```

Note that if you `search` and `upsert`, the two implementation can share the same callback for `fetchEntries`.

Note that if your callbacks are `async`, you can use `Findex.wrapAsyncFetchCallback`, `wrapAsyncUpsertEntriesCallback` and `wrapAsyncInsertChainsCallback`.

Note that the copy/paste code could be removed in a future version when Dart implements <https://github.com/dart-lang/language/issues/1482>.

## Installation

```bash
flutter pub get cloudproof
```

## Example

To run the example, you need a Redis server configured. Then, update `redisHost` and `redisPort` at the top of the `example/lib/findex_redis_implementation.dart` file.

## Tests

To run all tests:

```bash
flutter test
```

Some tests require a Redis database on localhost (default port).

If you ran the Java test which populate the Redis database, you can run the hidden test that read from this database.

```bash
RUN_JAVA_E2E_TESTS=1 flutter test --plain-name 'Search and decrypt with preallocate Redis by Java'
```

If you share the same Redis database between Java and Dart tests, `flutter test` will cleanup the Redis database (it could take some time and timeout on the first execution). So you may want to re-run `mvn test` to populate the Redis database again.

You can run the benchmarks with:

```bash
dart benchmark/cloudproof_benchmark.dart
```

### WARNINGS

- `fetchEntries`, `fetchChains`, `upsertEntries` and `insertChains` can not be static methods in a class or raw functions but should be static! You cannot put classic methods of an instance here.
- `fetchEntries`, `fetchChains`, `upsertEntries` and `insertChains` (if async) cannot access the state of the program, they will run in a separate `Isolate` with no data from the main thread (for example static/global variables populated during an initialization phase of your program will not exist). If you need to access some data from the main thread, the only way we think we'll work is to save this information inside a file or a database and read it from the callback. This pattern will slow down the `search` process. If you don't need async in the callbacks (for example the `sqlite` library has sync functions, you can call `*WrapperWithoutIsolate` and keep all the process in the same thread, so you can use your global variables).

### Implementation details

- The `search` and `upsert` methods will call the Rust FFI via native bindings synchronously. If you want to not stop your main thread, please call `compute` to run the search in a different Isolate.

## FFI libs notes

This project has been first created via:

```bash
flutter create --org com.example --template=plugin --platforms=android,ios -a kotlin cloudproof
```

### Generating `.h`

The `lib/src/*/generated_bindings.dart` are generated with `ffigen` with the config file `./ffigen_*.yml`:

```bash
flutter pub run ffigen --config ffigen_cover_crypt.yaml
flutter pub run ffigen --config ffigen_findex.yaml
```

#### iOS WARNING

Use cbindgen, do not forget to remove `str` type in `libcosmian_cover_crypt.h` (last two lines) for iOS to compile (type `str` unknown in C headers).

The two `.h` need to be inside the `ios/Classes` folder. Android doesn't need `.h` files.

### Building `.so`, `.a`…

#### Linux

Just copy `.so` file from the Rust projects to the `resources` folder. These `.so` are only useful to run the tests on Linux.

#### Android

Download artifacts from the Gitlab CI. You should get a `jniLibs` folder to copy to `android/src/main`.

Then:

```bash
cd example
flutter pub get
flutter run
```

#### iOS

If building with `cargo lipo` on Linux we only get `aarch64-apple-ios` and `x86_64-apple-ios`.

On codemagic.io:

- `aarch64-apple-ios` is failing with "ld: in /Users/builder/clone/ios/libcosmian_cover_crypt.a(cover_crypt.cover_crypt.aea4b2d2-cgu.0.rcgu.o), building for iOS Simulator, but linking in object file built for iOS, file '/Users/builder/clone/ios/libcosmian_cover_crypt.a' for architecture arm64"
- `x86_64-apple-ios` is failing with "ld: warning: ignoring file /Users/builder/clone/ios/libcosmian_cover_crypt.a, building for iOS Simulator-arm64 but attempting to link with file built for iOS Simulator-x86_64"

To make the flutter build succeed, 3 prerequisites are needed:

- declaring headers (CoverCrypt and Findex) in CloudproofPlugin.h (concat both headers)
- call artificially 1 function of each native library in SwiftCloudproofPlugin.swift
- use universal ios build: copy both .a in `cloudproof_flutter/ios`

### Supported versions

| Linux        | Flutter | Dart   | Android SDK       | NDK | Glibc | LLVM     | Smartphone Virtual Device |
| ------------ | ------- | ------ | ----------------- | --- | ----- | -------- | ------------------------- |
| Ubuntu 22.04 | 3.3.4   | 2.18.2 | Chipmunk 2021.2.1 | r25 | 2.35  | 14.0.0-1 | Pixel 5 API 30            |
| Centos 7     | 3.3.4   | 2.18.2 | Chipmunk 2021.2.1 | r25 | 2.17  | -        | -                         |

| Mac      | Flutter | Dart   | OS       | LLVM   | Xcode | Smartphone Virtual Device |
| -------- | ------- | ------ | -------- | ------ | ----- | ------------------------- |
| Catalina | 3.3.4   | 2.18.2 | Catalina | 12.0.0 |       | iPhone 12 PRO MAX         |

## Cloudproof versions Correspondence

When using local encryption and decryption with [CoverCrypt](https://github.com/Cosmian/cover_crypt) native libraries are required.

Check the main pages of the respective projects to build the native libraries appropriate for your systems. The [test directory](./src/test/resources/linux-x86-64/) provides pre-built libraries for Linux GLIBC 2.17. These libraries should run fine on a system with a more recent GLIBC version.

This table shows the minimum versions correspondences between the various components

| Flutter Lib | CoverCrypt lib | Findex |
| ----------- | -------------- | ------ |
| 0.1.0       | 6.0.5          | 0.7.2  |
| 1.0.0       | 6.0.5          | 0.7.2  |
| 2.0.0       | 7.1.0          | 0.10.0 |
| 3.0.0       | 8.0.0          | 0.12.0 |
| 4.0.0       | 8.0.0          | 1.0.1  |
