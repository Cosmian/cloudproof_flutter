
// abstract class FindexUpdate {
//   Future<Map<Uint8List, Uint8List>> fetchEntries(List<Uint8List> uids);
//   Future<void> upsertEntries(Map<Uint8List, Uint8List> entries);
//   Future<void> upsertChains(Map<Uint8List, Uint8List> chains);

//   Future<void> upsert(
//     MasterKeys masterKeys,
//     Uint8List label,
//     Map<IndexedValue, List<Word>> indexedValuesAndWords,
//   ) async {
//     final ffi = Ffi();
//     await ffi.upsert(masterKeys, label, indexedValuesAndWords, fetchEntries,
//         upsertEntries, upsertChains);
//   }
// }

// abstract class FindexSearch {
//   Future<Map<Uint8List, Uint8List>> fetchEntries(List<Uint8List> uids);
//   Future<Map<Uint8List, Uint8List>> fetchChains(List<Uint8List> uids);

//   Future<List<Uint8List>> search(
//     Uint8List keyK,
//     Uint8List label,
//     List<Word> words,
//   ) async {
//     final ffi = Ffi();
//     return await ffi.search(keyK, label, words, fetchEntries, fetchChains);
//   }
// }
