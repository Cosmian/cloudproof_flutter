#import <Flutter/Flutter.h>

@interface CloudproofPlugin : NSObject<FlutterPlugin>
@end

#define MAX_CLEAR_TEXT_SIZE (1 << 30)

#define MAX_CLEAR_TEXT_SIZE (1 << 30)

#define MAX_CLEAR_TEXT_SIZE (1 << 30)

/**
 * Externally set the last error recorded on the Rust side
 *
 * # Safety
 * This function is meant to be called from the Foreign Function
 * Interface
 */
int32_t set_error(const char *error_message_ptr);

/**
 * Get the most recent error as utf-8 bytes, clearing it in the process.
 * # Safety
 * - `error_msg`: must be pre-allocated with a sufficient size
 */
int get_last_error(char *error_msg_ptr, int *error_len);

/**
 * Generate the master authority keys for supplied Policy
 *
 *  - `master_keys_ptr`    : Output buffer containing both master keys
 *  - `master_keys_len`    : Size of the output buffer
 *  - `policy_ptr`         : Policy to use to generate the keys
 * # Safety
 */
int h_generate_master_keys(char *master_keys_ptr, int *master_keys_len, const char *policy_ptr);

/**
 * Generate the user private key matching the given access policy
 *
 * - `user_private_key_ptr`: Output buffer containing user private key
 * - `user_private_key_len`: Size of the output buffer
 * - `master_private_key_ptr`: Master private key (required for this
 *   generation)
 * - `master_private_key_len`: Master private key length
 * - `access_policy_ptr`: Access policy of the user private key (JSON)
 * - `policy_ptr`: Policy to use to generate the keys (JSON)
 * # Safety
 */
int h_generate_user_private_key(char *user_private_key_ptr,
                                int *user_private_key_len,
                                const char *master_private_key_ptr,
                                int master_private_key_len,
                                const char *access_policy_ptr,
                                const char *policy_ptr);

/**
 * Rotate the attributes of the given policy
 *
 * - `updated_policy_ptr`: Output buffer containing new policy
 * - `updated_policy_len`: Size of the output buffer
 * - `attributes_ptr`: Attributes to rotate (JSON)
 * - `policy_ptr`: Policy to use to generate the keys (JSON)
 * # Safety
 */
int h_rotate_attributes(char *updated_policy_ptr,
                        int *updated_policy_len,
                        const char *attributes_ptr,
                        const char *policy_ptr);

/**
 * Update the master keys according to this new policy.
 *
 * When a partition exists in the new policy but not in the master keys,
 * a new keypair is added to the master keys for that partition.
 * When a partition exists on the master keys, but not in the new policy,
 * it is removed from the master keys.
 *
 * - `updated_master_private_key_ptr`: Output buffer containing the updated master private key
 * - `updated_master_private_key_len`: Size of the updated master private key output buffer
 * - `updated_master_public_key_ptr`: Output buffer containing the updated master public key
 * - `updated_master_public_key_len`: Size of the updated master public key output buffer
 * - `current_master_private_key_ptr`: current master private key
 * - `current_master_private_key_len`: current master private key length
 * - `current_master_public_key_ptr`: current master public key
 * - `current_master_public_key_len`: current master public key length
 * - `policy_ptr`: Policy to use to update the master keys (JSON)
 * # Safety
 */
int h_update_master_keys(char *updated_master_private_key_ptr,
                         int *updated_master_private_key_len,
                         char *updated_master_public_key_ptr,
                         int *updated_master_public_key_len,
                         const char *current_master_private_key_ptr,
                         int current_master_private_key_len,
                         const char *current_master_public_key_ptr,
                         int current_master_public_key_len,
                         const char *policy_ptr);

/**
 * Refresh the user key according to the given master key and access policy.
 *
 * The user key will be granted access to the current partitions, as determined by its access policy.
 * If preserve_old_partitions is set, the user access to rotated partitions will be preserved
 *
 * - `updated_user_private_key_ptr`: Output buffer containing the updated user private key
 * - `updated_user_private_key_len`: Size of the updated user private key output buffer
 * - `master_private_key_ptr`: master private key
 * - `master_private_key_len`: master private key length
 * - `current_user_private_key_ptr`: current user private key
 * - `current_user_private_key_len`: current user private key length
 * - `access_policy_ptr`: Access policy of the user private key (JSON)
 * - `policy_ptr`: Policy to use to update the master keys (JSON)
 * - `preserve_old_partitions_access`: set to 1 to preserve the user access to the rotated partitions
 * # Safety
 */
int h_refresh_user_private_key(char *updated_user_private_key_ptr,
                               int *updated_user_private_key_len,
                               const char *master_private_key_ptr,
                               int master_private_key_len,
                               const char *current_user_private_key_ptr,
                               int current_user_private_key_len,
                               const char *access_policy_ptr,
                               const char *policy_ptr,
                               int preserve_old_partitions_access);

/**
 * Create a cache of the Public Key and Policy which can be re-used
 * when encrypting multiple messages. This avoids having to re-instantiate
 * the public key on the Rust side on every encryption which is costly.
 *
 * This method is to be used in conjunction with
 *     h_aes_encrypt_header_using_cache
 *
 * WARN: h_aes_destroy_encrypt_cache() should be called
 * to reclaim the memory of the cache when done
 * # Safety
 */
int32_t h_aes_create_encryption_cache(int *cache_handle,
                                      const char *policy_ptr,
                                      const char *public_key_ptr,
                                      int public_key_len);

/**
 * The function should be called to reclaim memory
 * of the cache created using h_aes_create_encrypt_cache()
 * # Safety
 */
int h_aes_destroy_encryption_cache(int cache_handle);

/**
 * Encrypt a header using an encryption cache
 * The symmetric key and header bytes are returned in the first OUT parameters
 * # Safety
 */
int h_aes_encrypt_header_using_cache(char *symmetric_key_ptr,
                                     int *symmetric_key_len,
                                     char *header_bytes_ptr,
                                     int *header_bytes_len,
                                     int cache_handle,
                                     const char *attributes_ptr,
                                     const char *uid_ptr,
                                     int uid_len,
                                     const char *additional_data_ptr,
                                     int additional_data_len);

/**
 * Encrypt a header without using an encryption cache.
 * It is slower but does not require destroying any cache when done.
 *
 * The symmetric key and header bytes are returned in the first OUT parameters
 * # Safety
 */
int h_aes_encrypt_header(char *symmetric_key_ptr,
                         int *symmetric_key_len,
                         char *header_bytes_ptr,
                         int *header_bytes_len,
                         const char *policy_ptr,
                         const char *public_key_ptr,
                         int public_key_len,
                         const char *attributes_ptr,
                         const char *uid_ptr,
                         int uid_len,
                         const char *additional_data_ptr,
                         int additional_data_len);

/**
 * Create a cache of the User Decryption Key which can be re-used
 * when decrypting multiple messages. This avoids having to re-instantiate
 * the user key on the Rust side on every decryption which is costly.
 *
 * This method is to be used in conjunction with
 *     h_aes_decrypt_header_using_cache()
 *
 * WARN: h_aes_destroy_decryption_cache() should be called
 * to reclaim the memory of the cache when done
 * # Safety
 */
int32_t h_aes_create_decryption_cache(int *cache_handle,
                                      const char *user_decryption_key_ptr,
                                      int user_decryption_key_len);

/**
 * The function should be called to reclaim memory
 * of the cache created using h_aes_create_decryption_cache()
 * # Safety
 */
int h_aes_destroy_decryption_cache(int cache_handle);

/**
 * Decrypt an encrypted header using a cache.
 * Returns the symmetric key,
 * the uid and additional data if available.
 *
 * No additional data will be returned if the `additional_data_ptr` is NULL.
 *
 * # Safety
 */
int h_aes_decrypt_header_using_cache(char *symmetric_key_ptr,
                                     int *symmetric_key_len,
                                     char *uid_ptr,
                                     int *uid_len,
                                     char *additional_data_ptr,
                                     int *additional_data_len,
                                     const char *encrypted_header_ptr,
                                     int encrypted_header_len,
                                     int cache_handle);

/**
 * # Safety
 */
int h_get_encrypted_header_size(const char *encrypted_ptr, int encrypted_len);

/**
 * Decrypt an encrypted header returning the symmetric key,
 * the uid and additional data if available.
 *
 * Slower than using a cache but avoids handling the cache creation and
 * destruction.
 *
 * No additional data will be returned if the `additional_data_ptr` is NULL.
 *
 * # Safety
 */
int h_aes_decrypt_header(char *symmetric_key_ptr,
                         int *symmetric_key_len,
                         char *uid_ptr,
                         int *uid_len,
                         char *additional_data_ptr,
                         int *additional_data_len,
                         const char *encrypted_header_ptr,
                         int encrypted_header_len,
                         const char *user_decryption_key_ptr,
                         int user_decryption_key_len);

/**
 *
 * # Safety
 */
int h_aes_symmetric_encryption_overhead(void);

/**
 *
 * # Safety
 */
int h_aes_encrypt_block(char *encrypted_ptr,
                        int *encrypted_len,
                        const char *symmetric_key_ptr,
                        int symmetric_key_len,
                        const char *uid_ptr,
                        int uid_len,
                        int block_number,
                        const char *data_ptr,
                        int data_len);

/**
 *
 * # Safety
 */
int h_aes_decrypt_block(char *clear_text_ptr,
                        int *clear_text_len,
                        const char *symmetric_key_ptr,
                        int symmetric_key_len,
                        const char *uid_ptr,
                        int uid_len,
                        int block_number,
                        const char *encrypted_bytes_ptr,
                        int encrypted_bytes_len);

//
// FINDEX HERE
//
// NOTE: Autogenerated file

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
 * Default number of results returned per keyword.
 */
#define MAX_RESULTS_PER_KEYWORD 65536

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
 * `LEB128(results.len()) || serialized_keyword_1
 *     || serialized_results_for_keyword_1`
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
typedef bool (*ProgressCallback)(const unsigned char *intermediate_results_ptr, unsigned int intermediate_results_len);

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
 * - `indexed_values`          : (output) search result
 * - `master_key`              : masterkey
 * - `label`                   : additional information used to derive Entry
 *   Table UIDs
 * - `keywords`                : `serde` serialized list of base64 keywords
 * - `max_results_per_keyword` : maximum number of results returned per keyword
 * - `max_depth`               : maximum recursion depth allowed
 * - `progress_callback`       : callback used to retrieve intermediate results
 *   and transmit user interrupt
 * - `fetch_entry`             : callback used to fetch the Entry Table
 * - `fetch_chain`             : callback used to fetch the Chain Table
 *
 * # Safety
 *
 * Cannot be safe since using FFI.
 */
int h_search(char *indexed_values_ptr,
             int *indexed_values_len,
             const char *master_key_ptr,
             int master_key_len,
             const uint8_t *label_ptr,
             int label_len,
             const char *keywords_ptr,
             int max_results_per_keyword,
             int max_depth,
             ProgressCallback progress_callback,
             FetchEntryTableCallback fetch_entry,
             FetchChainTableCallback fetch_chain);

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
 * - `label`                           : additional information used to derive
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
              const uint8_t *master_key_ptr,
              int master_key_len,
              const uint8_t *new_master_key_ptr,
              int new_master_key_len,
              const uint8_t *label_ptr,
              int label_len,
              FetchAllEntryTableUidsCallback fetch_all_entry_table_uids,
              FetchEntryTableCallback fetch_entry,
              FetchChainTableCallback fetch_chain,
              UpdateLinesCallback update_lines,
              ListRemovedLocationsCallback list_removed_locations);

/**
 * Get the most recent error as utf-8 bytes, clearing it in the process.
 * # Safety
 * - `error_msg`: must be pre-allocated with a sufficient size
 */
// int get_last_error(char *error_msg_ptr, int *error_len);
