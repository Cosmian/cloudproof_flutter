// NOTE: Autogenerated file

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
/**
 * Constant ENTRY_TABLE_UID_SIZE refers to the size of:
 * ```iet_uid = ℋ(𝐾uid, 𝑤𝑖, T)```
 */
#define ENTRY_TABLE_UID_SIZE 32
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
/**
 * The constant ENTRY_TABLE_VALUE_SIZE is determined by:
 *
 * `iet_value = EncSym(𝐾value, (ict_uid𝑥𝑤𝑖, 𝐾𝑤𝑖 , 𝑤𝑖))`
 *
 * where 𝑤𝑖 can be of almost any size (since this is a word).
 */
#define ENTRY_TABLE_VALUE_SIZE (92 + WORD_MAXIMUM_SIZE)
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
/**
 * CHAIN_TABLE_VALUE_SIZE constant refers to Findex.pdf paragraph 3.2: Index
 * Chain Table `ict_value = EncSym(𝐾𝑤𝑖 , 𝐿𝑤𝑖,2)`
 */
#define CHAIN_TABLE_VALUE_SIZE 60
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
typedef int (*FetchEntryTableCallback)(char *entries_ptr, unsigned int *entries_len, const unsigned char *uids_ptr, unsigned int uids_len);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
typedef void (*UpdateEntryTableCallback)(const unsigned char *entries_ptr, unsigned int entries_len);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
typedef void (*UpdateChainTableCallback)(const unsigned char *chain_ptr, unsigned int chain_len);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
typedef bool (*ProgressCallback)(const unsigned char *intermediate_results_ptr, unsigned int intermediate_results_len);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
typedef int (*FetchChainTableCallback)(char *chain_ptr, unsigned int *chain_len, const unsigned char *uids_ptr, unsigned int uids_len);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
/**
 *
 * # Return
 *
 * - 0: all done
 * - 1: ask again for more entries
 * - _: error
 */
typedef int (*FetchAllEntryTableCallback)(char *entries_ptr, unsigned int *entries_len, unsigned int number_of_entries);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
typedef int (*UpdateLinesCallback)(const unsigned char *removed_chain_table_ids_ptr, unsigned int removed_chain_table_ids_len, const unsigned char *new_encrypted_entry_table_items_ptr, unsigned int new_encrypted_entry_table_items_len, const unsigned char *new_encrypted_chain_table_items_ptr, unsigned int new_encrypted_chain_table_items_len);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
typedef int (*ListRemovedLocationsCallback)(char *removed_locations_ptr, unsigned int *removed_locations_len, const unsigned char *locations_ptr, unsigned int locations_len);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
/**
 * # Safety
 * cannot be safe since using FFI
 */
int h_upsert(const char *master_keys_ptr,
             const uint8_t *label_ptr,
             int label_len,
             const char *indexed_values_and_words_ptr,
             FetchEntryTableCallback fetch_entry,
             UpdateEntryTableCallback upsert_entry,
             UpdateChainTableCallback upsert_chain);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
/**
 * Works the same as `h_upsert()` but upserts the graph of all words used in
 * `indexed_values_and_words` too.
 *
 * # Safety
 * cannot be safe since using FFI
 */
int h_graph_upsert(const char *master_keys_ptr,
                   const uint8_t *label_ptr,
                   int label_len,
                   const char *indexed_values_and_words_ptr,
                   FetchEntryTableCallback fetch_entry,
                   UpdateEntryTableCallback upsert_entry,
                   UpdateChainTableCallback upsert_chain);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
/**
 * # Safety
 * cannot be safe since using FFI
 */
int h_search(char *indexed_values_ptr,
             int *indexed_values_len,
             const char *key_k_ptr,
             int key_k_len,
             const uint8_t *label_ptr,
             int label_len,
             const char *words_ptr,
             int loop_iteration_limit,
             int max_depth,
             ProgressCallback progress_callback,
             FetchEntryTableCallback fetch_entry,
             FetchChainTableCallback fetch_chain);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
/**
 * # Safety
 * cannot be safe since using FFI
 */
int h_compact(int number_of_reindexing_phases_before_full_set,
              const char *master_keys_ptr,
              const uint8_t *label_ptr,
              int label_len,
              FetchEntryTableCallback fetch_entry,
              FetchChainTableCallback fetch_chain,
              FetchAllEntryTableCallback fetch_all_entry,
              UpdateLinesCallback update_lines,
              ListRemovedLocationsCallback list_removed_locations);
#endif

#if (defined(DEFINE_INTERFACES) && defined(DEFINE_FFI))
/**
 * Get the most recent error as utf-8 bytes, clearing it in the process.
 * # Safety
 * - `error_msg`: must be pre-allocated with a sufficient size
 */
int get_last_error(char *error_msg_ptr, int *error_len);
#endif
