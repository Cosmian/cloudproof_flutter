#import <Flutter/Flutter.h>

@interface CloudproofPlugin : NSObject<FlutterPlugin>
@end

#define TAG_LENGTH 32

#define SYM_KEY_LENGTH 32

#define MAX_CLEAR_TEXT_SIZE (1 << 30)

/**
 * # Safety
 */
int h_policy(char *policy_ptr, int *policy_len, int max_attribute_creations);

/**
 * # Safety
 */
int h_add_policy_axis(char *updated_policy_ptr,
                      int *updated_policy_len,
                      const char *current_policy_ptr,
                      int current_policy_len,
                      const char *axis_ptr);

/**
 * # Safety
 */
int h_rotate_attribute(char *updated_policy_ptr,
                       int *updated_policy_len,
                       const char *current_policy_ptr,
                       int current_policy_len,
                       const char *attribute);

/**
 * # Safety
 */
int h_validate_boolean_expression(const char *boolean_expression_ptr);

/**
 * # Safety
 */
int h_validate_attribute(const char *attribute_ptr);

/**
 * Generates the master authority keys for supplied Policy.
 *
 *  - `msk_ptr`    : Output buffer containing the master secret key
 *  - `msk_len`    : Size of the master secret key output buffer
 *  - `mpk_ptr`    : Output buffer containing the master public key
 *  - `mpk_len`    : Size of the master public key output buffer
 *  - `policy_ptr` : Policy to use to generate the keys
 *  - `policy_len` : Size of the `Policy` to use to generate the keys
 *
 * # Safety
 */
int h_generate_master_keys(char *msk_ptr,
                           int *msk_len,
                           char *mpk_ptr,
                           int *mpk_len,
                           const char *policy_ptr,
                           int policy_len);

/**
 * Generates a user secret key for the given access policy
 *
 * - `usk_ptr`             : Output buffer containing user secret key
 * - `usk_len`             : Size of the output buffer
 * - `msk_ptr`             : Master secret key (required for this generation)
 * - `msk_len`             : Master secret key length
 * - `user_policy_ptr`   : null terminated access policy string
 * - `policy_ptr`          : bytes of the policyused to generate the keys
 * - `policy_len`          : length of the policy (in bytes)
 * # Safety
 */
int h_generate_user_secret_key(char *usk_ptr,
                               int *usk_len,
                               const char *msk_ptr,
                               int msk_len,
                               const char *user_policy_ptr,
                               const char *policy_ptr,
                               int policy_len);

/**
 * Updates the master keys according to the given policy.
 *
 * Cf (`CoverCrypt::update_master_keys`)[`CoverCrypt::update_master_keys`].
 *
 * - `updated_msk_ptr` : Output buffer containing the updated master secret key
 * - `updated_msk_len` : Size of the updated master secret key output buffer
 * - `updated_mpk_ptr` : Output buffer containing the updated master public key
 * - `updated_mpk_len` : Size of the updated master public key output buffer
 * - `current_msk_ptr` : current master secret key
 * - `current_msk_len` : current master secret key length
 * - `current_mpk_ptr` : current master public key
 * - `current_mpk_len` : current master public key length
 * - `policy_ptr`      : Policy to use to update the master keys (JSON)
 * # Safety
 */
int h_update_master_keys(char *updated_msk_ptr,
                         int *updated_msk_len,
                         char *updated_mpk_ptr,
                         int *updated_mpk_len,
                         const char *current_msk_ptr,
                         int current_msk_len,
                         const char *current_mpk_ptr,
                         int current_mpk_len,
                         const char *policy_ptr,
                         int policy_len);

/**
 * Refreshes the user secret key according to the given master key and access
 * policy.
 *
 * Cf [`CoverCrypt::refresh_user_secret_key()`](CoverCrypt::refresh_user_secret_key).
 *
 * - `updated_usk_ptr`                 : Output buffer containing the updated
 *   user secret key
 * - `updated_usk_len`                 : Size of the updated user secret key
 *   output buffer
 * - `msk_ptr`                         : master secret key
 * - `msk_len`                         : master secret key length
 * - `current_usk_ptr`                 : current user secret key
 * - `current_usk_len`                 : current user secret key length
 * - `access_policy_ptr`               : Access policy of the user secret key
 *   (JSON)
 * - `policy_ptr`                      : Policy to use to update the master
 *   keys (JSON)
 * - `preserve_old_partitions_access`  : set to 1 to preserve the user access
 *   to the rotated partitions
 * # Safety
 */
int h_refresh_user_secret_key(char *updated_usk_ptr,
                              int *updated_usk_len,
                              const char *msk_ptr,
                              int msk_len,
                              const char *current_usk_ptr,
                              int current_usk_len,
                              const char *access_policy_ptr,
                              const char *policy_ptr,
                              int policy_len,
                              int preserve_old_partitions_access);

/**
 * Creates a cache containing the Public Key and Policy. This cache can be
 * reused when encrypting messages which avoids passing these objects to Rust
 * in each call.
 *
 * WARNING: [`h_destroy_encrypt_cache()`](h_destroy_encryption_cache)
 * should be called to reclaim the cache memory.
 *
 * # Safety
 */
int32_t h_create_encryption_cache(int *cache_handle,
                                  const char *policy_ptr,
                                  int policy_len,
                                  const char *mpk_ptr,
                                  int mpk_len);

/**
 * Reclaims the memory of the cache.
 *
 * Cf [`h_create_encrypt_cache()`](h_create_encryption_cache).
 *
 * # Safety
 */
int h_destroy_encryption_cache(int cache_handle);

/**
 * Encrypts a header using an encryption cache.
 *
 * # Safety
 */
int h_encrypt_header_using_cache(char *symmetric_key_ptr,
                                 int *symmetric_key_len,
                                 char *header_bytes_ptr,
                                 int *header_bytes_len,
                                 int cache_handle,
                                 const char *encryption_policy_ptr,
                                 const char *header_metadata_ptr,
                                 int header_metadata_len,
                                 const char *authentication_data_ptr,
                                 int authentication_data_len);

/**
 * Encrypts a header without using an encryption cache.
 * It is slower but does not require destroying any cache when done.
 *
 * The symmetric key and header bytes are returned in the first OUT parameters
 * # Safety
 */
int h_encrypt_header(char *symmetric_key_ptr,
                     int *symmetric_key_len,
                     char *header_bytes_ptr,
                     int *header_bytes_len,
                     const char *policy_ptr,
                     int policy_len,
                     const char *mpk_ptr,
                     int mpk_len,
                     const char *encryption_policy_ptr,
                     const char *header_metadata_ptr,
                     int header_metadata_len,
                     const char *authentication_data_ptr,
                     int authentication_data_len);

/**
 * Creates a cache containing the user secret key. This cache can be reused
 * when decrypting messages which avoids passing this key to Rust in each call.
 *
 * Cf [`h_decrypt_header_using_cache()`](h_decrypt_header_using_cache).
 *
 * WARNING: [`h_destroy_decryption_cache()`](h_destroy_decryption_cache)
 * should be called to reclaim the cache memory.
 *
 * # Safety
 */
int32_t h_create_decryption_cache(int *cache_handle, const char *usk_ptr, int usk_len);

/**
 * Reclaims decryption cache memory.
 *
 * # Safety
 */
int h_destroy_decryption_cache(int cache_handle);

/**
 * Decrypts an encrypted header using a cache. Returns the symmetric key and
 * header metadata if any.
 *
 * No header metadata is returned if `header_metadata_ptr` is `NULL`.
 *
 * # Safety
 */
int h_decrypt_header_using_cache(char *symmetric_key_ptr,
                                 int *symmetric_key_len,
                                 char *header_metadata_ptr,
                                 int *header_metadata_len,
                                 const char *encrypted_header_ptr,
                                 int encrypted_header_len,
                                 const char *authentication_data_ptr,
                                 int authentication_data_len,
                                 int cache_handle);

/**
 * Decrypts an encrypted header, returning the symmetric key and header
 * metadata if any.
 *
 * No header metadata is returned if `header_metadata_ptr` is `NULL`.
 *
 * # Safety
 */
int h_decrypt_header(char *symmetric_key_ptr,
                     int *symmetric_key_len,
                     char *header_metadata_ptr,
                     int *header_metadata_len,
                     const char *encrypted_header_ptr,
                     int encrypted_header_len,
                     const char *authentication_data_ptr,
                     int authentication_data_len,
                     const char *usk_ptr,
                     int usk_len);

/**
 *
 * # Safety
 */
int h_symmetric_encryption_overhead(void);

/**
 *
 * # Safety
 */
int h_dem_encrypt(char *ciphertext_ptr,
                  int *ciphertext_len,
                  const char *symmetric_key_ptr,
                  int symmetric_key_len,
                  const char *authentication_data_ptr,
                  int authentication_data_len,
                  const char *plaintext_ptr,
                  int plaintext_len);

/**
 *
 * # Safety
 */
int h_dem_decrypt(char *plaintext_ptr,
                  int *plaintext_len,
                  const char *symmetric_key_ptr,
                  int symmetric_key_len,
                  const char *authentication_data_ptr,
                  int authentication_data_len,
                  const char *ciphertext_ptr,
                  int ciphertext_len);

/**
 * Hybrid encrypt some content
 *
 * # Safety
 */
int h_hybrid_encrypt(char *ciphertext_ptr,
                     int *ciphertext_len,
                     const char *policy_ptr,
                     int policy_len,
                     const char *mpk_ptr,
                     int mpk_len,
                     const char *encryption_policy_ptr,
                     const char *plaintext_ptr,
                     int plaintext_len,
                     const char *header_metadata_ptr,
                     int header_metadata_len,
                     const char *authentication_data_ptr,
                     int authentication_data_len);

/**
 * Hybrid decrypt some content.
 *
 * No header metadata is returned if `header_metadata_ptr` is `NULL`.
 *
 * # Safety
 */
int h_hybrid_decrypt(char *plaintext_ptr,
                     int *plaintext_len,
                     char *header_metadata_ptr,
                     int *header_metadata_len,
                     const char *ciphertext_ptr,
                     int ciphertext_len,
                     const char *authentication_data_ptr,
                     int authentication_data_len,
                     const char *usk_ptr,
                     int usk_len);

/**
 * Externally sets the last error recorded on the Rust side.
 *
 * # Safety
 *
 * The pointer must point to a null-terminated string.
 *
 * This function is meant to be called from the Foreign Function
 * Interface.
 *
 * # Parameters
 *
 * - `error_message_ptr`   : pointer to the error message to set
 */
int32_t h_set_error(const char *error_message_ptr);

/**
 * Externally gets the most recent error recorded on the Rust side, clearing
 * it in the process.
 *
 * # Safety
 *
 * The pointer `error_ptr` should point to a buffer which has been allocated
 * `error_len` bytes. If the allocated size is smaller than `error_len`, a
 * call to this function may result in a buffer overflow.
 *
 * # Parameters
 *
 * - `error_ptr`: pointer to the buffer to which to write the error
 * - `error_len`: size of the allocated memory
 */
int h_get_error(char *error_ptr, int *error_len);

//
// FINDEX HERE
//
// NOTE: Autogenerated file

/**
 * Number of bytes used to hash keywords.
 */
#define Keyword_HASH_LENGTH 32

/**
 * Length of an index table UID in bytes.
 */
#define UID_LENGTH 32

/**
 * Length of the blocks in the Chain Table in bytes.
 */
#define BLOCK_LENGTH 32

/**
 * Number of blocks per Chain Table value.
 */
#define TABLE_WIDTH 5

/**
 * Length of the Findex master key in bytes.
 */
#define MASTER_KEY_LENGTH 16

/**
 * Length of the chain keying material (`K_wi`) in bytes.
 */
#define KWI_LENGTH 16

/**
 * Length of a KMAC key in bytes.
 */
#define KMAC_KEY_LENGTH 32

/**
 * Length of a DEM key in bytes.
 */
#define DEM_KEY_LENGTH 32

/**
 * See `Token@index_id`
 */
#define INDEX_ID_LENGTH 5

/**
 * The callback signature is a kmac of the body of the request.
 * It is used to assert the client can call this callback.
 */
#define CALLBACK_SIGNATURE_LENGTH 32

/**
 * The number of seconds of validity of the requests to the Findex Cloud
 * backend. After this time, the request cannot be accepted by the backend.
 * This is done to prevent replay attacks.
 */
#define REQUEST_SIGNATURE_TIMEOUT_AS_SECS 60

/**
 * This seed is used to derive a new 32 bytes Kmac key.
 */
#define SIGNATURE_SEED_LENGTH 16

/**
 * Limit on the recursion to use when none is provided.
 */
#define MAX_DEPTH 100

/**
 * A pagination is performed in order to fetch the entire Entry Table. It is
 * fetched by batches of size [`NUMBER_OF_ENTRY_TABLE_LINE_IN_BATCH`].
 */
#define NUMBER_OF_ENTRY_TABLE_LINE_IN_BATCH 100

/**
 * See [`FindexCallbacks::progress()`](crate::core::FindexCallbacks::progress).
 *
 * # Serialization
 *
 * The intermediate results are serialized as follows:
 *
 * `LEB128(n_keywords) || LEB128(keyword_1)
 *     || keyword_1 || LEB128(n_associated_results)
 *     || LEB128(associated_result_1) || associated_result_1
 *     || ...`
 *
 * With the serialization of a keyword being:
 *
 * `LEB128(keyword.len()) || keyword`
 *
 * the serialization of the values associated to a keyword:
 *
 * `LEB128(serialized_results_for_keyword.len()) || serialized_result_1 || ...`
 *
 * and the serialization of a result:
 *
 * `LEB128(byte_vector.len() + 1) || prefix || byte_vector`
 *
 * where `prefix` is `l` (only `Location`s are returned) and the `byte_vector`
 * is the byte representation of the location.
 */
typedef int (*ProgressCallback)(const unsigned char *intermediate_results_ptr, unsigned int intermediate_results_len);

/**
 * See [`FindexCallbacks::fetch_entry_table()`](crate::core::FindexCallbacks::fetch_entry_table).
 *
 * # Serialization
 *
 * The input is serialized as follows:
 *
 * `LEB128(n_uids) || UID_1 || ...`
 *
 * The output should be deserialized as follows:
 *
 * `LEB128(n_entries) || UID_1 || LEB128(value_1.len()) || value_1 || ...`
 */
typedef int (*FetchEntryTableCallback)(unsigned char *entries_ptr, unsigned int *entries_len, const unsigned char *uids_ptr, unsigned int uids_len);

/**
 * See [`FindexCallbacks::fetch_chain_table()`](crate::core::FindexCallbacks::fetch_chain_table).
 *
 * # Serialization
 *
 * The input is serialized as follows:
 *
 * `LEB128(n_uids) || UID_1 || ...`
 *
 * The output should be serialized as follows:
 *
 * `LEB128(n_lines) || UID_1 || LEB128(value_1.len()) || value_1 || ...`
 */
typedef int (*FetchChainTableCallback)(unsigned char *chains_ptr, unsigned int *chains_len, const unsigned char *uids_ptr, unsigned int uids_len);

/**
 * See [`FindexCallbacks::upsert_entry_table()`](crate::core::FindexCallbacks::upsert_entry_table).
 *
 * # Serialization
 *
 * The input is serialized as follows:
 *
 * ` LEB128(entries.len()) || UID_1
 *     || LEB128(old_value_1.len()) || old_value_1
 *     || LEB128(new_value_1.len()) || new_value_1
 *     || ...`
 *
 * The output should be serialized as follows:
 *
 * `LEB128(n_lines) || UID_1 || LEB128(value_1.len()) || value_1 || ...`
 */
typedef int (*UpsertEntryTableCallback)(unsigned char *outputs_ptr, unsigned int *outputs_len, const unsigned char *entries_ptr, unsigned int entries_len);

/**
 * See [`FindexCallbacks::insert_chain_table()`](crate::core::FindexCallbacks::insert_chain_table).
 *
 * # Serialization
 *
 * The input is serialized as follows:
 *
 * `LEB128(n_lines) || UID_1 || LEB128(value_1.len() || value_1 || ...`
 */
typedef int (*InsertChainTableCallback)(const unsigned char *chains_ptr, unsigned int chains_len);

/**
 * See [`FindexCallbacks::fetch_all_entry_table_uids()`](crate::core::FindexCallbacks::fetch_all_entry_table_uids).
 *
 * The output should be deserialized as follows:
 *
 * `UID_1 || UID_2 || ... || UID_n`
 */
typedef int (*FetchAllEntryTableUidsCallback)(unsigned char *uids_ptr, unsigned int *uids_len);

/**
 * See [`FindexCallbacks::update_lines()`](crate::core::FindexCallbacks::update_lines).
 *
 * # Serialization
 *
 * The removed Chain Table UIDs are serialized as follows:
 *
 * `LEB128(n_uids) || UID_1 || ...`
 *
 * The new table items are serialized as follows:
 *
 * `LEB128(n_items) || UID_1 || LEB128(value_1.len()) || value_1 || ...`
 */
typedef int (*UpdateLinesCallback)(const unsigned char *chain_table_uids_to_remove_ptr, unsigned int chain_table_uids_to_remove_len, const unsigned char *new_encrypted_entry_table_items_ptr, unsigned int new_encrypted_entry_table_items_len, const unsigned char *new_encrypted_chain_table_items_ptr, unsigned int new_encrypted_chain_table_items_len);

/**
 * See
 * [`FindexCallbacks::list_removed_locations()`](crate::core::FindexCallbacks::list_removed_locations).
 *
 * # Serialization
 *
 * The input is serialized as follows:
 *
 * `LEB128(locations.len()) || LEB128(location_bytes_1.len()
 *     || location_bytes_1 || ...`
 *
 * Outputs should follow the same serialization.
 */
typedef int (*ListRemovedLocationsCallback)(unsigned char *removed_locations_ptr, unsigned int *removed_locations_len, const unsigned char *locations_ptr, unsigned int locations_len);

/**
 * Re-export the `cosmian_ffi` `h_get_error` function to clients with the old
 * `get_last_error` name The `h_get_error` is available inside the final lib
 * (but tools like ffigen seems to not parse it…) Maybe we can find a solution
 * by changing the function name inside the clients.
 *
 * # Safety
 *
 * It's unsafe.
 */
int get_last_error(char *error_ptr, int *error_len);

/**
 * Recursively searches Findex graphs for values indexed by the given keywords.
 *
 * # Serialization
 *
 * Le output is serialized as follows:
 *
 * `LEB128(n_keywords) || LEB128(keyword_1)
 *     || keyword_1 || LEB128(n_associated_results)
 *     || LEB128(associated_result_1) || associated_result_1
 *     || ...`
 *
 * # Parameters
 *
 * - `search_results`            : (output) search result
 * - `master_key`                : master key
 * - `label`                     : additional information used to derive Entry
 *   Table UIDs
 * - `keywords`                  : `serde` serialized list of base64 keywords
 * - `max_results_per_keyword`   : maximum number of results returned per
 *   keyword
 * - `max_depth`                 : maximum recursion depth allowed
 * - `fetch_chains_batch_size`   : increase this value to improve perfs but
 *   decrease security by batching fetch chains calls
 * - `progress_callback`         : callback used to retrieve intermediate
 *   results and transmit user interrupt
 * - `fetch_entry_callback`      : callback used to fetch the Entry Table
 * - `fetch_chain_callback`      : callback used to fetch the Chain Table
 *
 * # Safety
 *
 * Cannot be safe since using FFI.
 */
int h_search(char *search_results_ptr,
             int *search_results_len,
             const char *master_key_ptr,
             int master_key_len,
             const uint8_t *label_ptr,
             int label_len,
             const char *keywords_ptr,
             int max_results_per_keyword,
             int max_depth,
             unsigned int fetch_chains_batch_size,
             ProgressCallback progress_callback,
             FetchEntryTableCallback fetch_entry_callback,
             FetchChainTableCallback fetch_chain_callback);

/**
 * Index the given values for the given keywords. After upserting, any
 * search for such a keyword will result in finding (at least) the
 * corresponding value.
 *
 * # Serialization
 *
 * The list of values to index for the associated keywords should be serialized
 * as follows:
 *
 * `LEB128(n_values) || serialized_value_1
 *     || LEB128(n_associated_keywords) || serialized_keyword_1 || ...`
 *
 * where values serialized as follows:
 *
 * `LEB128(value_bytes.len() + 1) || base64(prefix || value_bytes)`
 *
 * with `prefix` being `l` for a `Location` and `w` for a `NextKeyword`, and
 * where keywords are serialized as follows:
 *
 * `LEB128(keyword_bytes.len()) || base64(keyword_bytes)`
 *
 * # Parameters
 *
 * - `master_key`      : Findex master key
 * - `label`           : additional information used to derive Entry Table UIDs
 * - `indexed_values_and_keywords` : serialized list of values and the keywords
 *   used to index them
 * - `fetch_entry`     : callback used to fetch the Entry Table
 * - `upsert_entry`    : callback used to upsert lines in the Entry Table
 * - `insert_chain`    : callback used to insert lines in the Chain Table
 *
 * # Safety
 *
 * Cannot be safe since using FFI.
 */
int h_upsert(const uint8_t *master_key_ptr,
             int master_key_len,
             const uint8_t *label_ptr,
             int label_len,
             const char *indexed_values_and_keywords_ptr,
             FetchEntryTableCallback fetch_entry,
             UpsertEntryTableCallback upsert_entry,
             InsertChainTableCallback insert_chain);

/**
 * Replaces all the Index Entry Table UIDs and values. New UIDs are derived
 * using the given label and the KMAC key derived from the new master key. The
 * values are dectypted using the DEM key derived from the master key and
 * re-encrypted using the DEM key derived from the new master key.
 *
 * Randomly selects index entries and recompact their associated chains. Chains
 * indexing no existing location are removed. Others are recomputed from a new
 * keying material. This removes unneeded paddings. New UIDs are derived for
 * the chain and values are re-encrypted using a DEM key derived from the new
 * keying material.
 *
 * # Parameters
 *
 * - `num_reindexing_before_full_set`  : number of compact operation needed to
 *   compact all Chain Table
 * - `old_master_key`                  : old Findex master key
 * - `new_master_key`                  : new Findex master key
 * - `new_label`                       : additional information used to derive
 *   Entry Table UIDs
 * - `fetch_entry`                     : callback used to fetch the Entry Table
 * - `fetch_chain`                     : callback used to fetch the Chain Table
 * - `update_lines`                    : callback used to update lines in both
 *   tables
 * - `list_removed_locations`          : callback used to list removed
 *   locations among the ones given
 *
 * # Safety
 *
 * Cannot be safe since using FFI.
 */
int h_compact(int num_reindexing_before_full_set,
              const uint8_t *old_master_key_ptr,
              int old_master_key_len,
              const uint8_t *new_master_key_ptr,
              int new_master_key_len,
              const uint8_t *new_label_ptr,
              int new_label_len,
              FetchAllEntryTableUidsCallback fetch_all_entry_table_uids,
              FetchEntryTableCallback fetch_entry,
              FetchChainTableCallback fetch_chain,
              UpdateLinesCallback update_lines,
              ListRemovedLocationsCallback list_removed_locations);

/**
 * Recursively searches Findex graphs for values indexed by the given keywords.
 *
 * # Serialization
 *
 * Le output is serialized as follows:
 *
 * `LEB128(n_keywords) || LEB128(keyword_1)
 *     || keyword_1 || LEB128(n_associated_results)
 *     || LEB128(associated_result_1) || associated_result_1
 *     || ...`
 *
 * # Parameters
 *
 * - `search_results`            : (output) search result
 * - `token`                     : findex cloud token
 * - `label`                     : additional information used to derive Entry
 *   Table UIDs
 * - `keywords`                  : `serde` serialized list of base64 keywords
 * - `max_results_per_keyword`   : maximum number of results returned per
 *   keyword
 * - `max_depth`                 : maximum recursion depth allowed
 * - `fetch_chains_batch_size`   : increase this value to improve perfs but
 *   decrease security by batching fetch chains calls
 * - `base_url`                  : base URL for Findex Cloud (with http prefix
 *   and port if required). If null, use the default Findex Cloud server.
 *
 * # Safety
 *
 * Cannot be safe since using FFI.
 */
int h_search_cloud(char *search_results_ptr,
                   int *search_results_len,
                   const char *token_ptr,
                   const uint8_t *label_ptr,
                   int label_len,
                   const char *keywords_ptr,
                   int max_results_per_keyword,
                   int max_depth,
                   unsigned int fetch_chains_batch_size,
                   const char *base_url_ptr);

/**
 * Index the given values for the given keywords. After upserting, any
 * search for such a keyword will result in finding (at least) the
 * corresponding value.
 *
 * # Serialization
 *
 * The list of values to index for the associated keywords should be serialized
 * as follows:
 *
 * `LEB128(n_values) || serialized_value_1
 *     || LEB128(n_associated_keywords) || serialized_keyword_1 || ...`
 *
 * where values serialized as follows:
 *
 * `LEB128(value_bytes.len() + 1) || base64(prefix || value_bytes)`
 *
 * with `prefix` being `l` for a `Location` and `w` for a `NextKeyword`, and
 * where keywords are serialized as follows:
 *
 * `LEB128(keyword_bytes.len()) || base64(keyword_bytes)`
 *
 * # Parameters
 *
 * - `token`           : Findex Cloud token
 * - `label`           : additional information used to derive Entry Table UIDs
 * - `indexed_values_and_keywords` : serialized list of values and the keywords
 *   used to index them
 * - `base_url`                  : base URL for Findex Cloud (with http prefix
 *   and port if required). If null, use the default Findex Cloud server.
 *
 * # Safety
 *
 * Cannot be safe since using FFI.
 */
int h_upsert_cloud(const char *token_ptr,
                   const uint8_t *label_ptr,
                   int label_len,
                   const char *indexed_values_and_keywords_ptr,
                   const char *base_url_ptr);
