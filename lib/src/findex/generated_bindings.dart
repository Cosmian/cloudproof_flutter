// ignore_for_file: constant_identifier_names, non_constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
import 'dart:ffi' as ffi;

/// Dart bindings to call Findex functions
class FindexNativeLibrary {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  FindexNativeLibrary(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  FindexNativeLibrary.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  /// Index the given values for the given keywords. After upserting, any
  /// search for such a keyword will result in finding (at least) the
  /// corresponding value.
  ///
  /// # Safety
  ///
  /// Cannot be safe since using FFI.
  int h_upsert(
    ffi.Pointer<ffi.Int> master_key_ptr,
    int master_key_len,
    ffi.Pointer<ffi.Int> label_ptr,
    int label_len,
    ffi.Pointer<ffi.Char> indexed_values_and_keywords_ptr,
    FetchEntryTableCallback fetch_entry,
    UpsertEntryTableCallback upsert_entry,
    InsertChainTableCallback upsert_chain,
  ) {
    return _h_upsert(
      master_key_ptr,
      master_key_len,
      label_ptr,
      label_len,
      indexed_values_and_keywords_ptr,
      fetch_entry,
      upsert_entry,
      upsert_chain,
    );
  }

  late final _h_upsertPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Int>,
              ffi.Int,
              ffi.Pointer<ffi.Int>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              FetchEntryTableCallback,
              UpsertEntryTableCallback,
              InsertChainTableCallback)>>('h_upsert');
  late final _h_upsert = _h_upsertPtr.asFunction<
      int Function(
          ffi.Pointer<ffi.Int>,
          int,
          ffi.Pointer<ffi.Int>,
          int,
          ffi.Pointer<ffi.Char>,
          FetchEntryTableCallback,
          UpsertEntryTableCallback,
          InsertChainTableCallback)>();

  /// Recursively searches Findex graphs for values indexed by the given keywords.
  ///
  /// # Safety
  ///
  /// Cannot be safe since using FFI.
  int h_search(
    ffi.Pointer<ffi.Char> indexed_values_ptr,
    ffi.Pointer<ffi.Int> indexed_values_len,
    ffi.Pointer<ffi.Char> key_k_ptr,
    int key_k_len,
    ffi.Pointer<ffi.Int> label_ptr,
    int label_len,
    ffi.Pointer<ffi.Char> keywords_ptr,
    int loop_iteration_limit,
    int max_depth,
    int progress_callback,
    FetchEntryTableCallback fetch_entry,
    FetchChainTableCallback fetch_chain,
  ) {
    return _h_search(
      indexed_values_ptr,
      indexed_values_len,
      key_k_ptr,
      key_k_len,
      label_ptr,
      label_len,
      keywords_ptr,
      loop_iteration_limit,
      max_depth,
      progress_callback,
      fetch_entry,
      fetch_chain,
    );
  }

  late final _h_searchPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Pointer<ffi.Int>,
              ffi.Int,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              FetchEntryTableCallback,
              FetchChainTableCallback)>>('h_search');
  late final _h_search = _h_searchPtr.asFunction<
      int Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Int>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Int>,
          int,
          ffi.Pointer<ffi.Char>,
          int,
          int,
          int,
          FetchEntryTableCallback,
          FetchChainTableCallback)>();

  /// Replaces all the Index Entry Table UIDs and values. New UIDs are derived
  /// using the given label and the KMAC key derived from the new master key. The
  /// values are dectypted using the DEM key derived from the master key and
  /// re-encrypted using the DEM key derived from the new master key.
  ///
  /// Randomly selects index entries and recompact their associated chains. Chains
  /// indexing no existing location are removed. Others are recomputed from a new
  /// keying material. This removes unneeded paddings. New UIDs are derived for
  /// the chain and values are re-encrypted using a DEM key derived from the new
  /// keying material.
  ///
  /// # Safety
  ///
  /// Cannot be safe since using FFI.
  int h_compact(
    int num_reindexing_before_full_set,
    ffi.Pointer<ffi.Int> master_key_ptr,
    int master_key_len,
    ffi.Pointer<ffi.Int> new_master_key_ptr,
    int new_master_key_len,
    ffi.Pointer<ffi.Int> label_ptr,
    int label_len,
    FetchEntryTableCallback fetch_entry,
    FetchChainTableCallback fetch_chain,
    FetchAllEntryTableCallback fetch_all_entry,
    UpdateLinesCallback update_lines,
    ListRemovedLocationsCallback list_removed_locations,
  ) {
    return _h_compact(
      num_reindexing_before_full_set,
      master_key_ptr,
      master_key_len,
      new_master_key_ptr,
      new_master_key_len,
      label_ptr,
      label_len,
      fetch_entry,
      fetch_chain,
      fetch_all_entry,
      update_lines,
      list_removed_locations,
    );
  }

  late final _h_compactPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Int,
              ffi.Pointer<ffi.Int>,
              ffi.Int,
              ffi.Pointer<ffi.Int>,
              ffi.Int,
              ffi.Pointer<ffi.Int>,
              ffi.Int,
              FetchEntryTableCallback,
              FetchChainTableCallback,
              FetchAllEntryTableCallback,
              UpdateLinesCallback,
              ListRemovedLocationsCallback)>>('h_compact');
  late final _h_compact = _h_compactPtr.asFunction<
      int Function(
          int,
          ffi.Pointer<ffi.Int>,
          int,
          ffi.Pointer<ffi.Int>,
          int,
          ffi.Pointer<ffi.Int>,
          int,
          FetchEntryTableCallback,
          FetchChainTableCallback,
          FetchAllEntryTableCallback,
          UpdateLinesCallback,
          ListRemovedLocationsCallback)>();

  /// Get the most recent error as utf-8 bytes, clearing it in the process.
  /// # Safety
  /// - `error_msg`: must be pre-allocated with a sufficient size
  int get_last_error(
    ffi.Pointer<ffi.Char> error_msg_ptr,
    ffi.Pointer<ffi.Int> error_len,
  ) {
    return _get_last_error(
      error_msg_ptr,
      error_len,
    );
  }

  late final _get_last_errorPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>)>>('get_last_error');
  late final _get_last_error = _get_last_errorPtr
      .asFunction<int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>)>();
}

/// Callback to fetch the lines with the given UIDs from the Entry Table.
/// The values returned are encrypted since they are stored that way. The
/// decryption is performed by Findex.
///
/// # Serialization
///
/// The input is serialized as follows:
///
/// `LEB128(uids.len()) || uid_1 || ...`
///
/// The output should be serialized as follows:
///
/// `LEB128(entries.len()) || LEB128(entry_1.len()) || entry_1 || ...`
///
/// # Parameters
///
/// - `entries` : (output) Entry Table items
/// - `uids`    : Entry Table UIDs of the lines to fetch
typedef FetchEntryTableCallback = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.UnsignedInt>,
            ffi.Pointer<ffi.UnsignedChar>, ffi.UnsignedInt)>>;

/// Upserts lines in the Entry Table. The input data should map each Entry
/// Table UID to upsert to the last value known by the client and the value
/// to upsert:
///
/// `UID <-> (OLD_VALUE, NEW_VALUE)`
///
/// To allow concurrent upsert operations, this callback should:
///
/// 1 - for each UID given, perform an *atomic* conditional upsert: if the
/// current value stored in the DB is equal to `OLD_VALUE`, then `NEW_VALUE`
/// should be upserted;
///
/// 2 - get the current values stored in the DB for all failed upserts from
/// step 1 and send them back to the client.
///
/// # Serialization
///
/// The input is serialized as follows:
///
/// ` LEB128(entries.len()) || LEB128(old_value_1.len()) || old_value_1 ||
/// LEB128(new_value_1.len()) || new_value_1 || ...`
///
/// The output should be serialized as follows:
///
/// `LEB128(outputs.len()) || LEB128(output_1.len()) || output_1 || ...`
///
/// # Parameters
///
/// - `entries` : entries to be upserted
/// - `outputs` : (output) current value of the lines that failed to be upserted
typedef UpsertEntryTableCallback = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Void Function(ffi.Pointer<ffi.UnsignedChar>, ffi.UnsignedInt,
            ffi.Pointer<ffi.UnsignedChar>, ffi.Pointer<ffi.UnsignedInt>)>>;

/// Inserts the given lines into the Chain Table. This should return an
/// error if a line with the same UID as one of the lines given already
/// exists.
///
/// # Serialization
///
/// The input is serialized as follows:
///
/// `LEB128(chains.len()) || LEB128(chain_1.len() || chain_1 || ...`
///
/// # Parameters
///
/// - `chains`   : Chain Table items to insert
typedef InsertChainTableCallback = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Void Function(ffi.Pointer<ffi.UnsignedChar>, ffi.UnsignedInt)>>;

/// Callback to fetch the lines with the given UIDs from the Chain Table.
/// The values returned are encrypted since they are stored that way. The
/// decryption is performed by Findex.
///
/// # Serialization
///
/// The input is serialized as follows:
///
/// `LEB128(uids.len()) || uid_1 || ...`
///
/// The output should be serialized as follows:
///
/// `LEB128(chains.len()) || LEB128(chain_1.len()) || chain_1 || ...`
///
/// # Parameters
///
/// - `chains`   : (output) Chain Table items
/// - `uids`    : Entry Table UIDs of the lines to fetch
typedef FetchChainTableCallback = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.UnsignedInt>,
            ffi.Pointer<ffi.UnsignedChar>, ffi.UnsignedInt)>>;

/// # Return
///
/// - 0: all done
/// - 1: ask again for more entries
/// - _: error
typedef FetchAllEntryTableCallback = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.UnsignedInt>,
            ffi.UnsignedInt)>>;
typedef UpdateLinesCallback = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Int Function(
            ffi.Pointer<ffi.UnsignedChar>,
            ffi.UnsignedInt,
            ffi.Pointer<ffi.UnsignedChar>,
            ffi.UnsignedInt,
            ffi.Pointer<ffi.UnsignedChar>,
            ffi.UnsignedInt)>>;
typedef ListRemovedLocationsCallback = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.UnsignedInt>,
            ffi.Pointer<ffi.UnsignedChar>, ffi.UnsignedInt)>>;

const int KeyWord_HASH_LENGTH = 32;

const int MASTER_KEY_LENGTH = 32;

const int KWI_LENGTH = 16;

const int KMAC_KEY_LENGTH = 16;