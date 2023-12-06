// ignore_for_file: avoid_print

import 'dart:ffi';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';

import 'in_memory_users.dart';

const expectedUsersIdsForFrance = [
  4,
  5,
  7,
  8,
  14,
  17,
  19,
  20,
  23,
  34,
  37,
  43,
  46,
  48,
  55,
  56,
  60,
  61,
  63,
  65,
  68,
  70,
  71,
  77,
  80,
  82,
  83,
  85,
  86,
  96
];

class FindexInMemory {
  static Map<Uint8List, Uint8List>? entryTable;
  static Map<Uint8List, Uint8List>? chainTable;

  static void init(FindexKey findexKey, String label) {
    entryTable = {};
    chainTable = {};
    Findex.instantiateFindex(
        findexKey,
        label,
        Pointer.fromFunction(
          fetchEntriesCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          fetchChainsCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          upsertEntriesCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          insertEntriesCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          insertChainsCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          deleteEntriesCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          deleteChainsCallback,
          errorCodeInCaseOfCallbackException,
        ),
        Pointer.fromFunction(
          dumpTokensCallback,
          errorCodeInCaseOfCallbackException,
        ));
  }

  static Future<Set<Keyword>> indexAll(FindexKey findexKey) async {
    final indexedValuesAndKeywords = {
      for (final user in Users.getUsers())
        IndexedValue.fromLocation(user.location): user.indexedWords,
    };

    return upsert(indexedValuesAndKeywords);
  }

  static List<UidAndValue> fetchEntries(Uids uids) {
    List<UidAndValue> entries = [];

    if (entryTable != null) {
      entryTable!.forEach((key, value) {
        for (Uint8List uid in uids.uids) {
          if (listEquals(uid, key)) {
            // print('fetchEntries: Key: $key, Value: $value');
            entries.add(UidAndValue(key, value));
            break;
          }
        }
      });
    }

    return entries;
  }

  static List<UidAndValue> fetchChains(Uids uids) {
    List<UidAndValue> chains = [];

    if (chainTable != null) {
      chainTable!.forEach((key, value) {
        for (Uint8List uid in uids.uids) {
          if (listEquals(uid, key)) {
            // print('fetchChains: Key: $key, Value: $value');
            chains.add(UidAndValue(uid, value));
            break;
          }
        }
      });
    }

    return chains;
  }

  static List<UidAndValue> upsertEntries(UpsertData entries) {
    List<UidAndValue> rejected = [];
    for (final entry in entries.map.entries) {
      if (entryTable != null) {
        entryTable?[entry.key] = entry.value.item2;
      }
    }
    return rejected;
  }

  static void insertEntries(List<UidAndValue> entries) {
    for (UidAndValue entry in entries) {
      if (entryTable != null) {
        entryTable?[entry.uid] = entry.value;
      }
    }
  }

  static void insertChains(List<UidAndValue> chains) {
    for (UidAndValue chain in chains) {
      if (chainTable != null) {
        chainTable?[chain.uid] = chain.value;
      }
    }
  }

  // --------------------------------------------------
  // Copy-paste code :AutoGeneratedImplementation
  // --------------------------------------------------

  static Future<Map<Keyword, Set<Location>>> search(
    Set<Keyword> keywords,
  ) async {
    return await Findex.search(keywords);
  }

  static Future<Set<Keyword>> upsert(
    Map<IndexedValue, Set<Keyword>> additions,
  ) async {
    return Findex.add(additions);
  }

  static int fetchEntriesCallback(
    Pointer<Uint8> outputEntryTableLinesPointer,
    Pointer<Uint32> outputEntryTableLinesLength,
    Pointer<Uint8> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapSyncFetchCallback(
      FindexInMemory.fetchEntries,
      outputEntryTableLinesPointer,
      outputEntryTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }

  static int fetchChainsCallback(
    Pointer<Uint8> outputChainTableLinesPointer,
    Pointer<Uint32> outputChainTableLinesLength,
    Pointer<Uint8> uidsPointer,
    int uidsNumber,
  ) {
    return Findex.wrapSyncFetchCallback(
      FindexInMemory.fetchChains,
      outputChainTableLinesPointer,
      outputChainTableLinesLength,
      uidsPointer,
      uidsNumber,
    );
  }

  static int upsertEntriesCallback(
    Pointer<Uint8> outputRejectedEntriesListPointer,
    Pointer<Uint32> outputRejectedEntriesListLength,
    Pointer<Uint8> oldValuesPointer,
    int oldValuesLength,
    Pointer<Uint8> newValuesPointer,
    int newValuesLength,
  ) {
    return Findex.wrapSyncUpsertEntriesCallback(
      FindexInMemory.upsertEntries,
      outputRejectedEntriesListPointer,
      outputRejectedEntriesListLength,
      oldValuesPointer,
      oldValuesLength,
      newValuesPointer,
      newValuesLength,
    );
  }

  static int insertEntriesCallback(
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.wrapSyncInsertEntriesCallback(
      FindexInMemory.insertEntries,
      entriesListPointer,
      entriesListLength,
    );
  }

  static int insertChainsCallback(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.wrapSyncInsertChainsCallback(
      FindexInMemory.insertChains,
      chainsListPointer,
      chainsListLength,
    );
  }

  static int deleteEntriesCallback(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    throw FindexException("not implemented");
  }

  static int deleteChainsCallback(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    throw FindexException("not implemented");
  }

  static int dumpTokensCallback(
    Pointer<Uint8> outputTokensPointer,
    Pointer<Uint32> outputTokensLength,
  ) {
    throw FindexException("not implemented");
  }
}
